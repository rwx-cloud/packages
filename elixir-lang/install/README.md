# elixir-lang/install

To install Elixir, you'll need to have Erlang installed.

```yaml
tasks:
  - key: erlang
    call: erlang/install 1.1.1
    with:
      erlang-version: "26.2.3"

  - key: elixir
    use: erlang
    call: elixir-lang/install 1.1.3
    with:
      elixir-version: "1.17.2"
```

## Supported Versions

This leaf installs Elixir using precompiled binaries.
See [the GitHub releases](https://github.com/elixir-lang/elixir/releases) for supported versions.
