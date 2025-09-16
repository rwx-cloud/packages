# ruby/install

RWX currently supports Ruby versions 3.1.0 through 3.4.6. You'll either need to specify `ruby-version` or `ruby-version-file`.

## With a .ruby-version file

If your project has a `.ruby-version` file:

```yaml
tasks:
  - key: ruby
    call: ruby/install 1.2.9
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
    call: ruby/install 1.2.9
    with:
      ruby-version: 3.4.6
```
