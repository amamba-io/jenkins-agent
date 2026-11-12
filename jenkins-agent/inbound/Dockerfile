ARG INBOUND_AGENT_IMAGE=jenkins/inbound-agent:jdk21
FROM ${INBOUND_AGENT_IMAGE}

USER root

# #3452: retain the upstream image behavior while updating its Debian Perl packages.
RUN set -eu; \
    cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.upstream; \
    sed -i 's|http://deb.debian.org/debian|https://mirrors.tuna.tsinghua.edu.cn/debian|g' /etc/apt/sources.list.d/debian.sources; \
    apt-get update; \
    apt-get install -y --no-install-recommends --only-upgrade \
      libperl5.40 perl perl-base perl-modules-5.40; \
    for package in libperl5.40 perl perl-base perl-modules-5.40; do \
      version=$(dpkg-query -W -f='${Version}' "$package"); \
      dpkg --compare-versions "$version" ge '5.40.1-6+deb13u1'; \
    done; \
    rm -rf /var/lib/apt/lists/*

USER jenkins
