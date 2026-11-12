#!/usr/bin/env bash
set -euo pipefail

test "$(id -un)" = jenkins
test -x /usr/local/bin/jenkins-agent
for package in libperl5.40 perl perl-base perl-modules-5.40; do
  version=$(dpkg-query -W -f='${Version}' "$package")
  dpkg --compare-versions "$version" ge '5.40.1-6+deb13u1'
done
git --version
java -jar /usr/share/jenkins/agent.jar -version
