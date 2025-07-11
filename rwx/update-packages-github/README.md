# rwx/update-packages-github

Update the versions of RWX packages used in a GitHub repository.
When updates are available, create or update a pull request.

The provided `github-access-token` should be for a
[private GitHub App](https://www.rwx.com/docs/mint/guides/github-automation)
with repository permissions for:

- Contents: read and write
- Pull Requests: read and write

If you would like to automatically create the `label`, additionally provide:

- Issues: read and write
- Projects: read only (see [github/cli discussion](https://github.com/cli/cli/discussions/5307))

To update minor versions (recommended):

```yaml
tasks:
  - key: update-rwx-packages
    call: rwx/update-packages-github 1.1.0
    with:
      repository: https://github.com/YOUR-ORG/YOUR-REPO.git
      ref: ${{ init.commit-sha }}
      github-access-token: ${{ vaults.your-vault.github-apps.your-github-app.token }}
```

Customize the label:

```yaml
tasks:
  - key: update-rwx-packages
    call: rwx/update-packages-github 1.1.0
    with:
      repository: https://github.com/YOUR-ORG/YOUR-REPO.git
      ref: ${{ init.commit-sha }}
      github-access-token: ${{ vaults.your-vault.github-apps.your-github-app.token }}
      label: rwx-updates
      label-color: "298F21"
```
