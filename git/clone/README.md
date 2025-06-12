# git/clone

## Clone Public Repositories

```yaml
tasks:
  - key: code
    call: git/clone 1.6.5
    with:
      repository: https://github.com/YOUR_ORG/YOUR_REPO.git
      ref: main
```

This example shows a hardcoded `ref` of `main`, but most of the time you'll pass the ref to clone using an [init parameter](https://www.rwx.com/docs/mint/init-parameters) like this:

```
ref: ${{ init.ref }}
```

By using an init parameter, you can specify the ref when running via the Mint CLI while also setting the value based on version control events.
For more examples see the Mint documentation on [getting started with GitHub](https://www.rwx.com/docs/mint/getting-started/github).

## Clone Private Repositories

To clone private repositories, you'll either need to pass an `ssh-key` to clone over ssh, or a `github-access-token` to clone GitHub repositories over https.

### Cloning GitHub Repositories over HTTPS

If you're using GitHub, Mint will automatically provide a token that you can use to clone your repositories.

```yaml
tasks:
  - key: code
    call: git/clone 1.6.5
    with:
      repository: https://github.com/YOUR_ORG/PROJECT.git
      ref: ${{ init.ref }}
      github-access-token: ${{ github.token }}
```

### Cloning over SSH

```yaml
tasks:
  - key: code
    call: git/clone 1.6.5
    with:
      repository: git@github.com:YOUR_ORG/PROJECT.git
      ref: ${{ init.ref }}
      ssh-key: ${{ secrets.PROJECT_REPO_SSH_KEY }}
```

You'll want to store your SSH key as a [Mint vault secret](https://www.rwx.com/docs/mint/vaults).

## Metadata

Tasks which `use` this leaf will have access to metadata about the cloned repository. Each of these environment variables are configured to have no impact to subsequent tasks' cache keys by default. With no additional configuration, it's safe to use these as metadata for tools which request additional context of the environment they run in (e.g. code coverage, parallel test runners, etc.).

If you need to reference one of these to alter behavior of a task, be sure to indicate that it should be included in the cache key:

```yaml
tasks:
  - key: code
    call: git/clone 1.6.5
    with:
      repository: https://github.com/YOUR_ORG/YOUR_REPO.git
      ref: main

  - key: use-meta
    use: code
    run: ./my-script.sh $MINT_GIT_COMMIT_SHA
    env:
      MINT_GIT_COMMIT_SHA:
        cache-key: included
```

### `MINT_GIT_REPOSITORY_URL`

The `repository` parameter you provided to `git/clone`.

### `MINT_GIT_REPOSITORY_NAME`

The name of the repository, extracted from your URL for convenience. For example, given a repository URL of `git@github.com:YOUR_ORG/PROJECT.git`, this environment variable would be set to `YOUR_ORG/PROJECT`.

### `MINT_GIT_COMMIT_MESSAGE`

The message of the resolved commit.

### `MINT_GIT_COMMIT_SUMMARY`

The summary line of the resolved commit's message.

### `MINT_GIT_COMMIT_SHA`

The SHA of the resolved commit.

### `MINT_GIT_COMMITTER_NAME`

The committer name associated with the resolved commit.

### `MINT_GIT_COMMITTER_EMAIL`

The committer email associated with the resolved commit.

### `MINT_GIT_REF`

The unresolved ref associated with the commit. Mint attempts to determine this for you, but in some scenarios you may want to specify. The logic is as follows:

- If you have provided the `meta-ref` parameter, we'll use that (note: you can specify the fully qualified ref including its `refs/heads/` or `refs/tags/` prefix, or you can specify only the short name)
- If you provide a commit sha to the `ref` parameter, we'll try to find a branch or tag with that commit at HEAD
- If you provide a branch or tag to the `ref` parameter, we'll use that (again, you can provide a fully qualified ref or short ref name)
- If no other case catches your ref, we'll use the resolved commit sha

### `MINT_GIT_REF_NAME`

The name of the unresolved ref associated with the commit. For example, given a `MINT_GIT_REF` of `refs/heads/main`, `MINT_GIT_REF_NAME` would be set to `main`.
