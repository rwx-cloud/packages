# docker/login-hook

Configure a [Mint hook](https://www.rwx.com/docs/mint/hooks) to log in to a Docker registry.

Any task that depends on this leaf and specifies a password or token as the `DOCKER_PASSWORD` environment variable will log in to the Docker registry for the duration of the task.

To avoid persisting credentials to disk, the Docker credentials are cleaned up at the end of each task. Subsequent
tasks that need Docker authentication must also specify the `DOCKER_PASSWORD` environment variable.

Docker Hub is the default registry. If you need to log in to a different registry, you can provide the server address
of the registry as the `registry` parameter to this leaf.

## Example

```yaml
tasks:
  - key: docker-login
    call: docker/login-hook 1.0.3
    with:
      username: my-username

  - key: docker-images
    use: docker-login
    docker: preserve-data
    run: docker compose pull
    env:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

Override the registry:

```yaml
tasks:
  - key: docker-login
    call: docker/login-hook 1.0.3
    with:
      username: my-username
      registry: custom-registry.your-company.com

  - key: docker-images
    use: docker-login
    docker: preserve-data
    run: docker compose pull
    env:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

## Multiple Registries

If you need to log into multiple registries, you can configure `docker/login-hook` more than once.
However, you'll need to specify `password-env-name` to prevent conflicts.

```yaml
tasks:
  - key: docker-login-dockerhub
    call: docker/login-hook 1.0.3
    with:
      username: my-username

  - key: docker-login-other-registry
    call: docker/login-hook 1.0.3
    with:
      username: my-username
      password-env-name: OTHER_REGISTRY_PASSWORD
      registry: custom-registry.your-company.com

  - key: example
    use: [docker-login-dockerhub, docker-login-other-registry]
    docker: preserve-data
    run: docker compose pull
    env:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
      OTHER_REGISTRY_PASSWORD: ${{ secrets.OTHER_REGISTRY_PASSWORD }}
```

## Docker Hub

When authenticating with [Docker Hub](https://hub.docker.com/), we recommend using an
[organization access token](https://docs.docker.com/security/for-admins/access-tokens/). Use your Docker Hub
organization name for the username and the access token for the password:

```yaml
tasks:
  - key: docker-login
    call: docker/login-hook 1.0.3
    with:
      username: my-docker-organization

  - key: docker-images
    use: docker-login
    docker: preserve-data
    run: docker compose pull
    env:
      DOCKER_PASSWORD: ${{ secrets.DOCKER_ORGANIZATION_ACCESS_TOKEN }}
```
