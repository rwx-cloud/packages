# tailscale/install

To install the latest version of Tailscale:

```yaml
tasks:
  - key: tailscale
    call: tailscale/install 1.0.2
```

To install a specific version of Tailscale:

```yaml
tasks:
  - key: tailscale
    call: tailscale/install 1.0.2
    with:
      version: "1.78.1"
```

For the list of available versions, see the "Packages" page of Tailscale:

https://pkgs.tailscale.com/stable
