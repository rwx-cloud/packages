# github/create-pull-request

Creates a pull request or updates an existing one.

The host and repository are derived from `origin`'s push URL, including HTTPS,
`ssh://`, and scp-style SSH URLs. All GitHub CLI operations target that same
repository, even if the checkout has a different upstream or fetch URL. Multiple
push URLs are rejected. GitHub Enterprise Server uses this same package; provide
a `github-token` issued by an installation on that instance. The URL chooses the
destination, not the token's installation. CLI authentication is task-local and
does not write `gh auth` configuration.

GitHub CLI API requests require the standard HTTPS port (443). Custom HTTPS
ports are rejected; SSH transport ports do not change the API host.

For Enterprise Server, commit authors use the viewer email returned by the
instance, falling back to `login@host` if it is empty. That fallback does not
guarantee account attribution. The runner must be able to reach the instance
and trust its TLS certificate.

## GitHub Token

The `github-token` should be for a
[private GitHub App](https://www.rwx.com/docs/mint/guides/github-automation)
with repository permissions for:

- Contents: read and write
- Pull Requests: read and write

If you request reviews from a `org/team` slug via the `reviewers` parameter,
the app additionally needs organization permission:

- Members: read

## Instructions

- Clone a git repository using the [git/clone](https://www.rwx.com/docs/packages/git/clone) package. Remember to pass `preserve-git-dir: true`.
- Define a task to make the desired changes
- Use this package to create a pull request, or update an existing one identified by the `branch-prefix`.

## Draft Pull Requests

Set `draft: true` to create or keep the pull request as a draft. The default is
`false`, which creates or keeps the pull request ready for review.

## Output Values

| key                 | description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| branch              | The branch for the pull request, or blank if a pull request was not created |
| pull-request-number | The pull request number, or blank a pull request was not created            |

## Example

This example uses a [cron trigger](https://www.rwx.com/docs/mint/cron-schedules) to update RWX packages once per week.

```yaml
on:
  cron:
    - key: update-rwx-packages
      schedule: "0 7 * * 1 America/New_York" # 7am on Mondays

tool-cache:
  vault: your-tool-cache-vault

tasks:
  - key: code
    call: git/clone 2.0.0
    with:
      repository: https://github.com/example-org/example-repo.git
      github-token: ${{ github-apps.your-orgs-bot.token }}
      ref: main
      preserve-git-dir: true

  - key: rwx-cli
    call: rwx/install-cli 2.0.2

  - key: update-packages
    use: [rwx-cli, code]
    cache: false
    run: rwx packages update | tee $RWX_VALUES/update-output

  - key: create-pull-request
    call: github/create-pull-request 1.3.0
    use: [update-packages]
    with:
      github-token: ${{ github-apps.your-orgs-bot.token }}
      branch-prefix: rwx-packages-update
      pull-request-title: Update RWX packages
      pull-request-body: "```\n${{ tasks.update-packages.values.update-output }}\n```"
```

### Enable auto-merge and request reviewers

```yaml
  - key: create-pull-request
    call: github/create-pull-request 1.3.0
    use: [update-packages]
    with:
      github-token: ${{ github-apps.your-orgs-bot.token }}
      branch-prefix: rwx-packages-update
      pull-request-title: Update RWX packages
      pull-request-body: "```\n${{ tasks.update-packages.values.update-output }}\n```"
      enable-auto-merge: true
      reviewers: "octocat,my-org/release-reviewers"
```
