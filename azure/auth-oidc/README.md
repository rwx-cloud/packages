# azure/auth-oidc

This package configures hooks that authenticate the Azure CLI through [workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation). It supports service principals and user-assigned managed identities.

The Azure CLI must be installed in each task that uses the authentication hook. RWX provides the [azure/install-cli](https://www.rwx.com/docs/packages/azure/install-cli) package for this.

To authenticate with an identity using a subscription:

```yaml
tasks:
  - key: azure-cli
    call: azure/install-cli 1.0.8

  - key: azure-auth
    call: azure/auth-oidc 2.0.0
    with:
      client-id: ${{ vaults.your-vault.secrets.your-azure-client-id }}
      tenant-id: ${{ vaults.your-vault.secrets.your-azure-tenant-id }}
      subscription-id: ${{ vaults.your-vault.secrets.your-azure-subscription-id }}

  - key: task-that-needs-azure
    use: [azure-cli, azure-auth]
    run: az account show
    env:
      AZURE_OIDC_TOKEN_PATH: ${{ vaults.your-vault.oidc.your-token.path }}
```

The hook accepts either the token file path in `AZURE_OIDC_TOKEN_PATH` or the token contents in `AZURE_OIDC_TOKEN`, but not both. Use the `oidc-token-path-env-var` and `oidc-token-env-var` parameters to customize these environment variable names.

Azure CLI only accepts token contents, not a token-file source. In path mode, the hook reads the current token immediately before each task calls `az login`. Azure CLI will not pick up later rotations while that task is still running.

To authenticate without a subscription when managing tenant-level resources:

```yaml
tasks:
  - key: azure-cli
    call: azure/install-cli 1.0.8

  - key: azure-auth
    call: azure/auth-oidc 2.0.0
    with:
      client-id: ${{ vaults.your-vault.secrets.your-azure-client-id }}
      tenant-id: ${{ vaults.your-vault.secrets.your-azure-tenant-id }}
      allow-no-subscription: true

  - key: task-that-needs-azure
    use: [azure-cli, azure-auth]
    run: az account show
    env:
      AZURE_OIDC_TOKEN: ${{ vaults.your-vault.oidc.your-token }}
```

Set `AZURE_SKIP_AUTH` to skip both login and logout for a task that depends on the hook but does not need Azure authentication.

## Upgrading from v1

Version 1 accepted the OIDC token as a package parameter and authenticated in the package task:

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
```

Version 2 generates hooks instead. Remove the OIDC token parameter and pass the token or token-file path to every task that uses the hook:

```yaml
tasks:
  - key: azure-cli
    call: azure/install-cli 1.0.8

  - key: azure-auth
    call: azure/auth-oidc 2.0.0
    with:
      client-id: ${{ vaults.your-vault.secrets.your-azure-client-id }}
      tenant-id: ${{ vaults.your-vault.secrets.your-azure-tenant-id }}

  - key: task-that-needs-azure
    use: [azure-cli, azure-auth]
    run: az account show
    env:
      AZURE_OIDC_TOKEN_PATH: ${{ vaults.your-vault.oidc.your-token.path }}
```
