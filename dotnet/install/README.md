# dotnet/install

Install one or more .NET SDK versions.

## Install a single channel

```yaml
tasks:
  - key: dotnet
    call: dotnet/install 1.0.1
    with:
      dotnet-channel: "8.0"
```

## Install from global.json

```yaml
tasks:
  - key: dotnet
    use: code
    call: dotnet/install 1.0.1
    with:
      global-json-file: global.json
    filter:
      - global.json
```

## Install multiple channels in one call

```yaml
tasks:
  - key: dotnet
    call: dotnet/install 1.0.1
    with:
      dotnet-channels: '["8.0", "9.0", "10.0"]'
      dotnet-quality: preview
```

When installing multiple SDKs, `--skip-non-versioned-files` will automatically be appended to the install script for subsequent installs, so they do not overwrite non-versioned files from earlier installs.

`dotnet/install` automatically configures `PATH` and `DOTNET_ROOT` for downstream tasks.
