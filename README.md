# Asterisk on Docker with Rocky Linux

![Build and Publish](https://github.com/pablodz/asterisk-rockylinux/actions/workflows/docker-publish.yml/badge.svg)

This repository provides Docker images for running Asterisk on Rocky Linux. The images are available on Docker Hub under the repository [`pablogod/asterisk-rockylinux`](https://hub.docker.com/r/pablogod/asterisk-rockylinux) with tags corresponding to the Asterisk version, base version, and optionally `-chansip` if SIP support via `chan_sip` is enabled.

> **Note:** Only the `master version supports DTMF over the AudioSocket protocol with Asterisk.

---

## 🐳 Available Tags

| Tag                                           | Asterisk Version | Base Version | `chan_sip` Enabled |
|-----------------------------------------------|------------------|--------------|---------------------|
| `master`                                      | master (unstable) | 9-minimal   | ❌ No               |
| `master-chansip`                              | master (unstable) | 9-minimal   | ✅ Yes              |
| `23-9-minimal`                                | 23               | 9-minimal   | ❌ No               |
| `23-9-minimal-chansip`                        | 23               | 9-minimal   | ✅ Yes              |
| `22-9-minimal`                                | 22               | 9-minimal   | ❌ No               |
| `22-9-minimal-chansip`                        | 22               | 9-minimal   | ✅ Yes              |
| `21-9-minimal`                                | 21               | 9-minimal   | ❌ No               |
| `21-9-minimal-chansip`                        | 21               | 9-minimal   | ✅ Yes              |

👉 See all available tags on [Docker Hub](https://hub.docker.com/r/pablogod/asterisk-rockylinux/tags)

---

## 🚀 Usage

### Pull the Image

```bash
# Without chan_sip
docker pull pablogod/asterisk-rockylinux:22-9-minimal

# With chan_sip enabled
docker pull pablogod/asterisk-rockylinux:22-9-minimal-chansip
```

---

### Build the Image Locally

To build all combinations locally:

```bash
make build
```

To build only one version with or without `chan_sip`:

```bash
# Without chan_sip (default)
docker build . \
  --build-arg ASTERISK_VERSION=22 \
  --build-arg BASE_VERSION=9-minimal \
  -t pablogod/asterisk-rockylinux:22-9-minimal

# With chan_sip enabled
docker build . \
  --build-arg ASTERISK_VERSION=22 \
  --build-arg BASE_VERSION=9-minimal \
  --build-arg ENABLE_CHAN_SIP=true \
  -t pablogod/asterisk-rockylinux:22-9-minimal-chansip
```

---

### Run the Container

```bash
# Without chan_sip
docker run -it --rm \
  --network host \
  -v /path/to/your/config:/etc/asterisk \
  pablogod/asterisk-rockylinux:22-9-minimal

# With chan_sip
docker run -it --rm \
  --network host \
  -v /path/to/your/config:/etc/asterisk \
  pablogod/asterisk-rockylinux:22-9-minimal-chansip
```

📌 Replace `/path/to/your/config` with your Asterisk config folder (`*.conf` files).

**Note:** `--network host` is required to avoid NAT issues with SIP/RTP. Running multiple containers in the same pod or VM with `host` networking is **not** supported.

---

### Using Docker Compose

Example `docker-compose.yml`:

```yaml
version: '3.8'
services:
  asterisk:
    image: pablogod/asterisk-rockylinux:22-9-minimal # or :22-9-minimal-chansip
    network_mode: host
    restart: always
    volumes:
      - /path/to/your/config:/etc/asterisk
```

To start:

```bash
docker-compose up -d
```

To stop:

```bash
docker-compose down
```

---

## 🛠️ Supported Build Args

| ARG Name         | Default     | Description                                  |
|------------------|-------------|----------------------------------------------|
| `ASTERISK_VERSION` | `22`        | Asterisk version to build (or `master`)      |
| `BASE_VERSION`     | `9-minimal` | Rocky Linux base version                     |
| `ENABLE_CHAN_SIP`  | `false`     | Set to `true` to include `chan_sip` module   |

---

## 📎 License

MIT
