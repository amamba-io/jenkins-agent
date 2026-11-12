# Patched Helm push plugin

Ubuntu agent images build ChartMuseum's `helm-cm-push` v0.11.1 from this separate
Go tool module. The upstream release binary embeds gRPC v1.72.2; this module pins
gRPC v1.79.3 to fix CVE-2026-33186 (#3453–#3457). `go.sum` locks the dependency
graph without changing the repository's Docker/Podman wrapper module.

The Ubuntu Dockerfile builds a static binary for the target architecture and
checks its embedded gRPC version. The local manifest in
`jenkins-agent/base/helm-push/plugin.yaml` registers it with Helm 3 without an
install hook that could download the vulnerable upstream binary again. Derived
Ubuntu agent and Podman images inherit the plugin from their base image.

When updating the plugin, update this module's dependencies and sums, the local
plugin manifest, and the Dockerfile's gRPC build-info check together. Validate
both AMD64 and ARM64 binaries and exercise `helm cm-push` against a local
ChartMuseum-compatible endpoint. The legacy CentOS manual build retains its
existing unsupported upstream installation path.
