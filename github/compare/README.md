# github/compare

Compares two git refs to determine which files changed and whether they match supplied patterns.

Outputs:

| key | description |
|----|----|
| `changes` | Newline separated filepaths that changed and matched the supplied patterns |
| `has-changes` | Whether there are any changes that matched the pattern (`true` or `false`) |
| `have-changes` | An alias for `has-changes` |

## A single pattern

```yaml
tasks:
  - key: github-cli
    call: github/install-cli 1.0.1

  - key: go-files
    use: github-cli
    call: github/compare 1.0.1
    with:
      repository: my-organization/my-repository
      base-ref: abc123
      head-ref: def456
      github-token: ${{ github.token }}
      patterns: "**/*.go"

  - key: build-go
    if: ${{ tasks.go-files.values.have-changes }
    run: go build
```

## Multiple patterns

```yaml
tasks:
  - key: github-cli
    call: github/install-cli 1.0.1

  - key: go-files
    use: github-cli
    call: github/compare 1.0.1
    with:
      repository: my-organization/my-repository
      base-ref: abc123
      head-ref: def456
      github-token: ${{ github.token }}
      patterns: |
        **/*.go
        go.mod
        go.sum

  - key: build-go
    if: ${{ tasks.go-files.values.have-changes }
    run: go build
```

## From a GitHub Push Trigger

```yaml
on:
  github:
    push:
      - if: ${{ event.git.branch == "main" }}
        init:
          base-ref: ${{ event.github.push.before }}
          head-ref: ${{ event.git.sha }}

      - if: ${{ event.git.branch != "main" }}
        init:
          base-ref: main
          head-ref: ${{ event.git.sha }}

tasks:
  - key: github-cli
    call: github/install-cli 1.0.1

  - key: go-files
    use: github-cli
    call: github/compare 1.0.1
    with:
      repository: my-organization/my-repository
      base-ref: ${{ init.base-ref }}
      head-ref: ${{ init.head-ref }}
      github-token: ${{ github.token }}
      patterns: |
        **/*.go
        go.mod
        go.sum

  - key: build-go
    if: ${{ tasks.go-files.values.have-changes }
    run: go build
```

## From a GitHub Pull Request Trigger

```yaml
on:
  github:
    pull_request:
      init:
        base-ref: ${{ event.github.pull_request.pull_request.base.sha }}
        head-ref: ${{ event.git.sha }}

tasks:
  - key: github-cli
    call: github/install-cli 1.0.1

  - key: go-files
    use: github-cli
    call: github/compare 1.0.1
    with:
      repository: my-organization/my-repository
      base-ref: ${{ init.base-ref }}
      head-ref: ${{ init.head-ref }}
      github-token: ${{ github.token }}
      patterns: |
        **/*.go
        go.mod
        go.sum

  - key: build-go
    if: ${{ tasks.go-files.values.have-changes }
    run: go build
```
