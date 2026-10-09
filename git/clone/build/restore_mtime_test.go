package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestRestoreMtime(t *testing.T) {
	binary := filepath.Join(t.TempDir(), "git-restore-mtime")
	if output, err := exec.Command("go", "build", "-o", binary, ".").CombinedOutput(); err != nil {
		t.Fatalf("build: %v\n%s", err, output)
	}

	t.Run("tracked paths and local changes", func(t *testing.T) {
		repo := newTestRepo(t)
		paths := []string{"unchanged", "changed", "rename", "dirty", "staged", "deleted", "staged-rename",
			"space name", "tab\tname", "\nnewline\nname", "quote\"name", "unicode-日本語", "-leading-dash", "1234567890"}
		for _, path := range paths {
			repo.write(path, "initial\n")
		}
		if err := os.Symlink("untracked", filepath.Join(repo.dir, "link")); err != nil {
			t.Fatal(err)
		}
		if err := os.Symlink("absent", filepath.Join(repo.dir, "broken-link")); err != nil {
			t.Fatal(err)
		}
		repo.commit(1100000000)
		repo.write("changed", "second\n")
		repo.git("mv", "rename", "renamed")
		repo.commit(1100000200)
		// The descendant wins even when its committer clock is behind its parent.
		repo.write("changed", "third\n")
		repo.commit(1100000100)
		repo.git("config", "diff.renames", "true")
		repo.write("dirty", "local\n")
		repo.write("staged", "index\n")
		repo.git("add", "staged")
		// A staged modification remains dirty even if the worktree matches HEAD.
		repo.write("staged", "initial\n")
		repo.git("mv", "staged-rename", "local-rename")
		if err := os.Remove(filepath.Join(repo.dir, "deleted")); err != nil {
			t.Fatal(err)
		}
		repo.write("untracked", "not tracked\n")
		if err := os.Mkdir(filepath.Join(repo.dir, "directory"), 0755); err != nil {
			t.Fatal(err)
		}
		untouched := []string{"dirty", "staged", "local-rename", "untracked", "directory"}
		for _, path := range untouched {
			timestamp := time.Unix(1200000000, 123456789)
			if err := os.Chtimes(filepath.Join(repo.dir, path), timestamp, timestamp); err != nil {
				t.Fatal(err)
			}
		}
		repo.restore(binary)
		for _, path := range paths {
			switch path {
			case "changed":
				repo.assertTime(path, time.Unix(1100000100, 0))
			case "rename", "dirty", "staged", "deleted", "staged-rename":
				continue
			default:
				repo.assertTime(path, time.Unix(1100000000, 0))
			}
		}
		repo.assertTime("renamed", time.Unix(1100000200, 0))
		repo.assertTime("link", time.Unix(1100000000, 0))
		repo.assertTime("broken-link", time.Unix(1100000000, 0))
		for _, path := range untouched {
			repo.assertTime(path, time.Unix(1200000000, 123456789))
		}
	})

	t.Run("merges and gitlinks", func(t *testing.T) {
		repo := newTestRepo(t)
		repo.write("conflict", "initial\n")
		repo.write("unchanged", "initial\n")
		repo.commit(1100000000)
		repo.git("checkout", "-b", "side")
		repo.write("conflict", "side\n")
		repo.write("inherited", "side only\n")
		repo.commit(1100000100)
		repo.git("checkout", "main")
		repo.write("conflict", "main\n")
		repo.commit(1100000200)
		cmd := repo.command("git", "merge", "--no-commit", "side")
		if output, err := cmd.CombinedOutput(); err == nil {
			t.Fatalf("expected merge conflict, got success: %s", output)
		}
		repo.write("conflict", "resolved\n")
		repo.write("merge-only", "created during merge\n")
		repo.commit(1100000300)
		repo.git("update-index", "--add", "--cacheinfo", "160000,"+repo.git("rev-parse", "HEAD")+",submodule")
		repo.git("commit", "-m", "gitlink")
		if err := os.Mkdir(filepath.Join(repo.dir, "submodule"), 0755); err != nil {
			t.Fatal(err)
		}
		timestamp := time.Unix(1200000000, 0)
		if err := os.Chtimes(filepath.Join(repo.dir, "submodule"), timestamp, timestamp); err != nil {
			t.Fatal(err)
		}
		repo.restore(binary)
		repo.assertTime("unchanged", time.Unix(1100000000, 0))
		repo.assertTime("inherited", time.Unix(1100000100, 0))
		repo.assertTime("conflict", time.Unix(1100000300, 0))
		repo.assertTime("merge-only", time.Unix(1100000300, 0))
		repo.assertTime("submodule", timestamp)
	})

	t.Run("no clean tracked files", func(t *testing.T) {
		repo := newTestRepo(t)
		repo.git("commit", "--allow-empty", "-m", "empty")
		repo.restore(binary)
		repo.write("dirty", "initial\n")
		repo.commit(1100000000)
		repo.write("dirty", "local\n")
		before, err := os.Stat(filepath.Join(repo.dir, "dirty"))
		if err != nil {
			t.Fatal(err)
		}
		repo.restore(binary)
		repo.assertTime("dirty", before.ModTime())
	})
}

type testRepo struct {
	t   *testing.T
	dir string
}

func newTestRepo(t *testing.T) testRepo {
	t.Helper()
	repo := testRepo{t: t, dir: t.TempDir()}
	repo.git("init", "-b", "main")
	repo.git("config", "user.name", "Test")
	repo.git("config", "user.email", "test@example.com")
	return repo
}

func (r testRepo) command(name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	cmd.Dir = r.dir
	cmd.Env = append(os.Environ(), "GIT_CONFIG_NOSYSTEM=1", "GIT_CONFIG_GLOBAL=/dev/null")
	return cmd
}

func (r testRepo) git(args ...string) string {
	r.t.Helper()
	output, err := r.command("git", args...).CombinedOutput()
	if err != nil {
		r.t.Fatalf("git %v: %v\n%s", args, err, output)
	}
	return strings.TrimSuffix(string(output), "\n")
}

func (r testRepo) write(path, data string) {
	r.t.Helper()
	if err := os.WriteFile(filepath.Join(r.dir, path), []byte(data), 0644); err != nil {
		r.t.Fatal(err)
	}
}

func (r testRepo) commit(timestamp int64) {
	r.t.Helper()
	r.git("add", "-A")
	cmd := r.command("git", "commit", "-m", "fixture")
	cmd.Env = append(cmd.Env, fmt.Sprintf("GIT_COMMITTER_DATE=@%d +0000", timestamp), "GIT_AUTHOR_DATE=@1000000000 +0000")
	if output, err := cmd.CombinedOutput(); err != nil {
		r.t.Fatalf("commit: %v\n%s", err, output)
	}
}

func (r testRepo) restore(binary string) {
	r.t.Helper()
	if output, err := r.command(binary).CombinedOutput(); err != nil {
		r.t.Fatalf("restore: %v\n%s", err, output)
	}
}

func (r testRepo) assertTime(path string, want time.Time) {
	r.t.Helper()
	info, err := os.Lstat(filepath.Join(r.dir, path))
	if err != nil {
		r.t.Fatal(err)
	}
	if !info.ModTime().Equal(want) {
		r.t.Errorf("%q mtime = %s, want %s", path, info.ModTime(), want)
	}
}
