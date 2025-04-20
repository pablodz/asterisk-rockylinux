# Asterisk on Docker with Rocky Linux

![Build and Publish](https://github.com/pablodz/asterisk-rockylinux/actions/workflows/docker-publish.yml/badge.svg)

This repository provides Docker images for running Asterisk on Rocky Linux. The images are available on Docker Hub under the repository `pablogod/asterisk-rockylinux` with tags corresponding to the Asterisk version and base version.

## Available Tags

| Tag                                      | Asterisk Version | Base Version       |
|------------------------------------------|------------------|--------------------|
| `pablogod/asterisk-rockylinux:20-8-minimal` | 20               | 8-minimal          |
| `pablogod/asterisk-rockylinux:20-8.9-minimal` | 20               | 8.9-minimal        |
| `pablogod/asterisk-rockylinux:20-9-minimal` | 20               | 9-minimal          |
| `pablogod/asterisk-rockylinux:20-9.3-minimal` | 20               | 9.3-minimal        |
| `pablogod/asterisk-rockylinux:21-8-minimal` | 21               | 8-minimal          |
| `pablogod/asterisk-rockylinux:21-8.9-minimal` | 21               | 8.9-minimal        |
| `pablogod/asterisk-rockylinux:21-9-minimal` | 21               | 9-minimal          |
| `pablogod/asterisk-rockylinux:21-9.3-minimal` | 21               | 9.3-minimal        |
| `pablogod/asterisk-rockylinux:22-8-minimal` | 22               | 8-minimal          |
| `pablogod/asterisk-rockylinux:22-8.9-minimal` | 22               | 8.9-minimal        |
| `pablogod/asterisk-rockylinux:22-9-minimal` | 22               | 9-minimal          |
| `pablogod/asterisk-rockylinux:22-9.3-minimal` | 22               | 9.3-minimal        |
| `pablogod/asterisk-rockylinux:latest`   | latest (not-stable)           | 9-minimal          |

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
  -v /path/to/your/config:/etc/asterisk \
  pablogod/asterisk-rockylinux:<version>-<base_version>
```

Replace `/path/to/your/config` with the directory containing your Asterisk configuration files (`*.conf`).

**Note:** The `--network host` mode is required to run Asterisk as a node because NAT (Network Address Translation) can cause issues with SIP and RTP protocols. Due to this limitation, it is not possible to run more than one replica of the container in a Kubernetes pod.

### Automated Builds with GitHub Actions

This repository includes a GitHub Actions workflow to automate the build and push process for Docker images. The workflow builds images for all combinations of Asterisk versions (`20`, `21`, `22`) and Rocky Linux base versions (`9.3-minimal`, `9-minimal`, `8.9-minimal`, `8-minimal`).
