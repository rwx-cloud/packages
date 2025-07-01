# github/create-pull-request

Creates a pull request or updates an existing one.

## GitHub Token

The `github-token` should be for a
[private GitHub App](https://www.rwx.com/docs/mint/guides/github-automation)
with repository permissions for:

- Contents: read and write
- Pull Requests: read and write

## Instructions

- Clone a git repository using the [git/clone](https://www.rwx.com/docs/mint/leaves/git/clone) package. Remember to pass `preserve-git-dir: true`.
- Define a task to make the desired changes
- Use this package to create a pull request, or update an existing one identified by the `branch-prefix`.

## Example

This example uses a [cron trigger](https://www.rwx.com/docs/mint/cron-schedules) to update RWX packages once per week.

```yaml
on:
  cron:
    - key: update-rwx-packages
      schedule: "0 7 * * 1 America/New_York" # 7am on Mondays

tasks:
  - key: code
    call: git/clone 1.6.5
    with:
      repository: https://github.com/example-org/example-repo.git
      github-access-token: ${{ github-apps.your-orgs-bot.token }}
      ref: main
      preserve-git-dir: true

  - key: rwx-cli
    call: rwx/install-cli 2.0.1

  - key: update-packages
    use: [rwx-cli, code]
    cache: false
    run: rwx packages update | tee $RWX_VALUES/update-output

  - key: create-pull-request
    call: github/create-pull-request 1.0.0
    use: [update-packages]
    with:
      github-token: ${{ github-apps.your-orgs-bot.token }}
      branch-prefix: rwx-packages-update
      pull-request-title: Update RWX packages
      pull-request-body: "```\n${{ tasks.update-packages.values.update-output }}\n```"
```
