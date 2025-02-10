ARG RUNTIME
ARG REGISTRY_REPO=amambadev
ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
ARG IMAGE_PROXY=docker.m.daocloud.io
FROM $IMAGE_PROXY/$REGISTRY_REPO/jenkins-agent-base:latest$DISTRIBUTION_SUFFIX$RUNTIME

ARG DISTRIBUTION
ARG DISTRIBUTION_SUFFIX
ARG JAVA_VERSION
ARG TARGETARCH

COPY jenkins-agent/base/ ./

# install java and maven
RUN ansible-playbook ./ansible/playbooks/main.yaml -vvv -e java_version=$JAVA_VERSION -e distribution=$DISTRIBUTION

# maven
ENV MAVEN_VERSION=3.9.9
ENV M2_HOME=/opt/apache-maven-$MAVEN_VERSION
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-${TARGETARCH}
ENV maven.home=$M2_HOME
ENV M2=$M2_HOME/bin
ENV PATH=$M2:$PATH:$JAVA_HOME/bin

# Set JDK to be 32bit
COPY jenkins-agent/maven/set_java $M2
RUN chmod +x $M2/set_java && $M2/set_java && rm $M2/set_java && echo "JAVA_HOME=$JAVA_HOME"

CMD ["mvn","-version"]