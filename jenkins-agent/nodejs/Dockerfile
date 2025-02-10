ARG RUNTIME
ARG REGISTRY_REPO=amambadev
ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
ARG IMAGE_PROXY=docker.m.daocloud.io
FROM $IMAGE_PROXY/$REGISTRY_REPO/jenkins-agent-base:latest$DISTRIBUTION_SUFFIX$RUNTIME

ARG DISTRIBUTION
ARG VERSION

COPY jenkins-agent/base/ ./

RUN ansible-playbook ./ansible/playbooks/main.yaml -vvv -e node_version=$VERSION -e distribution=$DISTRIBUTION
CMD ["node","--version"]