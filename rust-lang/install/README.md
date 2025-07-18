# rust-lang/install

To install Rust:

```yaml
tasks:
  - key: rust-lang
    call: rust-lang/install 1.0.4
    with:
      rust-version: 1.83.0
```

## Supported Versions

This leaf installs Rust using the `rustup` installer. In addition to the current stable version of Rust,
versions in the [archive](https://forge.rust-lang.org/infra/archive-stable-version-installers.html) are
available.
