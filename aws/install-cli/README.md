# aws/install-cli

To install the latest version of the AWS CLI:

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.7
```

To install a specific version of the AWS CLI (only v2 of the AWS CLI is supported):

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.7
    with:
      cli-version: "2.15.13"
```

For the list of available versions, see the AWS CLI changelog on GitHub:

https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst
