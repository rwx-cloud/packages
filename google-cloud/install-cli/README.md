# google-cloud/install-cli

To install the latest version of the Google Cloud CLI:

```yaml
tasks:
  - key: gcloud-cli
    call: google-cloud/install-cli 1.1.5
```

To install a specific version of the Google Cloud CLI:

```yaml
tasks:
  - key: gcloud-cli
    call: google-cloud/install-cli 1.1.5
    with:
      cli-version: "465.0.0"
```

For the list of available versions, see the Google Cloud CLI release notes:

https://cloud.google.com/sdk/docs/release-notes
