# hashicorp/install-terraform

To install the latest version of the Terraform CLI:

```yaml
tasks:
  - key: terraform
    call: hashicorp/install-terraform 1.0.8
```

To install a specific version of the Terraform CLI:

```yaml
tasks:
  - key: terraform
    call: hashicorp/install-terraform 1.0.8
    with:
      terraform-version: "1.7.3"
```

For the list of available versions, see the Terraform releases on GitHub:

https://github.com/hashicorp/terraform/releases
