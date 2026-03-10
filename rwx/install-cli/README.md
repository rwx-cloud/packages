# rwx/install-cli

To install the latest version of the RWX CLI:

```yaml
tasks:
  - key: rwx-cli
    call: rwx/install-cli 4.0.3
```

To install a specific version of the RWX CLI:

```yaml
tasks:
  - key: rwx-cli
    call: rwx/install-cli 4.0.3
    with:
      cli-version: v3.7.0
```

For the list of available versions, see the releases on GitHub:

https://github.com/rwx-cloud/cli/releases
