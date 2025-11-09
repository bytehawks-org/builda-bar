# Image Signing and Verification

This document provides comprehensive guidance on verifying the cryptographic signatures applied to builda-bar container images using Cosign.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Signature Verification](#signature-verification)
- [Advanced Verification Scenarios](#advanced-verification-scenarios)
- [Kubernetes Integration](#kubernetes-integration)
- [Troubleshooting](#troubleshooting)

## Overview

All released builda-bar images are signed using **Cosign**, the container signing and verification tool from the Sigstore project. Cosign provides:

### Benefits of Image Signing

- **Authenticity**: Cryptographically prove images originate from ByteHawks official builds
- **Integrity**: Detect any unauthorized modifications to signed images
- **Non-Repudiation**: Establish chain of custody for container supply chain
- **Transparency**: Leverage OIDC tokens for keyless signing via GitHub Actions
- **Compliance**: Meet supply chain security requirements (SLSA, NIS2)

### Signing Approach

builda-bar uses **keyless signing** via Sigstore's OIDC provider:

- Images are signed during GitHub Actions workflow execution
- No static keys stored in repository secrets
- OIDC token proves GitHub identity and workflow context
- Certificate includes:
  - GitHub repository identity
  - Git commit SHA
  - Workflow run ID
  - Timestamp

## Installation

### Install Cosign

Choose your preferred method:

#### macOS with Homebrew

```bash
brew install cosign
```

#### Linux from Release

```bash
wget https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
cosign version
```

#### Linux via Package Manager

```bash
# Alpine
apk add cosign

# Ubuntu/Debian
sudo apt-get install cosign

# Fedora
sudo dnf install cosign
```

#### Docker Image

```bash
docker run ghcr.io/sigstore/cosign:v2.2.0 version
```

#### Verify Installation

```bash
cosign version
# Output: 
# 2.2.0
# gitlab.com/sigstore/cosign/cmd/cosign
```

## Signature Verification

### Basic Verification

Verify a single image tag signature:

#### GHCR Image

```bash
cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
  ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
```

Expected output shows certificate details:
```
Verification successful!
Certificate subject: https://github.com/bytehawks/bytehawks/.github/workflows/docker-build-x86_64.yml@refs/tags/v1.0.0-20250101
Certificate issuer URL: https://token.actions.githubusercontent.com
```

#### Harbor Image

```bash
cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
  registry.bytehawks.org/cicd-images/builda-bar:stable-x86_64
```

### Verification by Digest

Verify using immutable SHA256 digest for maximum reproducibility:

```bash
cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
  ghcr.io/bytehawks/bytehawks/builda-bar@sha256:bbdc920d45050a03710b3e4e814010602abc2ede0f111ce282481148a27de615
```

**Advantages of digest-based verification:**
- Digest is immutable and permanently refers to specific image version
- Prevents tag reassignment attacks
- Reproducible verification across time

### Retrieve Image Digest

To find the digest of a pulled image:

```bash
# Pull image and get digest
docker pull ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64

# Get digest of pulled image
docker inspect ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64 | jq -r '.[0].RepoDigests[]'

# Output:
# ghcr.io/bytehawks/bytehawks/builda-bar@sha256:abc123def456...
```

## Advanced Verification Scenarios

### Verify Multiple Variants at Once

```bash
for variant in old-legacy legacy stable stream; do
  echo "Verifying ${variant}..."
  cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
    ghcr.io/bytehawks/bytehawks/builda-bar:${variant}-x86_64
done
```

### Extract and Inspect Certificate

View the certificate embedded in the signature:

```bash
cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
  ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64 2>&1 | grep -A 20 "Certificate"
```

Or save certificate for inspection:

```bash
cosign verify --certificate-identity-regexp="https://github.com/bytehawks/bytehawks" \
  ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64 \
  --certificate-oidc-issuer-regexp="https://token.actions.githubusercontent.com" > cert.txt
```

### Verify with Full Certificate Chain

Include OIDC issuer verification:

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/bytehawks/bytehawks/.github/workflows/docker-build-x86_64.yml@refs/tags/*" \
  --certificate-oidc-issuer-regexp="https://token.actions.githubusercontent.com" \
  ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
```

### Verify for Specific Release

Verify only images from a specific release tag:

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/bytehawks/bytehawks/.github/workflows/docker-build-x86_64.yml@refs/tags/v1.0.0-20250101" \
  ghcr.io/bytehawks/bytehawks/builda-bar:v1.0.0-20250101-alpine-stable-x86_64
```

## Kubernetes Integration

### Enforce Signature Verification with Kyverno

Install Kyverno and apply image signature verification policy:

#### 1. Install Kyverno

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --values kyverno-values.yaml
```

#### 2. Create Cluster Policy

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-bytehawks-images
  namespace: kyverno
spec:
  validationFailureAction: enforce
  background: true
  webhookTimeoutSeconds: 30
  rules:
  - name: verify-cosign-signature
    match:
      resources:
        kinds:
        - Pod
        - Deployment
        - StatefulSet
        - DaemonSet
        - Job
        - CronJob
    verifyImages:
    - imageReferences:
      - "ghcr.io/bytehawks/bytehawks/builda-bar:*"
      - "registry.bytehawks.org/cicd-images/builda-bar:*"
      attestors:
      - count: 1
        entries:
        - keys:
            signatureAlgorithm: sha256
            # Public key from Cosign certificate (OIDC-based in this case)
            publicKeys: |
              -----BEGIN PUBLIC KEY-----
              [ByteHawks Cosign public key - obtained from certificate]
              -----END PUBLIC KEY-----
            signatureFormat: cosign
      messageOnVerificationFailure: "Image signature verification failed for {{ image }}"
```

#### 3. Test Policy Enforcement

Create a test Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-builda-bar
  namespace: default
spec:
  containers:
  - name: builder
    image: ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
    command: ["sleep", "3600"]
```

Apply and observe:

```bash
kubectl apply -f test-pod.yaml
# If signature is valid: Pod created successfully
# If signature is invalid: Pod creation blocked by Kyverno
```

### Enforce Signature Verification with OPA/Gatekeeper

Alternative policy enforcement using OPA:

```rego
package bytehawks_image_verification

deny[msg] {
  input.request.kind.kind in ["Pod", "Deployment", "StatefulSet"]
  container := input.request.object.spec.containers[_]
  image := container.image
  
  startswith(image, "ghcr.io/bytehawks/bytehawks/builda-bar") || 
  startswith(image, "registry.bytehawks.org/cicd-images/builda-bar")
  
  not image_is_signed(image)
  
  msg := sprintf("Image %v is not signed with valid Cosign signature", [image])
}

image_is_signed(image) {
  # Implement signature verification logic
  # This would typically call cosign verify in an external service
  true
}
```

## Troubleshooting

### Verification Fails: "No signatures found"

**Issue**: Cosign cannot find signatures for the image

**Solutions**:

1. Verify image exists and is accessible:
   ```bash
   docker pull ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
   ```

2. Check image has been recently released (newly pushed images may have signing delay):
   ```bash
   # Wait a few minutes and retry
   ```

3. Verify the registry has Cosign image annotations enabled:
   ```bash
   docker inspect ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64 | jq '.[] | .RepoTags'
   ```

### Verification Fails: "Certificate identity mismatch"

**Issue**: Certificate subject doesn't match the regex pattern

**Solutions**:

1. Verify the exact repository path:
   ```bash
   # Correct
   ghcr.io/bytehawks/bytehawks/builda-bar
   
   # Incorrect (missing "bytehawks")
   ghcr.io/bytehawks/builda-bar
   ```

2. Use more permissive regex if needed:
   ```bash
   cosign verify --certificate-identity-regexp="bytehawks" \
     ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
   ```

### Verification Fails: "Invalid OIDC token"

**Issue**: OIDC token validation failed

**Solutions**:

1. Verify system time is synchronized (OIDC tokens are time-sensitive):
   ```bash
   date
   ntpdate -u ntp.ubuntu.com  # Ubuntu
   ```

2. Ensure Cosign is updated:
   ```bash
   cosign version
   # Update if needed
   brew upgrade cosign  # macOS
   ```

### Cannot Connect to Registry

**Issue**: "Error: GET https://registry.bytehawks.org/.../manifests/sha256:..."

**Solutions**:

1. Verify network connectivity:
   ```bash
   curl -I https://registry.bytehawks.org
   ```

2. Authenticate to Harbor if required:
   ```bash
   docker login registry.bytehawks.org
   cosign verify ... registry.bytehawks.org/...
   ```

3. Check authentication credentials for GHCR:
   ```bash
   docker login ghcr.io
   ```

### Cosign Permission Denied

**Issue**: "Permission denied" when running cosign

**Solution**:

```bash
# Ensure cosign binary has execute permissions
chmod +x /usr/local/bin/cosign

# Or reinstall via package manager
sudo apt-get install --reinstall cosign
```

## Security Best Practices

### Recommended Verification Workflow

1. **Always verify digests** when consuming images in production:
   ```bash
   DIGEST=$(docker inspect ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64 | jq -r '.[0].RepoDigests[0]')
   cosign verify --certificate-identity-regexp="https://github.com/bytehawks" "$DIGEST"
   ```

2. **Automate verification** in CI/CD:
   ```yaml
   - name: Verify image signature
     run: |
       cosign verify --certificate-identity-regexp="https://github.com/bytehawks" \
         ghcr.io/bytehawks/bytehawks/builda-bar:${TAG}
   ```

3. **Enforce in Kubernetes** using admission controllers (Kyverno/OPA)

4. **Validate OIDC issuer** for maximum security:
   ```bash
   cosign verify \
     --certificate-oidc-issuer-regexp="https://token.actions.githubusercontent.com" \
     ghcr.io/bytehawks/bytehawks/builda-bar:stable-x86_64
   ```

## Additional Resources

- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview)
- [Sigstore Project](https://www.sigstore.dev/)
- [Kyverno Policy Examples](https://kyverno.io/policies/)
- [SLSA Framework](https://slsa.dev/)
- [NIS2 Compliance](https://digital-strategy.ec.europa.eu/en/policies/nis2-directive)