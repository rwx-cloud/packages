# azure/install-cli

To install the latest version of the Azure CLI:

```yaml
tasks:
  - key: azure-cli
    call: azure/install-cli 1.0.9
```

To install a specific version of the Azure CLI:

```yaml
tasks:
  - key: azure-cli
    call: azure/install-cli 1.0.9
    with:
      version: "2.65.0"
```

For the list of available versions, see the Azure CLI release notes:

https://learn.microsoft.com/en-us/cli/azure/release-notes-azure-cli
