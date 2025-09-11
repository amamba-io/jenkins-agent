FROM --platform=linux/amd64 ubuntu:22.04 as build
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN apt-get update -y && apt-get --no-install-recommends install wget default-jre ca-certificates maven bzip2 -y
RUN wget -qP /tmp https://github.com/jenkins-zh/jenkins-cli/releases/latest/download/jcli-linux-amd64.tar.gz
RUN tar -xzf /tmp/jcli-linux-amd64.tar.gz -C /usr/local/bin
RUN wget -qP /tmp https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN tar -jxf /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /tmp
RUN mv /tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin
COPY formula.yaml /
COPY remove-bundle-plugins.groovy /
COPY hack/download_auth_plugin_hpi.sh hack/download_auth_plugin_hpi.sh
COPY version.yaml /
RUN chmod +x hack/download_auth_plugin_hpi.sh
WORKDIR /
RUN jcli cwp --install-artifacts --config-path formula.yaml --batch-mode --show-progress
# must after at `jcli cwp` avoid overwrite
RUN ./hack/download_auth_plugin_hpi.sh -v

FROM jenkins/jenkins:2.502
COPY --from=build /tmp/output/target/jenkins-1.0-SNAPSHOT.war /usr/share/jenkins/jenkins.war
COPY --from=build /tmp/daocloud-oic-auth.hpi /usr/share/jenkins/ref/plugins/daocloud-oic-auth.hpi
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENTRYPOINT ["tini", "--", "/usr/local/bin/jenkins.sh"]
