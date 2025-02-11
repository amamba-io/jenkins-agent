ARG REGISTRY_REPO=amamba-io
ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
ARG ARCH_SUFFIX
FROM $REGISTRY_REPO/jenkins-agent-base:latest$DISTRIBUTION_SUFFIX$ARCH_SUFFIX

ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
COPY jenkins-agent/base/ ./
COPY ./jenkins-agent/base/storage.conf /etc/containers/storage.conf
COPY ./jenkins-agent/base/containers.conf /etc/containers/containers.conf
COPY ./jenkins-agent/base/registries.conf /etc/containers/registries.conf
VOLUME /var/lib/containers
ENV PODMAN_IGNORE_CGROUPSV1_WARNING=true

RUN ansible-playbook ./ansible/playbooks/main.yaml -vvv -e install_podman=true -e distribution=$DISTRIBUTION
CMD ["podman", "info"]