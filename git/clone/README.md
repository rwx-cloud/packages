# git/clone

Use this package to clone a git repository.

## Dependencies

The `git/clone` package requires `jq` and `curl` to be installed.

If you're using the RWX base configuration, then they will already be installed.

```yaml
base:
  image: ubuntu:24.04
  config: rwx/base 1.0.0
```

However, if you are running without the RWX base configuration, then you will need to install them and specify a `use` dependency on the `git/clone` task.
For example using debian:

```yaml
base:
  image: debian:trixie
  config: none

tasks:
  - key: system-packages
    run: |
      sudo apt-get update
      sudo apt-get install curl jq
      sudo apt-get clean

  - key: code
    use: system-packages
    call: git/clone 2.0.0
    with:
      repository: ...
```

## Clone Public Repositories

```yaml
tasks:
  - key: code
    call: git/clone 2.0.0
    with:
      repository: https://github.com/YOUR_ORG/YOUR_REPO.git
      ref: main
```

This example shows a hardcoded `ref` of `main`, but most of the time you'll pass the ref to clone using an [init parameter](https://www.rwx.com/docs/rwx/init-parameters) like this:

```
ref: ${{ init.ref }}
```

By using an init parameter, you can specify the ref when running via the RWX CLI while also setting the value based on version control events.
For more examples see the documentation on [getting started with GitHub](https://www.rwx.com/docs/rwx/getting-started/github).

## Clone Private Repositories

To clone private repositories, you'll either need to pass an `ssh-key` to clone over ssh, or a `github-access-token` to clone GitHub repositories over https.

### Cloning GitHub Repositories over HTTPS

If you're using GitHub, RWX will automatically provide a token that you can use to clone your repositories.

```yaml
tasks:
  - key: code
    call: git/clone 2.0.0
    with:
      repository: https://github.com/YOUR_ORG/PROJECT.git
      ref: ${{ init.ref }}
      github-access-token: ${{ github.token }}
```

### Cloning over SSH

```yaml
tasks:
  - key: code
    call: git/clone 2.0.0
    with:
      repository: git@github.com:YOUR_ORG/PROJECT.git
      ref: ${{ init.ref }}
      ssh-key: ${{ secrets.PROJECT_REPO_SSH_KEY }}
```

You'll want to store your SSH key as a [vault secret](https://www.rwx.com/docs/rwx/vaults).

## Metadata

Tasks which `use` this leaf will have access to metadata about the cloned repository. Each of these environment variables are configured to have no impact to subsequent tasks' cache keys by default. With no additional configuration, it's safe to use these as metadata for tools which request additional context of the environment they run in (e.g. code coverage, parallel test runners, etc.).

If you need to reference one of these to alter behavior of a task, be sure to indicate that it should be included in the cache key:

```yaml
tasks:
  - key: code
    call: git/clone 2.0.0
    with:
      repository: https://github.com/YOUR_ORG/YOUR_REPO.git
      ref: main

  - key: use-meta
    use: code
    run: ./my-script.sh $RWX_GIT_COMMIT_SHA
    env:
      RWX_GIT_COMMIT_SHA:
        cache-key: included
```

Note: the following environment variables are also available with the `MINT_` prefix instead of `RWX_` for backwards compatibility.

### `RWX_GIT_REPOSITORY_URL`

The `repository` parameter you provided to `git/clone`.

### `RWX_GIT_REPOSITORY_NAME`

The name of the repository, extracted from your URL for convenience. For example, given a repository URL of `git@github.com:YOUR_ORG/PROJECT.git`, this environment variable would be set to `YOUR_ORG/PROJECT`.

### `RWX_GIT_COMMIT_MESSAGE`

The message of the resolved commit.

### `RWX_GIT_COMMIT_SUMMARY`

The summary line of the resolved commit's message.

### `RWX_GIT_COMMIT_SHA`

The SHA of the resolved commit.

### `RWX_GIT_COMMITTER_NAME`

The committer name associated with the resolved commit.

### `RWX_GIT_COMMITTER_EMAIL`

The committer email associated with the resolved commit.

### `RWX_GIT_REF`

The unresolved ref associated with the commit. `git/clone` attempts to determine this for you, but in some scenarios you may want to specify. The logic is as follows:

- If you have provided the `meta-ref` parameter, we'll use that (note: you can specify the fully qualified ref including its `refs/heads/` or `refs/tags/` prefix, or you can specify only the short name)
- If you provide a commit sha to the `ref` parameter, we'll try to find a branch or tag with that commit at HEAD
- If you provide a branch or tag to the `ref` parameter, we'll use that (again, you can provide a fully qualified ref or short ref name)
- If no other case catches your ref, we'll use the resolved commit sha

### `RWX_GIT_REF_NAME`

The name of the unresolved ref associated with the commit. For example, given a `RWX_GIT_REF` of `refs/heads/main`, `RWX_GIT_REF_NAME` would be set to `main`.

## v2.0.0 Changes

Version 2.0.0 introduces tool caching for faster incremental clones. The `.git` directory is now preserved in a tool cache between runs, meaning subsequent clones of the same repository become fast incremental fetches instead of full clones.

### What's New

- **Tool-cached `.git` directory**: The `.git` directory persists between task executions via RWX tool caches
- **Faster subsequent runs**: After the first clone, subsequent runs only fetch new commits
- **Simplified clone logic**: The clone process now uses a consistent incremental fetch pattern
- **New `tool-cache-key-prefix` parameter**: Optionally override the tool cache key prefix to make it easier to find your entry in the vaults UI

### Migration from v1.x

The v2 API is backward compatible. Existing configurations will work without changes. The main difference is improved performance on subsequent runs.
