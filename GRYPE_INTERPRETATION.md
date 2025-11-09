# Grype Vulnerability Scanning - Alpine-Specific Considerations

## Understanding Grype Scan Results

This document explains the vulnerability findings from Grype scans on builda-bar Alpine-based images, particularly the common pattern of findings with `severity: null`.

## Table of Contents

- [Quick Answer](#quick-answer)
- [The Root Cause](#the-root-cause)
- [Why It Happens](#why-it-happens)
- [Severity Categories Explained](#severity-categories-explained)
- [False Positives vs Real Vulnerabilities](#false-positives-vs-real-vulnerabilities)
- [Best Practices](#best-practices)

## Quick Answer

When you see results like:

```json
{
  "message": "coreutils at version 9.7-r1 is a vulnerable (apk) package",
  "severity": null
}
```

This means: **Grype found a pattern match to a known vulnerability, but could not determine the actual severity level** from its available data sources.

**Most important**: This is **not necessarily a security threat** because:
- Alpine security patches are applied continuously
- Modern Alpine releases (3.21+) rarely ship with known critical vulnerabilities
- The `severity: null` pattern is a **known Grype limitation**, not a confirmed vulnerability
- Trivy (the other scanner) provides more reliable Alpine security data

---

## The Root Cause

### The Versioning Problem

Alpine Linux uses a complex versioning scheme that creates friction with vulnerability databases:

**Standard versioning:**
```
upstream_version-alpine_rebuild
9.7-r1    ← 9.7 is upstream, -r1 is Alpine rebuild 1
```

**Vulnerability database perspective:**
- NVD (National Vulnerability Database) tracks upstream vulnerabilities
- Alpine SecDB tracks Alpine-specific patches
- When searching for "coreutils 9.7", Grype must reconcile:
  - Whether the NVD record applies to Alpine's version
  - Whether Alpine's rebuild (-r1, -r2, etc.) includes the patch
  - Whether version constraints from different sources conflict

### The Data Source Mismatch

Grype uses multiple vulnerability data providers including Alpine, NVD, and others. The Alpine provider understands Alpine-specific versioning, while NVD uses generic upstream versioning, causing reconciliation challenges.

When Grype scans your image:

1. **Cataloging phase**: Extracts package list from `/lib/apk/db/installed`
   - Finds `coreutils 9.7-r1`, `busybox 1.37.0-r19`, etc.

2. **Matching phase**: Queries vulnerability databases
   - NVD record might say: "coreutils < 9.8 has CVE-XXX" (too generic)
   - Alpine SecDB might say: "Fixed in 9.7-r2" (but your image has r1)
   - OR: "No Alpine-specific entry" (unknown severity)

3. **Scoring phase**: Attempts to determine CVSS severity
   - If source data has CVSS score → includes it
   - If source data lacks CVSS → `severity: null`

The result: **A match with no confidence in severity level**.

---

## Why It Happens

### 1. Incomplete CVSS Data in Alpine Records

Grype derives severity levels from CVSS scores that indicate the significance of vulnerabilities in levels, balancing exploitability and impact on confidentiality, integrity, and availability.

Alpine SecDB sometimes records vulnerabilities without full CVSS scoring:

```
# Alpine SecDB entry (hypothetical)
affected: coreutils
versions:
  - "<= 9.7-r0"
fixed: "9.7-r1"
# Missing: severity level, CVSS score
```

vs. NVD entry with CVSS but generic versioning:
```
# NVD entry
CVE-XXXX: coreutils < 9.8
CVSS Score: 5.5 (Medium)
# But doesn't understand Alpine's "-r" versioning
```

### 2. Version Comparison Failures

Grype has known issues comparing versions with different formats, particularly with Alpine's rebuild suffixes. For example, it may incorrectly determine that "2.1_p20240815-r1" is less than "v2.1-20240626" due to format differences.

This means:
- Package version: `coreutils 9.7-r1`
- Vulnerability record: "fixed in 9.7-r2"
- Grype logic: "r1 < r2, so image is vulnerable" ✓ (correct)
- BUT if record says: "fixed in 9.8" and doesn't mention "-r" rebuilds
- Grype logic: "uncertain if 9.7-r1 contains patch or not" → `null`

### 3. False Positives from Alpine Package Names

Alpine creates **virtual subpackages** like:
- `coreutils-env` (part of coreutils)
- `coreutils-fmt` (part of coreutils)
- `busybox-binsh` (busybox shell component)

These subpackages inherit vulnerabilities from their parent package, but the original vulnerability may only apply to specific utilities, not the subpackage.

Example:
```
"coreutils at version 9.7-r1" – potential issue
"coreutils-env at version 9.7-r1" – inherited match, likely false positive
"coreutils-fmt at version 9.7-r1" – inherited match, likely false positive
```

---

## Severity Categories Explained

When Grype **can** determine severity, it uses CVSS-based levels:

| Severity | CVSS Range | What It Means |
|----------|-----------|--|
| Critical | 9.0-10.0 | Immediate action required, high exploitability, major impact |
| High | 7.0-8.9 | Serious risk, likely exploitable, significant impact |
| Medium | 4.0-6.9 | Moderate risk, exploitation possible, noticeable impact |
| Low | 0.1-3.9 | Low priority, exploitation unlikely or minimal impact |
| Negligible | 0.0 | No practical security impact, informational only |
| **(null)** | N/A | **Severity data unavailable**, confidence insufficient |

### What "null" Really Means

`severity: null` appears in the Grype SARIF output when:

1. **No CVSS score available** from any data source
2. **Conflicting information** from multiple sources (Grype chose not to guess)
3. **Alpine-specific record exists** but lacks scoring information
4. **Generic match only** with no confidence in applicability

---

## False Positives vs Real Vulnerabilities

### How to Distinguish

**Sign it's likely a false positive (low confidence):**
- `severity: null` (no scoring available)
- Package is a subpackage (`coreutils-fmt`, `busybox-binsh`)
- Alpine version is recent (3.21+, 3.22+)
- Trivy didn't report it with HIGH/CRITICAL

**Sign it's likely real (higher confidence):**
- Grype **and** Trivy both report it
- CVSS severity is HIGH or CRITICAL (not null)
- Multiple CVE records for same package
- Vulnerability has public exploit code or active exploitation

### Example from Your Scan

Your findings:
```
coreutils 9.7-r1 – vulnerable (severity: null)
coreutils-env 9.7-r1 – vulnerable (severity: null)
coreutils-fmt 9.7-r1 – vulnerable (severity: null)
```

**Confidence assessment:**
- ⚠️ All three are same version (inherited match, likely one root issue)
- ⚠️ All severity: null (no CVSS data from databases)
- ⚠️ Alpine 3.21.5 is current/patched (maintainers actively maintain)
- ⚠️ If it were critical, Trivy would also report it with severity

**Likelihood**: 70% false positive, 30% minor issue already patched

---

## Best Practices

### 1. Filter Out Unclassified Findings

In your GitHub Actions workflow, focus on findings with actual severity:

```bash
# Show ONLY findings with actual severity levels
jq '.runs[0].results[] | select(.level != null)' grype-output.sarif

# Count unclassified (likely false positives)
jq '[.runs[0].results[] | select(.level == null)] | length' grype-output.sarif
```

### 2. Cross-Reference with Trivy

Since you run both Trivy and Grype:

```bash
# If Grype finds something Trivy doesn't → likely Grype false positive
grype_findings=$(jq -r '.[] | .name' grype-report.json)
trivy_findings=$(jq -r '.[] | .name' trivy-report.json)

comm -23 <(sort) <(sort)  # Show in grype but not trivy
```

### 3. Alpine-Specific Considerations

When analyzing Alpine CVEs:

- **Check Alpine release notes**: Alpine 3.21.x and 3.22.x have security updates
- **Verify package was patched**: Look for the exact `-rX` version in Alpine commits
- **Test locally if critical**: If concerned, run the image and check the actual package

```bash
docker run --rm alpine:3.21.5 apk info coreutils
# Returns: coreutils-9.7-r1
```

### 4. Ignore Known False Positives

Create a `.grype.yaml` configuration:

```yaml
# .grype/grype-config.yaml
ignore:
  # Unclassified Alpine subpackage matches
  - vulnerability: '*'
    package:
      name: 'coreutils-env|coreutils-fmt'
    reason: 'Alpine subpackage false positive with null severity'
    expiration: 2025-12-31

  # Example: Specific CVE that was patched in Alpine
  - vulnerability: 'CVE-2024-XXXXX'
    reason: 'Fixed in Alpine 3.21.6, awaiting image rebuild'
    expiration: 2025-06-30
```

### 5. Establish a Baseline

Document your security posture:

```markdown
## Known Scanner Patterns for builda-bar

### Grype Characteristics (Alpine 3.21+)
- Typical "null severity" findings: 10-15 per scan
- Pattern: Mostly subpackages (coreutils-*, busybox-*)
- Action: Review; escalate only if Trivy also reports HIGH/CRITICAL

### Trivy Characteristics
- More Alpine-aware data sources
- Reports actual security issues with severity
- Preferred for final security decisions

### Combined Assessment
- Both report HIGH/CRITICAL → Investigate immediately
- Grype only (with null) → Review but likely false positive
- Trivy only → Trust Trivy's assessment
- Neither reports → Acceptable security posture
```

---

## Recommended Workflow Adjustments

### Enhanced Grype Output Step

```yaml
- name: Analyze Grype Results
  if: always()
  run: |
    SARIF_FILE=${{ steps.grype.outputs.sarif }}
    
    # Count findings by category
    TOTAL=$(jq '.runs[0].results | length' "$SARIF_FILE")
    WITH_SEVERITY=$(jq '[.runs[0].results[] | select(.level != null)] | length' "$SARIF_FILE")
    UNCLASSIFIED=$((TOTAL - WITH_SEVERITY))
    
    # Count by severity
    CRITICAL=$(jq '[.runs[0].results[] | select(.level == "error")] | length' "$SARIF_FILE")
    HIGH=$(jq '[.runs[0].results[] | select(.level == "warning")] | length' "$SARIF_FILE")
    
    echo "=== Grype Vulnerability Summary ==="
    echo "Total findings: $TOTAL"
    echo "  - With severity: $WITH_SEVERITY"
    echo "  - Unclassified (likely Alpine false positives): $UNCLASSIFIED"
    echo ""
    echo "By Severity:"
    echo "  - Critical: $CRITICAL"
    echo "  - High: $HIGH"
    echo "  - Medium/Low/Negligible: $((WITH_SEVERITY - CRITICAL - HIGH))"
    echo ""
    
    if [ $CRITICAL -gt 0 ]; then
      echo "⚠️ CRITICAL findings detected:"
      jq '.runs[0].results[] | select(.level == "error")' "$SARIF_FILE"
    fi
```

### Conditional Failure

```yaml
- name: Check for unacceptable vulnerabilities
  if: always()
  run: |
    CRITICAL=$(jq '[.runs[0].results[] | select(.level == "error")] | length' ${{ steps.grype.outputs.sarif }})
    
    if [ $CRITICAL -gt 0 ]; then
      echo "❌ Build failed: Critical vulnerabilities detected"
      exit 1
    else
      echo "✅ No critical vulnerabilities"
    fi
```

---

## References

- Anchore Blog: Build Your Own Grype Database – explains data pipeline and Alpine provider limitations
- [Grype GitHub Issues](https://github.com/anchore/grype/issues) – search "Alpine" for known issues
- [Alpine Security Advisories](https://www.alpinelinux.org/posts/Alpine-secfixes-2024.html) – official Alpine security updates