package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"golang.org/x/sys/unix"
)

func main() {
	if err := restoreMtime(); err != nil {
		fmt.Fprintln(os.Stderr, "git-restore-mtime:", err)
		os.Exit(1)
	}
}

func gitOutput(args ...string) ([]byte, error) {
	cmd := exec.Command("git", args...)
	cmd.Stderr = os.Stderr
	return cmd.Output()
}

func restoreMtime() error {
	index, err := gitOutput("ls-files", "--stage", "-z")
	if err != nil {
		return err
	}
	pending := make(map[string]bool)
	for _, entry := range bytes.Split(index, []byte{0}) {
		if len(entry) == 0 {
			continue
		}
		metadata, path, ok := strings.Cut(string(entry), "\t")
		if !ok {
			return fmt.Errorf("invalid index entry: %q", entry)
		}
		// Gitlinks are directories; submodules are restored separately by git-clone.
		if !strings.HasPrefix(metadata, "160000 ") {
			pending[path] = true
		}
	}

	status, err := gitOutput("status", "--porcelain=v1", "-z", "--untracked-files=no")
	if err != nil {
		return err
	}
	entries := bytes.Split(status, []byte{0})
	for i := 0; i < len(entries); i++ {
		entry := entries[i]
		if len(entry) == 0 {
			continue
		}
		delete(pending, string(entry[3:]))
		if bytes.ContainsAny(entry[:2], "RC") {
			i++ // In -z status output the destination precedes the source.
			delete(pending, string(entries[i]))
		}
	}
	if len(pending) == 0 {
		return nil
	}

	// Walk descendants before ancestors, even with skewed commit clocks. A merge
	// counts only paths changed relative to every parent (e.g. conflict resolutions).
	// Treat renames as new paths, independently of the user's rename configuration.
	cmd := exec.Command("git", "log", "--topo-order", "--raw", "-z", "--no-renames",
		"--no-show-signature", "--diff-merges=combined", "--format=%ct", "HEAD", "--")
	cmd.Stderr = os.Stderr
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	if err := cmd.Start(); err != nil {
		return err
	}
	err = restoreHistory(stdout, pending)
	// Drain the pipe even after all paths are found so Git can exit normally.
	_, drainErr := io.Copy(io.Discard, stdout)
	waitErr := cmd.Wait()
	if err != nil {
		return err
	}
	if drainErr != nil {
		return drainErr
	}
	if waitErr != nil {
		return waitErr
	}
	if len(pending) != 0 {
		return fmt.Errorf("no commit found for %d tracked paths", len(pending))
	}
	return nil
}

func restoreHistory(history io.Reader, pending map[string]bool) error {
	reader := bufio.NewReader(history)
	var timestamp int64
	for len(pending) != 0 {
		token, err := reader.ReadString(0)
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		token = strings.TrimLeft(strings.TrimSuffix(token, "\x00"), "\n")
		if token == "" {
			continue
		}
		if !strings.HasPrefix(token, ":") {
			timestamp, err = strconv.ParseInt(token, 10, 64)
			if err != nil {
				return fmt.Errorf("invalid commit timestamp %q: %w", token, err)
			}
			continue
		}
		path, err := reader.ReadString(0)
		if err != nil {
			return err
		}
		path = strings.TrimSuffix(path, "\x00")
		if !pending[path] {
			continue
		}
		times := []unix.Timespec{{Sec: timestamp}, {Sec: timestamp}}
		if err := unix.UtimesNanoAt(unix.AT_FDCWD, path, times, unix.AT_SYMLINK_NOFOLLOW); err != nil {
			return fmt.Errorf("set timestamp for %q: %w", path, err)
		}
		delete(pending, path)
	}
	return nil
}
