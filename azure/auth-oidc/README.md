# azure/auth-oidc

This leaf authenticates the Azure CLI via OIDC. It works with Azure's [workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation).
Specifically, you can authenticate as a service principal or user-assigned managed identity.

The Azure CLI is required. Mint provides the [azure/install-cli](https://www.rwx.com/docs/packages/azure/install-cli) leaf.

To authenticate with an identity using a subscription:

```yaml
tasks:
  - key: azure-cli
    call: azure/install-cli 1.0.8

  - key: azure-auth
    use: azure-cli
    call: azure/auth-oidc 1.0.7
    with:
      oidc-token-path: ${{ vaults.your-vault.oidc.your-token.path }}
      client-id: ${{ vaults.your-vault.secrets.your-azure-client-id }}
      tenant-id: ${{ vaults.your-vault.secrets.your-azure-tenant-id }}
      subscription-id: ${{ vaults.your-vault.secrets.your-azure-subscription-id }}
```

The package accepts either `oidc-token-path` or `oidc-token`. Token files are refreshed during long-running tasks, so prefer `oidc-token-path` when it is available.

To authenticate without a subscription (when managing tenant-level resources):

```yaml
tasks:
  - key: azure-cli
    call: azure/install-cli 1.0.8

  - key: azure-auth
    use: azure-cli
    call: azure/auth-oidc 1.0.7
    with:
      oidc-token: ${{ vaults.your-vault.oidc.your-token }}
      client-id: ${{ vaults.your-vault.secrets.your-azure-client-id }}
      tenant-id: ${{ vaults.your-vault.secrets.your-azure-tenant-id }}
      allow-no-subscription: true
```
