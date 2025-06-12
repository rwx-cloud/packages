# kubernetes/install-cli

To install the latest version of the Kubernetes CLI (kubectl):

```yaml
tasks:
  - key: kubectl-cli
    call: kubernetes/install-cli 1.0.4
```

To install a specific version of the Kubernetes CLI:

```yaml
tasks:
  - key: kubectl-cli
    call: kubernetes/install-cli 1.0.4
    with:
      cli-version: "1.29.2"
```

For the list of available versions, see the Kubernetes releases:

https://kubernetes.io/releases/
