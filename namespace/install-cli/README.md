# namespace/install-cli

To install the latest version of the Namespace CLI:

```yaml
tasks:
  - key: namespace-cli
    call: namespace/install-cli 1.0.2
```

To install a specific version of the Namespace CLI:

```yaml
tasks:
  - key: namespace-cli
    call: namespace/install-cli 1.0.2
    with:
      cli-version: "0.0.437"
```
