# Asterisk on Docker with Rocky Linux

![Build and Publish](https://github.com/pablodz/asterisk-rockylinux/actions/workflows/docker-publish.yml/badge.svg)

This repository provides Docker images for running Asterisk on Rocky Linux. The images are available on Docker Hub under the repository `pablogod/asterisk-rockylinux` with tags corresponding to the Asterisk version and base version.

**Note:** Only the `latest` version supports DTMF over the audiosocket protocol with Asterisk.

## Usage

### Pull the Image

| Tag                                      | Asterisk Version | Base Version       |
|------------------------------------------|------------------|--------------------|
| `pablogod/asterisk-rockylinux:20-9-minimal` | 20               | 9-minimal          |
| `pablogod/asterisk-rockylinux:20-9.3-minimal` | 20               | 9.3-minimal        |
| `pablogod/asterisk-rockylinux:21-9-minimal` | 21               | 9-minimal          |
| `pablogod/asterisk-rockylinux:21-9.3-minimal` | 21               | 9.3-minimal        |
| `pablogod/asterisk-rockylinux:22-9-minimal` | 22               | 9-minimal          |
| `pablogod/asterisk-rockylinux:22-9.3-minimal` | 22               | 9.3-minimal        |
| `pablogod/asterisk-rockylinux:latest`   | latest (not-stable)           | 9-minimal          |

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

### Run with Docker Compose

You can also use Docker Compose to manage the container. Below is an example `docker-compose.yml` file:

```yaml
version: '3.8'
services:
  asterisk:
    image: pablogod/asterisk-rockylinux:<version>-<base_version>
    network_mode: host
    restart: always
    volumes:
      - /path/to/your/config:/etc/asterisk
```

Replace `<version>-<base_version>` with the desired tag (e.g., `20-9-minimal`) and `/path/to/your/config` with the directory containing your Asterisk configuration files (`*.conf`).

To start the container using Docker Compose, run:

```bash
docker-compose up -d
```

To stop the container, run:

```bash
docker-compose down
```

### Automated Builds with GitHub Actions

This repository includes a GitHub Actions workflow to automate the build and push process for Docker images. The workflow builds images for all combinations of Asterisk versions (`20`, `21`, `22`) and Rocky Linux base versions (`9.3-minimal`, `9-minimal`).
