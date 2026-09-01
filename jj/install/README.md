# jj/install

To install the latest version of [Jujutsu (jj)](https://github.com/jj-vcs/jj):

```yaml
tasks:
  - key: jj
    call: jj/install 1.0.0
```

To install a specific version of Jujutsu:

```yaml
tasks:
  - key: jj
    call: jj/install 1.0.0
    with:
      version: "0.44.0"
```

For the list of available versions, see the Jujutsu releases on GitHub:

https://github.com/jj-vcs/jj/releases
