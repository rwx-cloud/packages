# aws/install-cli

To install the latest version of the AWS CLI:

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 2.0.0
```

To install a specific version of the AWS CLI (only v2 of the AWS CLI is supported):

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 2.0.0
    with:
      cli-version: "2.15.13"
```

For the list of available versions, see the AWS CLI changelog on GitHub:

https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst

## Upgrading to 2.0.0

Version 2.0.0 no longer automatically installs `unzip` and `gpg` if they are missing. If your base image does not include these tools, you will need to install them yourself and specify that task as a `use` dependency.

```yaml
tasks:
  - key: install-deps
    run: |
      apt-get update
      apt-get install -y unzip gnupg
      apt-get clean

  - key: aws-cli
    use: install-deps
    call: aws/install-cli 2.0.0
```
