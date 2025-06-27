# depot/install-cli

To install the latest version of the Depot CLI:

```yaml
tasks:
  - key: depot-cli
    call: depot/install-cli 1.0.3
```

To install a specific version of the Depot CLI:

```yaml
tasks:
  - key: depot-cli
    call: depot/install-cli 1.0.3
    with:
      cli-version: "2.53.0"
```

For the list of available versions, see the Depot CLI releases on GitHub:

https://github.com/depot/cli/releases
