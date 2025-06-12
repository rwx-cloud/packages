# golang/install

To install the latest version of go:

```yaml
tasks:
  - key: go
    call: golang/install 1.1.2
```

To install a specific version:

```yaml
tasks:
  - key: go
    call: golang/install 1.1.2
    with:
      go-version: "1.21.5"
```

If the patch version is omitted, the latest patch version for the given minor
version will be downloaded.

A minor or patch version must be specified.

## Checksum verification

`golang/install` downloads go binaries from https://go.dev/dl/. Most downloads
include a sha256 checksum that is verified. However, some downloads of older go
versions include only a sha1 checksum, that is not made available via the API
that `golang/install` uses. For such downloads, checksum verification is
skipped.
