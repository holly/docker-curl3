# docker-curl3

HTTP/3-enabled curl in a Docker container. Supports HTTP/3 protocol via OpenSSL (QUIC) + ngtcp2.

## Requirements

- Docker

## Quick Start

```bash
git clone <REPO_URL>
cd curl3
./build.sh              # Build image (first time: 20-30 minutes)
./run.sh --version      # Check version
./run.sh https://example.com  # Usage example
```

## Usage

### Check version and features

```bash
./run.sh --version
./run.sh -V
```

### Connect with HTTP/3

```bash
./run.sh --http3 https://www.google.com
```

### Verbose output

```bash
./run.sh -v https://example.com      # Verbose
./run.sh -vv https://example.com     # Very verbose
```

### Via symlink

```bash
./curl https://example.com          # Equivalent to ./run.sh
```

### Direct Docker execution

```bash
docker run --rm -it holly/curl3:latest --version
docker run --rm -it holly/curl3:latest https://example.com
```

## Build Contents

| Component | Version | Purpose |
|-----------|---------|---------|
| curl | 8.20.1-DEV | HTTP client |
| OpenSSL | 4.1.0 | TLS + QUIC |
| ngtcp2 | 1.23.0-DEV | QUIC implementation |
| nghttp2 | 1.59.0 | HTTP/2 |
| nghttp3 | 0.8 | HTTP/3 |
| libssh2 | 1.11.0 | SSH/SFTP |
| brotli | 1.1.0 | Compression |
| zlib | 1.3 | Compression |

### Supported Protocols

```
file ftp ftps http https ipfs ipns scp sftp ws wss
```

### Supported Features

```
alt-svc AsynchDNS brotli HSTS HTTP2 HTTP3 HTTPS-proxy IPv6 
Largefile libz PSL SSL threadsafe TLS-SRP UnixSockets
```

## Build Times

| Scenario | Time |
|----------|------|
| First build | 20-30 minutes |
| With cache (no dependency changes) | 1-5 minutes |
| With dependency changes | 5-15 minutes |

## For Developers

For build customization, debugging, and configuration changes, see `CLAUDE.md`.

## License

MIT
