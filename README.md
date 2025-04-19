# Asterisk on Rocky Linux

This repository provides Docker images for running Asterisk on Rocky Linux. The images are available on Docker Hub under the repository `pablogod/asterisk-rockylinux` with tags corresponding to the Asterisk version and base version.

## Available Tags

- `pablogod/asterisk-rockylinux:20-<base_version>`
- `pablogod/asterisk-rockylinux:21-<base_version>`
- `pablogod/asterisk-rockylinux:22-<base_version>`

Replace `<base_version>` with one of the supported Rocky Linux base versions.

## Supported Rocky Linux Base Versions

The following Rocky Linux base versions are supported:

- `9.3-minimal`, `9-minimal`
- `8.9-minimal`, `8-minimal`

## Usage

### Pull the Image

To pull a specific version of the Asterisk image with a specific base version, use the following command:

```bash
docker pull pablogod/asterisk-rockylinux:<version>-<base_version>
```

Replace `<version>` with `20`, `21`, or `22` and `<base_version>` with one of the supported base versions.

### Build the Image Locally

To build the image locally for all supported base versions, use:

```bash
make build
```

To build for a specific base version, modify the `BASE_VERSIONS` variable in the `Makefile`.

### Run the Container

To run the container, use:

```bash
docker run -it \
  --network host \
  --restart always \
  pablogod/asterisk-rockylinux:<version>-<base_version>
```

### Automated Builds with GitHub Actions

This repository includes a GitHub Actions workflow to automate the build and push process for Docker images. The workflow builds images for all combinations of Asterisk versions (`20`, `21`, `22`) and Rocky Linux base versions (`9.3-minimal`, `9-minimal`, `8.9-minimal`, `8-minimal`).
