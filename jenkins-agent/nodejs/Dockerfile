ARG RUNTIME
ARG REGISTRY_REPO=amamba-io
ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
ARG ARCH_SUFFIX
FROM $REGISTRY_REPO/jenkins-agent-base:latest$DISTRIBUTION_SUFFIX$RUNTIME$ARCH_SUFFIX

ARG DISTRIBUTION
ARG VERSION

COPY jenkins-agent/base/ ./

RUN ansible-playbook ./ansible/playbooks/main.yaml -vvv -e node_version=$VERSION -e distribution=$DISTRIBUTION
CMD ["node","--version"]