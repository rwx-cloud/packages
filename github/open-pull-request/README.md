# mint/update-leaves-github

Update the versions of Mint leaves used in a GitHub repository.
When updates are available, open or update a pull request.

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
  - key: mint-update-leaves
    call: mint/update-leaves-github 1.0.9
    with:
      repository: https://github.com/YOUR-ORG/YOUR-REPO.git
      ref: ${{ init.commit-sha }}
      github-access-token: ${{ vaults.MY_VAULT.github-apps.MY-GITHUB-APP.token }}
```

Customize the label and color name:

```yaml
tasks:
  - key: mint-update-leaves
    call: mint/update-leaves-github 1.0.9
    with:
      repository: https://github.com/YOUR-ORG/YOUR-REPO.git
      ref: ${{ init.commit-sha }}
      github-access-token: ${{ vaults.MY_VAULT.github-apps.MY-GITHUB-APP.token }}
      label: mint-updates
      label-color: "298F21"
```

Setting `label` to an empty string will skip labeling new pull requests.

Pull requests that may be eligible for update are any for this repository
that have been created by your private GitHub App and, if not set to an empty
string, having the provided `label`.

**If you reuse the same private GitHub App for other tasks, you should not set
`label` to an empty string. When not provided, it will default to `mint-updates`.**
