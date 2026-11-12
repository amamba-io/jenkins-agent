ARG REGISTRY_REPO=amamba-io
ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
ARG ARCH_SUFFIX
ARG NETWORK_HELPER_BUILDER=rust:1.80.1-alpine3.20

# CentOS 7 repositories do not provide netavark. Build static helpers so they
# do not depend on a newer glibc than the one in the agent image.
FROM ${NETWORK_HELPER_BUILDER} AS centos-network-helpers
ARG NETWORK_HELPER_VERSION=1.12.2
RUN apk add --no-cache build-base protobuf-dev
WORKDIR /build
RUN set -eu; \
    mkdir /out; \
    for helper in netavark aardvark-dns; do \
      wget -qO source.tar.gz "https://github.com/containers/${helper}/archive/refs/tags/v${NETWORK_HELPER_VERSION}.tar.gz"; \
      mkdir "${helper}"; \
      tar -xzf source.tar.gz -C "${helper}" --strip-components=1; \
      wget -qO vendor.tar.gz "https://github.com/containers/${helper}/releases/download/v${NETWORK_HELPER_VERSION}/${helper}-v${NETWORK_HELPER_VERSION}-vendor.tar.gz"; \
      tar -xzf vendor.tar.gz -C "${helper}"; \
      (cd "${helper}" && cargo build --release --frozen --bin "${helper}" \
        --config 'source.crates-io.replace-with="vendored-sources"' \
        --config 'source.vendored-sources.directory="vendor"'); \
      cp "${helper}/target/release/${helper}" /out/; \
    done

# Ubuntu installs its networking helpers through apt.
FROM scratch AS ubuntu-network-helpers
WORKDIR /out
FROM ${DISTRIBUTION}-network-helpers AS network-helpers

FROM $REGISTRY_REPO/jenkins-agent-base:latest$DISTRIBUTION_SUFFIX$ARCH_SUFFIX

ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
COPY jenkins-agent/base/ ./
COPY ./jenkins-agent/base/storage.conf /etc/containers/storage.conf
COPY ./jenkins-agent/base/containers.conf /etc/containers/containers.conf
COPY ./jenkins-agent/base/registries.conf /etc/containers/registries.conf
COPY --from=network-helpers /out/ /usr/local/libexec/podman/
VOLUME /var/lib/containers
ENV PODMAN_IGNORE_CGROUPSV1_WARNING=true

RUN ansible-playbook ./ansible/playbooks/main.yaml -vvv -e install_podman=true -e distribution=$DISTRIBUTION
CMD ["podman", "info"]
