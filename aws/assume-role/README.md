# aws/assume-role

To assume a role:

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role

  - key: task-that-needs-role
    use: [aws-cli, assume-role]
    run: ...
    env:
      AWS_OIDC_TOKEN:
        value: ${{ vaults.your-vault.oidc.your-token }}
        cache-key: excluded
```

If for some reason you need to opt-out of role assumption, your task can set specify the environment variable `AWS_SKIP_AUTH` to true.

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role

  - key: task-that-does-not-need-role
    use: [aws-cli, assume-role]
    run: ...
    env:
      AWS_SKIP_AUTH: true
```

To specify the length of the session:

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role
      role-duration-seconds: 3600

  - key: task-that-needs-role
    use: [aws-cli, assume-role]
    run: ...
    env:
      AWS_OIDC_TOKEN:
        value: ${{ vaults.your-vault.oidc.your-token }}
        cache-key: excluded
```

To choose a name for the session:

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role
      role-session-name: your-unique-session-name-${{ run.id }}

  - key: task-that-needs-role
    use: [aws-cli, assume-role]
    run: ...
    env:
      AWS_OIDC_TOKEN:
        value: ${{ vaults.your-vault.oidc.your-token }}
        cache-key: excluded
```

To configure a specific profile:

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role
      profile-name: your-profile

  - key: task-that-needs-role
    use: [aws-cli, assume-role]
    run: ...
    env:
      AWS_OIDC_TOKEN:
        value: ${{ vaults.your-vault.oidc.your-token }}
        cache-key: excluded
```

To assume another role, via chaining:

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      oidc-token: ${{ vaults.your-vault.oidc.your-token }}
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role

  - key: chained-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-other-role
      role-chaining: true

  - key: task-that-needs-chained-role
    use: [aws-cli, assume-role, chained-role]
    run: ...
    env:
      AWS_OIDC_TOKEN:
        value: ${{ vaults.your-vault.oidc.your-token }}
        cache-key: excluded
```

To assume another role, via chaining, with specific profiles:

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role
      profile-name: your-profile

  - key: chained-role
    call: aws/assume-role 2.0.4
    with:
      source-profile-name: your-profile
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-other-role
      profile-name: your-other-profile

  - key: task-that-needs-chained-role
    use: [aws-cli, assume-role, chained-role]
    run: ...
    env:
      AWS_OIDC_TOKEN:
        value: ${{ vaults.your-vault.oidc.your-token }}
        cache-key: excluded
```

## Upgrading from v1.X.X

In v1.X.X the AWS OIDC token was provided as a leaf parameter.
Starting in version 2, the AWS OIDC token is provided to tasks that use the assume role leaf task as an environment variable (by default `AWS_OIDC_TOKEN`).

With this change, the task will run the role assumption as a before hook.
As a result of this, upon retrying a task, a new token will be used, preventing the incidental use of expired credentials.

### Assuming a Role

#### Before

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    use: aws-cli
    call: aws/assume-role 1.1.4 # deprecated by 2.0.0
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role
      oidc-token: ${{ vaults.your-vault.oidc.your-token }}

  - key: your-task
    use: assume-role
    run: # ...
```

#### After

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role

  - key: your-task
    use: [aws-cli, assume-role]
    run: ...
    env:
      AWS_OIDC_TOKEN:
        value: ${{ vaults.your-vault.oidc.your-token }}
        cache-key: excluded
```

### Role Chaining

#### Before

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    use: aws-cli
    call: aws/assume-role 1.1.4 # deprecated by 2.0.0
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role
      oidc-token: ${{ vaults.your-vault.oidc.your-token }}

  - key: chain-role
    use: assume-role
    call: aws/assume-role 1.1.4 # deprecated by 2.0.0
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-other-role

  - key: your-task
    use: chain-role
    run: ...
```

#### After

```yaml
tasks:
  - key: aws-cli
    call: aws/install-cli 1.0.2

  - key: assume-role
    call: aws/assume-role 2.0.4
    with:
      oidc-token: ${{ vaults.your-vault.oidc.your-token }}
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-role

  - key: chain-role
    call: aws/assume-role 2.0.4
    with:
      region: us-east-2
      role-to-assume: arn:aws:iam::your-account-id:role/your-other-role
      role-chaining: true

  - key: your-task
    use: [aws-cli, assume-role, chain-role]
    run: ...
    env:
      AWS_OIDC_TOKEN:
        value: ${{ vaults.your-vault.oidc.your-token }}
        cache-key: excluded
```
