# rwx/package

Build and upload an RWX package.

This package zips a directory and uploads it to the RWX package registry, returning the content digest of the uploaded package.

## Usage

```yaml
tasks:
  - key: package
    call: rwx/package 1.0.0
    with:
      directory: path/to/package
      rwx-access-token: ${{ secrets.RWX_ACCESS_TOKEN }}
```
