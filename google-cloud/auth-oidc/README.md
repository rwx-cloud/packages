# google-cloud/auth-oidc

## Dependencies

The `google-cloud/auth-oidc` package requires `jq` and the Google Cloud CLI to be installed.

If you're using the RWX base configuration, then `jq` will already be installed.

```yaml
base:
  image: ubuntu:24.04
  config: rwx/base 1.0.0
```

However, if you are running without the RWX base configuration, then you will need to install `jq` and specify a `use` dependency on tasks that authenticate with Google Cloud.

RWX provides the [google-cloud/install-cli](https://www.rwx.com/docs/packages/google-cloud/install-cli) package for installing the Google Cloud CLI.

To authenticate with Google Cloud using OIDC and direct Workload Identity Federation:

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-oidc 2.0.0
    with:
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}

  - key: task-that-needs-gcloud
    use: [install-gcloud, gcloud-auth]
    run: gcloud ...
    env:
      GCP_OIDC_TOKEN: ${{ vaults.your-vault.oidc.gcp }}
```

To authenticate with Google Cloud using OIDC and a Service Account:

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-oidc 2.0.0
    with:
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}
      service-account: ${{ vaults.your-vault.secrets.SERVICE_ACCOUNT }}

  - key: task-that-needs-gcloud
    use: [install-gcloud, gcloud-auth]
    run: gcloud ...
    env:
      GCP_OIDC_TOKEN: ${{ vaults.your-vault.oidc.gcp }}
```

A `project-id` may optionally be provided to select an active project for `gcloud`:

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-oidc 2.0.0
    with:
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}
      project-id: identifier-of-my-project

  - key: task-that-needs-gcloud
    use: [install-gcloud, gcloud-auth]
    run: gcloud ...
    env:
      GCP_OIDC_TOKEN: ${{ vaults.your-vault.oidc.gcp }}
```

If for some reason you need to opt-out of authentication, your task can specify the environment variable `GCP_SKIP_AUTH` to true.

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-oidc 2.0.0
    with:
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}

  - key: task-that-does-not-need-gcloud
    use: [install-gcloud, gcloud-auth]
    run: ...
    env:
      GCP_SKIP_AUTH: true
```

For more information about RWX and OIDC, please [see the RWX documentation](https://www.rwx.com/docs/oidc).

## Upgrading from v1.X.X

In v1.X.X the OIDC token was provided as a package parameter.
Starting in version 2, the OIDC token is provided to tasks that use the auth-oidc package as an environment variable (by default `GCP_OIDC_TOKEN`).

With this change, the task will run authentication as a before hook.
As a result of this, upon retrying a task, a new token will be used, preventing the incidental use of expired credentials, and the hook generation task itself is cacheable.

### Before

```yaml
tasks:
  - key: gcloud-login
    use: install-gcloud
    call: google-cloud/auth-oidc 1.0.9
    with:
      oidc-token: ${{ vaults.your-vault.oidc.gcp }}
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}
```

### After

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-oidc 2.0.0
    with:
      workload-identity-provider: ${{ vaults.your-vault.secrets.WORKLOAD_IDENTITY_PROVIDER }}

  - key: your-task
    use: [install-gcloud, gcloud-auth]
    run: ...
    env:
      GCP_OIDC_TOKEN: ${{ vaults.your-vault.oidc.gcp }}
```
