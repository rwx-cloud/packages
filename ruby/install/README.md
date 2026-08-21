# ruby/install

Installs Ruby from the [mise precompiled binaries](https://mise.jdx.dev/lang/ruby.html#precompiled-binaries).
Any Ruby version with a precompiled binary available is supported. You'll either need to specify `ruby-version` or `ruby-version-file`.

## With a .ruby-version file

If your project has a `.ruby-version` file:

```yaml
tasks:
  - key: ruby
    call: ruby/install 2.0.1
    with:
      ruby-version-file: .ruby-version
    filter: [.ruby-version]
```

Remember to include the [`filter`](https://www.rwx.com/docs/mint/filtering-files) so that the task will be cached only based on the contents of the `.ruby-version` file.

## Specifying a version

If your project does not have a `.ruby-version` file, you can specify the version manually in your task:

```yaml
tasks:
  - key: ruby
    call: ruby/install 2.0.1
    with:
      ruby-version: 3.4.10
```

## GitHub attestation verification

By default, the GitHub artifact attestations of the precompiled binary are verified before it is installed.
To skip verification, set `ensure-github-attestations` to `"false"`:

```yaml
tasks:
  - key: ruby
    call: ruby/install 2.0.1
    with:
      ruby-version: 3.4.10
      ensure-github-attestations: "false"
```
