# namespace/login-hook

Configure an [RWX hook](https://www.rwx.com/docs/mint/hooks) to log in to [Namespace](https://namespace.so/).

Any task that depends on this package and specifies an OIDC token file path in `NAMESPACE_OIDC_TOKEN_PATH` or token contents in `NAMESPACE_OIDC_TOKEN` will log in to Namespace for the duration of the task.

Namespace CLI only accepts token contents, not a token-file source. When `NAMESPACE_OIDC_TOKEN_PATH` is used, the login hook reads the current token once before the task and exchanges it for Namespace credentials. Namespace will not pick up later rotations during the same task.

To avoid persisting credentials to disk, the Namespace credentials are cleaned up at the end of each task. Subsequent
tasks that need Namespace authentication must also specify one of these environment variables.

## Example

```yaml
tasks:
  - key: namespace-cli
    call: namespace/install-cli 1.0.0

  - key: namespace-login
    call: namespace/login-hook 1.0.3
    with:
      workspace-id: my-namespace-workspace-id

  - key: namespace-build
    use: [namespace-cli, namespace-login]
    run: |
      nsc build --name foo/bar --push .
    env:
      NAMESPACE_OIDC_TOKEN_PATH: ${{ vaults.your-rwx-vault.oidc.token-name.path }}
```

## Multiple Workspaces

If you need to log into multiple workspaces, you can configure `namespace/login-hook` more than once.
However, you'll need to specify `oidc-token-env-name` or `oidc-token-path-env-name` to prevent conflicts.

```yaml
tasks:
  - key: namespace-cli
    call: namespace/install-cli 1.0.0

  - key: namespace-login-to-workspace-a
    call: namespace/login-hook 1.0.3
    with:
      workspace-id: my-namespace-workspace-id
      oidc-token-env-name: NAMESPACE_OIDC_TOKEN_A

  - key: namespace-login-to-workspace-b
    call: namespace/login-hook 1.0.3
    with:
      workspace-id: my-namespace-workspace-id
      oidc-token-env-name: NAMESPACE_OIDC_TOKEN_B

  - key: namespace-build-in-workspace-a
    use: [namespace-cli, namespace-login-to-workspace-a]
    run: |
      nsc build --name foo/bar --push .
    env:
      NAMESPACE_OIDC_TOKEN_A: ${{ vaults.your-rwx-vault.oidc.token-a }}

  - key: namespace-build-in-workspace-b
    use: [namespace-cli, namespace-login-to-workspace-b]
    run: |
      nsc build --name foo/bar --push .
    env:
      NAMESPACE_OIDC_TOKEN_B: ${{ vaults.your-rwx-vault.oidc.token-b }}
```
