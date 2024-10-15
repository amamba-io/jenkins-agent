#!/usr/bin/env bash

set -e
set -x

executable_tools=(make gcc wget git curl autoconf zip unzip jq vim gettext tree yq argocd kubectl-argo-rollouts kustomize sonar-scanner helm docker kubectl)
rpm_packages=(gcc-c++ openssl-devel glibc-common)
dep_packages=(g++ libcurl4-openssl-dev libssl-dev locales)
count=0

# highlight_message echo different color's message
# - $1: color code, eg. 1, 2, 3, 4 -> red, green, yellow, blue
# - $2: want to highlight the output message
function highlight_message() {
  local color_name=${1}
  local message=${2}

  case "${color_name}" in
    red)
      color_code=1
      ;;
    green)
      color_code=2
      ;;
    yellow)
      color_code=3
      ;;
    blue)
      color_code=4
      ;;
    *)
      color_code=0
      ;;
  esac

  echo -e "\033[3${color_code}m$(date '+%Y-%m-%d %H:%M:%S')  ${message}\033[0m"
}

# check the command is executable
function check_command() {
  if ! command -v "${1}" &> /dev/null; then
    highlight_message "red" "${1} is not executable"
    count=$((count+1))
  else
    highlight_message "green" "${1} is executable"
  fi
}

# centos: check the package is installed in rpm
function check_rpm() {
  if ! rpm -q "${1}" &> /dev/null; then
    highlight_message "red" "${1} is not installed in rpm"
    count=$((count+1))
  else
    highlight_message "green" "${1} is installed in rpm"
  fi
}

# ubuntu: check the package is installed in dep
function check_dep() {
  if ! dpkg -l | grep "$1" &> /dev/null; then
    highlight_message "red" "${1} package is not installed in dep"
    count=$((count+1))
  else
    highlight_message "green" "${1} is installed in dep"
  fi
}

function check_base_tools() {
  # git
  if ! git clone https://github.com/amamba-io/jenkins-agent.git; then
    highlight_message "red" "git clone failed"
    count=$((count+1))
  else
    highlight_message "green" "git clone success"
  fi

  # vim
  if ! vim -c "normal! GoThis is test txt" -c "wq" test.txt; then
    highlight_message "red" "vim edit file failed"
    count=$((count+1))
  else
    if ! grep -q "This is test txt" test.txt; then
      highlight_message "yellow" "vim edit file has unknown exception, no match found in the file"
      content=$(cat test.txt)
      highlight_message "blue" "file content: ${content}"
    else
      highlight_message "green" "vim edit file success"
    fi
  fi

  # curl
  http_code=$(curl -s -o /dev/null -w "%{http_code}" www.baidu.com)
  if [ -z "${http_code}" ]; then
    highlight_message "red" "curl baidu failed"
    count=$((count+1))
  elif [ "${http_code}" == 200 ]; then
    highlight_message "green" "curl baidu success"
  else
    highlight_message "yellow" "curl baidu has unknown exception, response code is not 200"
    highlight_message "blue" "the response code is ${http_code}"
  fi

  # wget
  if ! wget https://github.com/amamba-io/jenkins-agent/archive/refs/tags/v0.4.4.zip; then
    highlight_message "red" "wget jenkins-agent failed"
    count=$((count+1))
  else
    highlight_message "green" "wget jenkins-agent success"
    rm -f v0.4.4.zip
  fi

  # unzip && zip
  curl -sOL https://github.com/amamba-io/jenkins-agent/archive/refs/tags/v0.4.4.zip
  if ! unzip v0.4.4.zip; then
    highlight_message "red" "unzip jenkins-agent failed"
    count=$((count+1))
  else
    highlight_message "green" "unzip jenkins-agent success"
    if ! zip v0.4.4.0.zip jenkins-agent-0.4.4; then
      highlight_message "red" "zip jenkins-agent failed"
      count=$((count+1))
    else
      highlight_message "green" "zip jenkins-agent success"
    fi
  fi

  # yq
  if [ -f "/tmp/base-agent/test.yaml" ]; then
    name=$(yq '.metadata.name' /tmp/base-agent/test.yaml)
    if [ -z "${name}" ]; then
      highlight_message "red" "yq get value failed"
      count=$((count+1))
    elif [ "${name}" == "test" ]; then
      highlight_message "green" "yq get value success"
    else
      highlight_message "yellow" "yq get value has unknown exception, yq exec success but not get value"
    fi
  else
    highlight_message "red" "test.yaml is not found in path /tmp/base-agent/"
    count=$((count+1))
  fi

  # jq
  if [ -f "/tmp/base-agent/test.json" ]; then
    name=$(jq '.name' /tmp/base-agent/test.json)
    if [ -z "${name}" ]; then
      highlight_message "red" "jq get value failed"
      count=$((count+1))
    elif [ "${name}" == "\"jenkins-agent\"" ]; then
      highlight_message "green" "jq get value success"
    else
      highlight_message "yellow" "jq get value has unknown exception, jq exec success but not get value"
    fi
  else
    highlight_message "red" "test.json is not found in path /tmp/base-agent/"
    count=$((count+1))
  fi

  # helm && helm cm-push
  if ! helm repo add jenkins-agent http://amamba-io.github.io/charts; then
    highlight_message "red" "helm repo add failed"
    count=$((count+1))
  else
    highlight_message "green" "helm repo add success"
  fi

  if ! helm pull jenkins-agent/jenkins --version 0.4.4; then
    highlight_message "red" "helm pull chart failed"
    count=$((count+1))
    if ! helm search repo jenkins-agent | grep 0.4.4; then
      highlight_message "yellow" "jenkins 0.4.4 is not found in jenkins-agent repo"
      charts=$(helm search repo jenkins-agent)
      highlight_message "blue" "jenkins-agent repo charts list: \n${charts}"
    fi
  else
    highlight_message "green" "helm pull chart success"
  fi

  if ! helm cm-push --help; then
    highlight_message "red" "helm cm-push get help failed"
    count=$((count+1))
    if ! helm plugin list | grep cm-push; then
      highlight_message "yellow" "cm-push is not found in helm plugin list"
      plugins=$(helm plugin list)
      highlight_message "blue" "helm plugins list: \n${plugins}"
    fi
  else
    highlight_message "green" "helm cm-push get help success"
  fi

  # kubectl
  if ! kubectl config view; then
    highlight_message "red" "kubectl config view failed"
    count=$((count+1))
  else
    highlight_message "green" "kubectl config view success"
  fi

  # docker or podman
  if [[ "${AGENT_IMAGE}" == *"podman"* ]]; then
    key="podman"
  else
    key="docker"
  fi

  if ! $key pull busybox; then
    highlight_message "red" "${key} pull image failed"
    count=$((count+1))
  else
    if ! $key images | grep -q busybox; then
      highlight_message "yellow" "${key} pull image has unknown exception, not found busybox image in images list"
    else
      highlight_message "green" "${key} pull image success"
    fi
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

  check_base_tools

  if [ ${count} -ne 0 ]; then
    exit 1
  fi
}

main "$@"