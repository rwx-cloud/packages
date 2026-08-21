# python/install

Installs Python from the [mise precompiled binaries](https://mise.jdx.dev/lang/python.html#precompiled-python-binaries).
Any Python version with a precompiled binary available is supported. You'll need to specify `python-version`.

```yaml
tasks:
  - key: python
    call: python/install 2.0.1
    with:
      python-version: 3.14.7
```

You can optionally specify the version of `pip` to install:

```yaml
tasks:
  - key: python
    call: python/install 2.0.1
    with:
      python-version: 3.14.7
      pip-version: 25.0.1
```

And the version of `setuptools`:

```yaml
tasks:
  - key: python
    call: python/install 2.0.1
    with:
      python-version: 3.14.7
      pip-version: 25.0.1
      setuptools-version: 78.1.0
```

By default, the GitHub artifact attestations of the precompiled binary are verified before it is installed.
To skip verification, set `ensure-github-attestations` to `"false"`:

```yaml
tasks:
  - key: python
    call: python/install 2.0.1
    with:
      python-version: 3.14.7
      ensure-github-attestations: "false"
```

If you do not specify `pip-version` or `setuptools-version`, the versions bundled with the precompiled binary will be installed.
NOTE: Python versions 3.12.0 and greater do not install `setuptools` by default. See [docker-library/python#952](https://github.com/docker-library/python/issues/952) for more information on this decision. If you would like to install setuptools via this package, pass the `setuptools-version` parameter.
