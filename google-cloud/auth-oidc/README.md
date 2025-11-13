# google-cloud/auth-oidc

This leaf requires the Google Cloud CLI be installed. Mint provides the
[google-cloud/install-cli](https://cloud.rwx.com/leaves/google-cloud/install-cli) leaf.

To authenticate with Google Cloud using OIDC and direct Workload Identity Federation:

```yaml
tasks:
  - key: gcloud-login
    call: google-cloud/auth-oidc 1.0.9
    with:
      oidc-token: ${{ vaults.your-vault.oidc.gcp }}
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}
```

To authenticate with Google Cloud using OIDC and a Service Account:

```yaml
tasks:
  - key: gcloud-login
    call: google-cloud/auth-oidc 1.0.9
    with:
      oidc-token: ${{ vaults.your-vault.oidc.gcp }}
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}
      service-account: ${{ vaults.your-vault.secrets.SERVICE_ACCOUNT }}
```

A `project-id` may optionally be provided to select an active project for `gcloud`:

```yaml
tasks:
  - key: gcloud-login
    call: google-cloud/auth-oidc 1.0.9
    with:
      oidc-token: ${{ vaults.your-vault.oidc.gcp }}
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}
      project-id: identifier-of-my-project
```

For more information about Mint and OIDC, please [see the Mint documentation](https://www.rwx.com/docs/mint/oidc).
