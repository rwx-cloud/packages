# rwx/install-cli

To install the latest version of the RWX CLI:

```yaml
tasks:
  - key: rwx-cli
    call: rwx/install-cli 4.0.1
```

To install a specific version of the RWX CLI:

```yaml
tasks:
  - key: rwx-cli
    call: rwx/install-cli 4.0.1
    with:
      cli-version: v1.10.0
```

For the list of available versions, see the releases on GitHub:

https://github.com/rwx-cloud/cli/releases
