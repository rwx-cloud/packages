# rwx/tool-versions

Extract the versions specified in a `.tool-versions` file, used by tools such as
[asdf](https://asdf-vm.com/) and [mise-en-place](https://mise.jdx.dev/).

Versions are available as [output values](https://www.rwx.com/docs/mint/output-values)
after calling this leaf.

## Example

If your project has a `.tool-versions` file:

```yaml
nodejs 22.4.1
ruby 3.3.2
```

Capture the versions to pass to other tasks:

```yaml
tasks:
  - key: code
    call: git/clone 2.0.0
    with:
      repository: https://github.com/YOUR_ORG/YOUR_REPO.git
      ref: ${{ init.ref }
      github-token: ${{ github.token }}

  - key: tool-versions
    use: code
    call: rwx/tool-versions 1.0.6
    filter: [.tool-versions]

  - key: nodejs
    call: nodejs/install 1.1.10
    with:
      node-version: ${{ tasks.tool-versions.values.nodejs }}

  - key: ruby
    call: ruby/install 1.2.13
    with:
      ruby-version: ${{ tasks.tool-versions.values.ruby }}
```

The output value is named based on the tool name, so we have `nodejs` and `ruby` in this example.

Remember to include the [`filter`](https://www.rwx.com/docs/mint/filtering-files) so that the task will be cached only based on the contents of the `.tool-versions` file.
