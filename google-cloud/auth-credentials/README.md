# google-cloud/auth-credentials

This leaf requires the Google Cloud CLI be installed. Mint provides the
[google-cloud/install-cli](https://cloud.rwx.com/leaves/google-cloud/install-cli) leaf.

To authenticate with Google Cloud using a service account's credentials JSON (in a secret):

```yaml
tasks:
  - key: gcloud-login
    call: google-cloud/auth-credentials 1.0.4
    with:
      credentials-json: ${{ vaults.your-vault.secrets.GCP_CREDENTIALS_JSON }}
```

A `project-id` may optionally be provided to select an active project for `gcloud`:

```yaml
tasks:
  - key: gcloud-login
    call: google-cloud/auth-credentials 1.0.4
    with:
      credentials-json: ${{ vaults.your-vault.secrets.GCP_CREDENTIALS_JSON }}
      project-id: identifier-of-my-project
```
