# render/deploy

Deploy applications to [Render](https://render.com).

The Render service you provide must exist. This task will deploy to any
service types that Render supports building. It does not yet support
deploying from third-party container registries.

## Example

```yaml
tasks:
  # ... `test` task omitted for brevity

  - key: deploy
    after: test
    call: render/deploy 1.0.2
    with:
      ref: ${{ init.commit-sha }}
      render-api-key: ${{ vaults.your-vault.secrets.RENDER_API_KEY }}
      service-name: your-render-service-name
```
