# entire/install

Install the Entire CLI using the official installer. The installation is cached for one day.

Requires `curl` and `bash`. The package adds `~/.local/bin` to `PATH` for subsequent tasks, including the `git-remote-entire` helper used for `entire://` repositories.

```yaml
tasks:
  - key: entire
    call: entire/install 1.0.0

  - key: check-entire
    use: entire
    run: entire version
```
