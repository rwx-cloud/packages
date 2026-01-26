# pagerduty/verify-signature

Verify PagerDuty [webhook signatures](https://developer.pagerduty.com/docs/verifying-webhook-signatures).

```yaml
tasks:
  - key: verify-signature
    call: pagerduty/verify-signature 1.0.0
    with:
      body: ${{ init.body }}
      headers: ${{ init.headers }}
      secret: ${{ vaults.your-vault.secrets.PAGERDUTY_WEBHOOK_SECRET }}

  - key: automate-the-thing
    after: verify-signature
    run: ....
    env:
      BODY: ${{ init.body }}
```
