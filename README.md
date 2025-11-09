# builda-bar

[![Build Status](https://github.com/bytehawks/bytehawks/actions/workflows/docker-build-x86_64.yml/badge.svg)](https://github.com/bytehawks/bytehawks/actions/workflows/docker-build-x86_64.yml)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Alpine-based build container for ByteHawks – enabling transparent, auditable software supply chains for European digital sovereignty (x86_64/Arm64).

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Image Variants](#image-variants)
- [Pulling Images](#pulling-images)
- [Security Features](#security-features)
- [Verification & Signing](#verification--signing)
- [Contents & Tools](#contents--tools)
- [Build Information](#build-information)
- [Contributing](#contributing)

## Overview

**builda-bar** is a minimal Alpine Linux-based container designed for ByteHawks build orchestration and NIS2-compliant software supply chain management. It provides a transparent, auditable foundation for building statically compiled software with integrated security scanning and Software Bill of Materials (SBOM) generation.

### Key Characteristics

- **Minimal Attack Surface**: Based on Alpine Linux, reducing dependencies and vulnerabilities
- **Multi-Variant Support**: Available in `old-legacy`, `legacy`, `stable`, and `stream` Alpine versions
- **Security-First**: Automated vulnerability scanning with Trivy and Grype
- **Supply Chain Transparency**: CycloneDX SBOM generation for every build
- **Cryptographically Signed**: Cosign signatures for image verification and authenticity
- **Multi-Platform Ready**: x86_64 support with Arm64 coming soon
- **European Digital Sovereignty**: Aligned with NIS2 compliance requirements

## Quick Start

### Pull the Latest Stable Image

From GitHub Container Registry (GHCR):
```bash
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
```

From ByteHawks Harbor Registry:
```bash
docker pull registry.bytehawks.org/cicd-images/builda-bar:stable-x86_64
```

### Run the Container

```bash
docker run --rm -it ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
```

Or with mounted volumes for builds:
```bash
docker run --rm -v $(pwd)/src:/build/src:ro -v $(pwd)/dist:/build/dist ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
```

## Image Variants

### Alpine Versions

builda-bar is built across multiple Alpine Linux versions to support diverse use cases and stability requirements:

| Variant | Alpine Version | Use Case | Status |
|---------|----------------|----------|--------|
| `old-legacy` | 3.15.11 | Long-term stability, legacy systems | Supported |
| `legacy` | 3.20.8 | Extended LTS, conservative deployments | Supported |
| `stable` | 3.21.5 | Recommended default, balanced approach | **Recommended** |
| `stream` | 3.22.2 | Cutting-edge features, latest packages | Latest |

### Platform Support

| Platform | Status | Tag Suffix |
|----------|--------|-----------|
| x86_64 | ✅ Supported | `-x86_64` |
| Arm64 | 🚧 Coming Soon | `-arm64` |

## Pulling Images

### From GitHub Container Registry (GHCR)

GHCR is the primary public registry for builda-bar images.

#### Latest Stable (Recommended)
```bash
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
```

#### By Alpine Variant
```bash
# Legacy LTS
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:legacy-x86_64

# Old Legacy (long-term support)
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:old-legacy-x86_64

# Stream (latest features)
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:stream-x86_64
```

#### By Full Version and Alpine Release
```bash
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:alpine-3.21.5-stable-x86_64
```

#### By Release Version
```bash
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:v1.0.0-20250101-alpine-stable-x86_64
```

#### By Digest (Immutable Reference)
```bash
docker pull ghcr.io/bytehawks/bytehawks/builda-bar@sha256:abc123def456...
```

### From ByteHawks Harbor Registry

Harbor registry provides additional isolation and enterprise-grade features for European deployments.

#### Latest Stable
```bash
docker pull registry.bytehawks.org/cicd-images/builda-bar:stable-x86_64
```

#### By Alpine Variant
```bash
docker pull registry.bytehawks.org/cicd-images/builda-bar:legacy-x86_64
docker pull registry.bytehawks.org/cicd-images/builda-bar:old-legacy-x86_64
docker pull registry.bytehawks.org/cicd-images/builda-bar:stream-x86_64
```

#### By Full Version
```bash
docker pull registry.bytehawks.org/cicd-images/builda-bar:alpine-3.21.5-stable-x86_64
docker pull registry.bytehawks.org/cicd-images/builda-bar:v1.0.0-20250101-alpine-stable-x86_64
```

#### By Digest (Immutable Reference)
```bash
docker pull registry.bytehawks.org/cicd-images/builda-bar@sha256:abc123def456...
```

### Authentication

#### GHCR (GitHub Container Registry)
```bash
# Public access (no authentication required)
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64

# With authentication (optional, for higher rate limits)
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

#### Harbor Registry
```bash
docker login registry.bytehawks.org
# Provide your Harbor credentials when prompted
```

## Security Features

### Automated Vulnerability Scanning

Every build is scanned with industry-leading security tools:

#### Trivy Scanning
[Trivy](https://github.com/aquasecurity/trivy) performs comprehensive vulnerability assessment scanning for known CVEs across all packages in the container image. Results are uploaded to GitHub Security tab as SARIF reports.

**What Trivy checks:**
- OS package vulnerabilities
- Application dependencies
- Configuration issues
- Known malware signatures

#### Grype Scanning
[Grype](https://github.com/anchore/grype) provides dependency vulnerability detection with support for multiple package ecosystems.

**What Grype checks:**
- Application-level dependencies
- Cross-package vulnerability correlations
- Provides alternative CVE database sources

### SBOM (Software Bill of Materials)

A CycloneDX-formatted SBOM is generated for every build, providing complete transparency of container contents:

```
sbom-stable-x86_64.json
sbom-legacy-x86_64.json
sbom-old-legacy-x86_64.json
sbom-stream-x86_64.json
```

SBOMs are available as build artifacts and include:
- All Alpine packages and versions
- Package checksums and origins
- Dependency relationships
- License information

### Scan Result Retrieval

#### From GitHub Actions

1. Navigate to the [ByteHawks repository Actions tab](https://github.com/bytehawks/bytehawks/actions)
2. Select the latest "Build builda-bar Container Images" workflow run
3. Scroll to "Artifacts" section
4. Download desired SBOM or scan reports:
   - `sbom-{variant}-{arch}.json` – CycloneDX Software Bill of Materials
   - `scan-{variant}-{arch}` – Trivy vulnerability reports

#### Accessing Security Findings

1. Go to repository **Security** tab → **Code scanning alerts**
2. Results are organized by:
   - Tool (Trivy or Grype)
   - Variant and architecture
   - Severity (CRITICAL, HIGH)

#### Local SBOM Inspection

```bash
# Extract SBOM from workflow artifacts
unzip sbom-stable-x86_64.json

# View with a standard JSON tool
cat sbom-stable-x86_64.json | jq .

# Parse for specific packages
cat sbom-stable-x86_64.json | jq '.components[] | select(.name | contains("openssl"))'
```

## Verification & Signing

### Cosign Image Signing

All released images are signed with Cosign using ByteHawks project keys, ensuring:
- **Image Authenticity**: Verify images haven't been tampered with
- **Provenance Tracking**: Confirm images originate from official builds
- **Supply Chain Security**: Enforce signed images in Kubernetes policies

### Verifying Image Signatures

#### Prerequisites

Install Cosign:
```bash
# macOS
brew install cosign

# Linux
wget https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Docker
docker run ghcr.io/sigstore/cosign:latest version
```

#### Verify GHCR Image

```bash
# Verify signature
cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
  ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64

# Verify and inspect attestation
cosign verify-attestation ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
```

#### Verify Harbor Image

```bash
cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
  registry.bytehawks.org/cicd-images/builda-bar:stable-x86_64
```

#### Verify by Digest

```bash
cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
  ghcr.io/bytehawks/bytehawks/builda-bar@sha256:bbdc920d45050a03710b3e4e814010602abc2ede0f111ce282481148a27de615
```

### Kubernetes Admission Control

Enforce signature verification in Kubernetes using Kyverno or OPA:

#### Kyverno Policy Example
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-bytehawks-images
spec:
  validationFailureAction: enforce
  rules:
  - name: verify-cosign-signature
    match:
      resources:
        kinds:
        - Pod
    verifyImages:
    - imageReferences:
      - "ghcr.io/bytehawks/bytehawks/*"
      - "registry.bytehawks.org/cicd-images/*"
      attestors:
      - count: 1
        entries:
        - keys:
            signatureAlgorithm: sha256
            publicKeys: |
              -----BEGIN PUBLIC KEY-----
              [ByteHawks public key here]
              -----END PUBLIC KEY-----
            signatureFormat: cosign
```

## Contents & Tools

builda-bar includes a curated selection of tools for build orchestration and system configuration:

### System Tools
- `bash` – Advanced shell scripting
- `coreutils` – Core POSIX utilities
- `findutils` – File searching and processing
- `grep` – Text pattern matching
- `sed` – Stream editing and transformation

### Build & Compilation
- `gcc` – GNU C Compiler (native code compilation)
- `make` – Build automation
- `cmake` – Cross-platform build configuration
- `linux-headers` – Kernel header files for system-level compilation
- `musl-dev` – musl C library development headers

### Scripting & Automation
- `python3` – Python 3 runtime
- `py3-pip` – Python package manager
- `ansible` – Infrastructure automation and configuration management
- `perl` – Text processing and scripting
- `git` – Version control system
- `git-perl` – Perl modules for Git operations

### Network & Transfer
- `curl` – URL data transfer (HTTP/HTTPS/FTP)
- `wget` – HTTP/FTP file download utility

### System Configuration
- `ca-certificates` – Root CA certificates for HTTPS verification

### Environment Variables

Container-set variables for build context:

```bash
ALPINE_VERSION=3.21.5          # Alpine release version
VARIANT_NAME=stable             # Variant name (stable, legacy, etc.)
BUILD_CONTAINER=builda-bar      # Container identifier
PYTHONUNBUFFERED=1              # Real-time Python output
```

## Build Information

### Image Metadata

Each image includes comprehensive OpenContainer Initiative (OCI) metadata:

```bash
# Inspect metadata
docker inspect ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64 | jq '.[0].Config.Labels'
```

### Available Labels

- `org.opencontainers.image.title` – "builda-bar"
- `org.opencontainers.image.description` – Full description with variant and version
- `org.opencontainers.image.source` – GitHub repository URL
- `org.opencontainers.image.documentation` – Wiki URL
- `org.opencontainers.image.vendor` – "ByteHawks"
- `org.opencontainers.image.licenses` – "Apache-2.0"
- `org.opencontainers.image.created` – Build timestamp
- `org.opencontainers.image.revision` – Git commit SHA
- `org.opencontainers.image.version` – Release version
- `alpine.variant` – Alpine variant name
- `alpine.version` – Alpine version number

### Release Tagging Convention

Releases follow semantic versioning with date-based identifiers:

```
v{MAJOR}.{MINOR}.{PATCH}-{YYYYMMDD}

Example: v1.0.0-20250101
```

Each release generates images with tags:

```
{variant}-{arch}
alpine-{alpine-version}-{variant}-{arch}
{release-version}-alpine-{variant}-{arch}
```

## Contributing

### Local Building

Build locally for testing:

```bash
# x86_64
docker build --build-arg ALPINE_VERSION=3.21.5 \
  --build-arg VARIANT_NAME=stable \
  -t builda-bar:local-stable-x86_64 \
  -f Dockerfile .

# Run container
docker run --rm -it builda-bar:local-stable-x86_64
```

### Manual Workflow Trigger

Trigger builds manually with custom tags:

1. Go to **Actions** → **Build builda-bar Container Images**
2. Click **Run workflow** → **Run workflow**
3. Enter optional `tag_override` (e.g., `v1.2.3-20250115`)
4. Workflow creates images with specified version

### Reporting Issues

Found a vulnerability or issue? Please report through:

- **Security issues**: Use GitHub Security Advisory feature
- **General issues**: [GitHub Issues](https://github.com/bytehawks/bytehawks/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bytehawks/bytehawks/discussions)

## License

builda-bar is licensed under the **Apache License 2.0**. See [LICENSE](./LICENSE) file for details.

---

**ByteHawks** – European Digital Sovereignty Through Transparent Software Supply Chains
