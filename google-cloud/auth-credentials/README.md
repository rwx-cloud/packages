# google-cloud/auth-credentials

This package requires the Google Cloud CLI be installed. RWX provides the
[google-cloud/install-cli](https://www.rwx.com/docs/packages/google-cloud/install-cli) package.

To authenticate with Google Cloud using a service account's credentials JSON (in a secret):

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-credentials 2.0.0

  - key: task-that-needs-gcloud
    use: [install-gcloud, gcloud-auth]
    run: gcloud ...
    env:
      GCP_CREDENTIALS_JSON:
        value: ${{ vaults.your-vault.secrets.GCP_CREDENTIALS_JSON }}
        cache-key: excluded
```

A `project-id` may optionally be provided to select an active project for `gcloud`:

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-credentials 2.0.0
    with:
      project-id: identifier-of-my-project

  - key: task-that-needs-gcloud
    use: [install-gcloud, gcloud-auth]
    run: gcloud ...
    env:
      GCP_CREDENTIALS_JSON:
        value: ${{ vaults.your-vault.secrets.GCP_CREDENTIALS_JSON }}
        cache-key: excluded
```

If for some reason you need to opt-out of authentication, your task can specify the environment variable `GCP_SKIP_AUTH` to true.

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-credentials 2.0.0

  - key: task-that-does-not-need-gcloud
    use: [install-gcloud, gcloud-auth]
    run: ...
    env:
      GCP_SKIP_AUTH: true
```

## Upgrading from v1.X.X

In v1.X.X the credentials JSON was provided as a package parameter.
Starting in version 2, the credentials JSON is provided to tasks that use the auth credentials package as an environment variable (by default `GCP_CREDENTIALS_JSON`).

With this change, the task will run authentication as a before hook.
As a result of this, upon retrying a task, fresh credentials will be used, and the hook generation task itself is cacheable.

### Before

```yaml
tasks:
  - key: gcloud-login
    use: install-gcloud
    call: google-cloud/auth-credentials 1.0.7
    with:
      credentials-json: ${{ vaults.your-vault.secrets.GCP_CREDENTIALS_JSON }}
```

### After

```yaml
tasks:
  - key: install-gcloud
    call: google-cloud/install-cli 1.1.6

  - key: gcloud-auth
    call: google-cloud/auth-credentials 2.0.0

  - key: your-task
    use: [install-gcloud, gcloud-auth]
    run: ...
    env:
      GCP_CREDENTIALS_JSON:
        value: ${{ vaults.your-vault.secrets.GCP_CREDENTIALS_JSON }}
        cache-key: excluded
```
