# golang/mod-download

Download your Go modules with better cache efficiency.

## Features

- Downloads all direct and indirect modules specified in `go.mod` and `go.sum`
- Uses `go mod download -reuse` for incremental downloads on subsequent runs

## Usage

```yaml
tasks:
  - key: code
    call: git/clone 2.0.0
    with:
      repository: https://github.com/YOUR_ORG/YOUR_REPO.git
      ref: main
      github-token: ${{ github.token }}

  - key: go
    call: golang/install 1.2.0

  - key: go-modules
    use: [go, code]
    call: golang/mod-download 1.0.0
    filter: [go.mod, go.sum]
    with:
      tool-cache: my-repo-go-modules

  - key: go-test
    use: go-modules
    run: go test ./...
```

If your Go project is not in the workspace root, you can specify a path:

```yaml
  - key: go-modules
    use: [go, code]
    call: golang/mod-download 1.0.0
    filter: [path/to/go.mod, path/to/go.sum]
    with:
      path: path/to
      tool-cache: my-repo-go-modules
```
