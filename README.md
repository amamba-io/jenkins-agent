# jenkins-agent

including mirrors of various languages

while we update jenkins version，we should change github workflows first

## update agent version

when you want update jenkins agent versions, just do the following steps:
1. vim version.yaml, add some new version for some language
2. run `make update-agents-version` to auto update the following files:
   - helm chart values.yaml
   - github action yaml
   - .relok8s-images.yaml
   - some .rego files to verify images
## Pull request checks

PRs run version-generation consistency, Helm lint, policy and CasC checks.
Image changes additionally build affected Ubuntu/Docker images on AMD64 using
one representative version (the first entry in `version.yaml`) and run tool checks.
Images are loaded locally and never pushed. Documentation and chart-only changes
skip image builds. New commits cancel previous checks for the same PR.

The `Build Images` workflow retains the supported Ubuntu architecture/version/runtime
matrix, deployment and Relok8s validation after merging to `main`, on release tags,
and through **Actions → Build Images → Run workflow**.
Configure branch protection to require **PR Checks**, replacing old build job checks.

## CentOS agents: manual builds only

CentOS-based agents are no longer maintained. PR checks, main-branch builds,
release-tag builds, and release image bundles only build/include Ubuntu agents.
CentOS Dockerfiles and provisioning tasks remain available for temporary upgrade needs. Existing published images are retained,
but CentOS images receive no routine version or security updates.

For an exceptional rebuild, use **Actions → Build CentOS Agents (Manual Only) →
Run workflow** (`build_deprecated_agent_image.yaml`). Choose the workflow branch
and provide `container_tag`, for example `v0.7.1-legacy`. The same entry is available
through the GitHub CLI:

```bash
gh workflow run build_deprecated_agent_image.yaml --ref main \
  -f container_tag=v0.7.1-legacy
```

This manually publishes Base, Node.js 16.20.2, Python 3.8.19, Go 1.17.13, and
Maven/JDK 8 and 11 images for Docker and Podman on AMD64 and ARM64, plus their
multi-architecture manifests. Base images are built and checked first; language
images then use those freshly built bases. The selected tag and the existing
CentOS `latest` aliases are updated. Ubuntu tags have the `-ubuntu` suffix and
are built by the regular workflow. Manual CentOS runs are serialized because
language Dockerfiles consume the base `latest` aliases.

CentOS tags preserve their historical naming without an OS suffix, for example
`ghcr.io/amamba-io/jenkins-agent-base:v0.7.1-legacy-podman` and
`ghcr.io/amamba-io/jenkins-agent-maven:v0.7.1-legacy-jdk1.8-podman`.
When upgrading an installation that still selects CentOS agents, explicitly use
an existing compatible image tag or manually rebuild the required release tag.
CentOS images are excluded from new Relok8s bundles and must be staged separately
for offline upgrades. Prefer Ubuntu agents for maintained installations.
