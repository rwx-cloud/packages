# mise/install

Installs [mise](https://mise.jdx.dev) (mise-en-place) and, by default, the tools
declared in your project's mise config (`mise.toml` / `.tool-versions`). The
installed tools (Ruby, Python, Node, etc.) are added to `PATH` via mise's shims,
so they are available to later tasks.

To install mise and the tools defined in your config:

```yaml
tasks:
  - key: tools
    call: mise/install 1.0.0
```

This reads the mise config in the checkout root (`mise.toml`, `.mise.toml`, or
`.tool-versions`), installs every tool it declares, and puts them on `PATH`.

## Config file

mise's native config is `mise.toml` (it also accepts `.mise.toml` and
`.config/mise/config.toml`). mise **also** reads asdf's `.tool-versions`
directly with no conversion, as well as `.ruby-version`, `.node-version`,
`.nvmrc`, etc. This means you can migrate from `.tool-versions` incrementally —
your existing files keep working. Moving to `mise.toml` additionally lets you
define environment variables and tasks alongside your tool versions.

## Parameters

| Parameter           | Default    | Description |
|---------------------|------------|-------------|
| `mise-version`      | `latest`   | Version of mise to install (e.g. `2026.7.11`), or `latest`. |
| `install`           | `true`     | Run `mise install` to install the tools from the project config. Set to `false` to install only the mise CLI. |
| `working-directory` | (checkout) | Directory to run `mise install` in (where the mise config lives). Useful for monorepos. |
| `ruby-compile`      | `false`    | Ruby install strategy (see below). |

### Pin a mise version

```yaml
tasks:
  - key: tools
    call: mise/install 1.0.0
    with:
      mise-version: "2026.7.11"
```

### Install only the mise CLI

```yaml
tasks:
  - key: mise
    call: mise/install 1.0.0
    with:
      install: "false"
  - key: build
    use: mise
    run: mise exec -- ./scripts/build
```

### Monorepo subdirectory

```yaml
tasks:
  - key: tools
    call: mise/install 1.0.0
    with:
      working-directory: services/api
```

## Ruby and Python binaries

- **Python** is installed from **precompiled binaries** by default
  (python-build-standalone) — no source compilation, so installs take seconds.
- **Ruby** currently compiles from source by default in mise. This package sets
  `ruby.compile=false` by default so mise uses **precompiled Ruby binaries**
  (available for linux x86_64 and arm64) and only falls back to compiling from
  source when a prebuilt binary is unavailable. Set `ruby-compile: "true"` to
  always compile from source, or leave it empty to use mise's own default.

```yaml
tasks:
  - key: tools
    call: mise/install 1.0.0
    with:
      ruby-compile: "true"
```

## Platform support

mise runs on Linux x86_64 and arm64. This package installs the mise CLI via
`https://mise.run` and requires `curl` (installed automatically on `apt`- and
`apk`-based images if missing).
