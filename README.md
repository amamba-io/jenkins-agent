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

The `Build Images` workflow retains the complete architecture/version/runtime
matrix, deployment and Relok8s validation after merging to `main`, on release tags,
and through **Actions → Build Images → Run workflow**.
Configure branch protection to require **PR Checks**, replacing old build job checks.
