# rwx/bootstrap

This package is called internally within RWX to bootstrap base images.
RWX calls it automatically; you do not need to use it directly.

It extracts a container image which is then used as a base image for an RWX run.

The image is pulled and unpacked with [crane](https://github.com/google/go-containerregistry),
so no container runtime is started and the task does not set `docker: true`.
The base layer this runs on must provide `crane`, `jq` and `tar`.
