# sonarsource/install-sonar-scanner

The `sonar-scanner-version` parameter is required. You can find the supported versions at https://binaries.sonarsource.com/?prefix=Distribution/sonar-scanner-cli.

Of the listed versions, we support `5.0.0.2966` and higher.

## Example

```yaml
tasks:
  # ... `code` task using mint/git-clone omitted for brevity

  - key: sonar-scanner
    call: sonarsource/install-sonar-scanner 1.0.1
    with:
      sonar-scanner-version: "6.2.1.4610"

  # ... `tests` task omitted for brevity

  - key: scan-coverage
    use: [code, sonar-scanner, tests]
    run: sonar-scanner
    env:
      SONAR_TOKEN: ${{ vaults.your-vault.secrets.SONAR_TOKEN }}
```
