# podman-insider

Podman In Podman

```sh
podman build -t localhost/podman-insider:latest -f Containerfile .


# Rootful Podman in rootful Podman with --privileged
podman run --privileged quay.io/podman/stable podman run ubi8 echo hello

# Rootless Podman in rootful Podman with --privileged
podman run --user podman --privileged quay.io/podman/stable podman run ubi8 echo hello

# Running without the --privileged flag
podman run --cap-add=sys_admin,mknod --device=/dev/fuse --security-opt label=disable quay.io/podman/stable podman run ubi8-minimal echo hello

# Rootless Podman in rootful Podman without --privileged
podman run --user podman --security-opt label=disable --security-opt unmask=ALL --device /dev/fuse -ti quay.io/podman/stable podman run -ti docker.io/busybox echo hello

# Podman-remote in rootful Podman with a leaked Podman socket from the host
podman run -v /run:/run --security-opt label=disable quay.io/podman/stable podman --remote run busybox echo hi
```
