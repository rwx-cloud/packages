# mise/install

Installs [mise](https://mise.jdx.dev) (mise-en-place) and, by default, the tools
declared in your project's mise config (`mise.toml` / `.tool-versions`).

```yaml
tasks:
  - key: code
    call: git/clone

  - key: mise
    use: code
    call: mise/install 1.0.0
    filter:
      - mise.toml
```

This reads the mise config in the checkout root (`mise.toml`, `.mise.toml`, or
`.tool-versions`), installs every tool it declares, and puts them on `PATH`.

### Pin a mise version

```yaml
tasks:
  - key: tools
    use: code
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
    use: [code, mise]
    run: mise exec -- ./scripts/build
```

### Monorepo subdirectory

```yaml
tasks:
  - key: tools
    use: code
    call: mise/install 1.0.0
    with:
      working-directory: services/api
    filter:
      - services/api/mise.toml
```

### Tool versions as output values

When `mise install` runs, each resolved tool version is exported as an
[output value](https://www.rwx.com/docs/output-values) keyed by mise's tool
name, so later tasks can reference a version without re-parsing the config:

```yaml
tasks:
  - key: mise
    use: code
    call: mise/install 1.0.0
    filter:
      - mise.toml

  - key: print-node-version
    use: mise
    run: echo "node $NODE_VERSION"
    env:
      NODE_VERSION: ${{ tasks.mise.values.node }}
```

Values are the concrete resolved versions (for example `24.18.0` even if
the config requested `24`).
