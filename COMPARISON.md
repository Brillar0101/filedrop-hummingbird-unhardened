# Comparison: Hardened vs Unhardened Container Images on Hummingbird

Side-by-side security comparison of the two File Drop projects. Same app, same functionality, same Hummingbird OS — radically different container image security posture.

Both projects deploy on **Fedora Hummingbird Linux VMs**. The only difference is the container images running inside them: one uses Hummingbird's hardened `hi/*` images, the other uses standard Docker Hub images that have no hardened equivalent.

## The stacks

| Component | filedrop-hummingbird | filedrop-unhardened |
|-----------|---------------------|---------------------|
| **Host OS** | Fedora Hummingbird VM | Fedora Hummingbird VM |
| App runtime | Python 3.11 (FastAPI) | Node.js 22 (Express) |
| App image | `hi/python:3.11` (distroless) | `node:22` (full Debian) |
| Proxy | `hi/nginx:latest` | `httpd:latest` |
| Database | `hi/postgresql:17` | `mysql:8` |
| All images from | `registry.access.redhat.com/hi/` | `docker.io/library/` |

## Security comparison

| Property | Hummingbird | Unhardened |
|----------|-------------|------------|
| **Build approach** | Multi-stage, distroless final image | Single-stage, full OS |
| **Runtime user** | UID 65532 (non-root) | root |
| **Shell in image** | No | Yes (bash, sh) |
| **Package manager** | No (pip removed in build) | Yes (npm + apt) |
| **System tools** | None | curl, wget, gcc, make, etc. |
| **Root filesystem** | Read-only, immutable | Read-write |
| **Security headers** | X-Content-Type-Options, X-Frame-Options, Referrer-Policy | None |
| **Image size** | ~100-200 MB | ~1+ GB |
| **Expected CVEs** | **~20** | **200-400+** |

## How to run the comparison

### Scan the hummingbird app

```bash
cd ~/projects/filedrop-hummingbird
podman-compose up -d
grype localhost/filedrop-hummingbird_app:latest
```

### Scan the unhardened app

```bash
cd ~/projects/filedrop-unhardened
podman-compose up -d
grype localhost/filedrop-unhardened_app:latest
```

### Scan the base images directly

```bash
# Hummingbird (hardened)
grype registry.access.redhat.com/hi/python:3.11
grype registry.access.redhat.com/hi/nginx:latest
grype registry.access.redhat.com/hi/postgresql:17

# Standard (unhardened)
grype docker.io/library/node:22
grype docker.io/library/httpd:latest
grype docker.io/library/mysql:8
```

## What the numbers mean

The CVE count difference is not about the application code — the Express app and the FastAPI app have the same functionality and similar dependency counts. The difference comes from the **base images**.

### Why Hummingbird images have fewer CVEs

- **Distroless:** The final image contains only the language runtime and the application. No shell, no package manager, no system utilities. Fewer packages = fewer CVEs.
- **Curated:** Hummingbird images are built from a minimal, security-focused package set. Every included package is there for a reason.
- **Patched:** Security patches are applied promptly to the small set of included packages.

### Why standard images have more CVEs

- **Full OS:** Standard images are based on Debian or Ubuntu with hundreds of pre-installed packages. Most are unused by the application but each one can have vulnerabilities.
- **Broad scope:** Standard images are designed for general use. They include tools for debugging, building, and administration — great for development, bad for production security.
- **Slower patching:** With hundreds of packages to track, vulnerabilities accumulate between image updates.

## The demo pitch

> "Here are two Hummingbird VMs running the exact same app — upload a file, get a download link. Both run on the same hardened Hummingbird OS. The difference is the container images inside: one uses Hummingbird's hardened `hi/*` images with ~20 CVEs. The other uses standard Docker Hub images with 200-400+ CVEs. Same OS, same functionality — completely different container-level security."
>
> "Hummingbird locks down the OS, but your container images are your responsibility. If your stack has hardened `hi/*` images, use them. If it doesn't, this is the CVE exposure you carry inside each container."
