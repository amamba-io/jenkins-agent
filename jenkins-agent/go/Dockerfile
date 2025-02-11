ARG RUNTIME
ARG REGISTRY_REPO=amamba-io
ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
ARG ARCH_SUFFIX
FROM $REGISTRY_REPO/jenkins-agent-base:latest$DISTRIBUTION_SUFFIX$RUNTIME$ARCH_SUFFIX

ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
ARG VERSION
ENV PATH=$PATH:/usr/local/go/bin
ENV PATH=$PATH:/usr/local/
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/jenkins/go
ENV PATH=$PATH:$GOPATH/bin

COPY jenkins-agent/base/ ./

RUN ansible-playbook ./ansible/playbooks/main.yaml -vvv -e go_version=$VERSION -e distribution=$DISTRIBUTION
RUN mkdir -p $GOPATH/bin && mkdir -p $GOPATH/src && mkdir -p $GOPATH/pkg
CMD ["go","version"]