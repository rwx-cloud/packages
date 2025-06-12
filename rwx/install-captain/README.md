## rwx/install-captain

Captain is an open source CLI that can detect and quarantine flaky tests,
automatically retry failed tests, partition files for parallel execution,
and more. It's compatible with 15 testing frameworks.

To install the latest version of the Captain CLI:

```yaml
tasks:
  - key: captain
    call: rwx/install-captain 1.0.5
```

To install a specific version of the Captain CLI:

```yaml
tasks:
  - key: captain
    call: rwx/install-captain 1.0.5
    with:
      captain-version: v1.18.3
```

For the list of available versions, see the releases on GitHub:

https://github.com/rwx-research/captain/releases
