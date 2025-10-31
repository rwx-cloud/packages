# erlang/install

To install Erlang:

```yaml
tasks:
  - key: erlang
    call: erlang/install 1.1.1
    with:
      erlang-version: 28.1
```

## Supported Versions

This leaf installs Erlang using precompiled binaries available from [Hex](https://hex.pm).
See [their documentation](https://github.com/hexpm/bob?tab=readme-ov-file#erlang-builds) for supported versions.
