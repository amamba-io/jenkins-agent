#!/usr/bin/env bash

set -e

executable_tools=(make gcc wget git curl autoconf zip unzip jq vim gettext tree yq argocd kubectl-argo-rollouts kustomize sonar-scanner helm docker kubectl)
rpm_packages=(gcc-c++ openssl-devel glibc-common)
dep_packages=(g++ libcurl4-openssl-dev libssl-dev locales)
count=0

source hack/util.sh

# check the command is executable
function check_command() {
  if ! command -v "${1}" &> /dev/null; then
    util::message "red" "${1} is not executable"
    count=$((count+1))
  else
    util::message "green" "${1} is executable"
  fi
}

# centos: check the package is installed in rpm
function check_rpm() {
  if ! rpm -q "${1}" &> /dev/null; then
    util::message "red" "${1} is not installed in rpm"
    count=$((count+1))
  else
    util::message "green" "${1} is installed in rpm"
  fi
}

# ubuntu: check the package is installed in dep
function check_dep() {
  if ! dpkg -l | grep "$1" &> /dev/null; then
    util::message "red" "${1} package is not installed in dep"
    count=$((count+1))
  else
    util::message "green" "${1} is installed in dep"
  fi
}

function check_base_tools() {
  # git
  if ! git clone https://github.com/amamba-io/jenkins-agent.git; then
    util::message "red" "git: ❌"
    count=$((count+1))
  else
    util::message "green" "git: ✅"
  fi

  # vim
  if ! touch test.txt && vim -c "normal! GoThis is test txt" -c "wq" test.txt; then
    util::message "red" "vim: ❌"
    count=$((count+1))
  else
    if ! grep -q "This is test txt" test.txt; then
      util::message "yellow" "vim: ⚠️"
    else
      util::message "green" "vim: ✅"
    fi
  fi

  # curl
  http_code=$(curl -s -o /dev/null -w "%{http_code}" www.baidu.com)
  if [ -z "${http_code}" ]; then
    util::message "red" "curl: ❌"
  elif [ "${http_code}" == 200 ]; then
    util::message "green" "curl: ✅"
  else
    util::message "yellow" "curl: ⚠️"
  fi
}

main() {
  for tool in ${executable_tools[*]}; do
    check_command "${tool}"
  done

  if [[ "${AGENT_IMAGE}" == *"ubuntu"* ]]; then
    for package in ${dep_packages[*]}; do
      check_dep "${package}"
    done
  else
    for package in ${rpm_packages[*]}; do
      check_rpm "${package}"
    done
  fi

  if [ ${count} -ne 0 ]; then
    exit 1
  fi
}

main "$@"