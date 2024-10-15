#!/usr/bin/env bash

set -x

count=0

function check_go_command() {
  if ! command -v go &> /dev/null; then
    util::message "red" "go is not executable"
    count=$((count+1))
  else
    util::message "green" "go is executable"
  fi

  go_version=$(go version)
  MATRIX=$(echo "${SOFTWARE_MATRIX}" | sed 's/go-//')
  if [[ $go_version == *"${MATRIX}"* ]]; then
    util::message "green" "go version is right"
  else
    util::message "red" "go version is error"
    count=$((count+1))
  fi
}

function check_maven_command() {
  if ! command -v mvn &> /dev/null; then
    util::message "red" "mvn is not executable"
    count=$((count+1))
  else
    util::message "green" "mvn is executable"
  fi

  # validate mvn configuration
  if mvn -h 2>&1 | grep -q "JAVA_HOME"; then
    util::message "red" "mvn configuration is error, JAVA_HOME is not set"
    count=$((count+1))
  fi
}

function check_nodejs_command() {
  if ! command -v node &> /dev/null; then
    util::message "red" "node is not executable"
    count=$((count+1))
  else
    util::message "green" "node is executable"
  fi

  node_version=$(node --version)
  MATRIX=$(echo "${SOFTWARE_MATRIX}" | sed 's/nodejs-//')
  if [[ "${node_version}" == *"${MATRIX}"* ]]; then
    util::message "green" "node version is right"
  else
    util::message "red" "node version is error"
    count=$((count+1))
  fi
}

function check_python_command() {
  if ! command -v python &> /dev/null; then
    util::message "red" "python is not executable"
    count=$((count+1))
  else
    util::message "green" "python is executable"
  fi

  if ! command -v pip &> /dev/null; then
    util::message "red" "pip is not executable"
    count=$((count+1))
  else
    util::message "green" "pip is executable"
  fi

  python_version=$(python --version 2>&1)
  MATRIX=$(echo "${SOFTWARE_MATRIX}" | sed 's/python-//')
  if [[ "${python_version}" == *"${MATRIX}"* ]]; then
    util::message "green" "python version is right"
  else
    util::message "red" "python version is error"
    count=$((count+1))
  fi
}

main() {
  if [[ "${SOFTWARE_MATRIX}" == *"go"* ]]; then
    check_go_command
  elif [[ "${SOFTWARE_MATRIX}" == *"java"* ]]; then
    check_maven_command
  elif [[ "${SOFTWARE_MATRIX}" == *"python"* ]]; then
    check_python_command
  elif [[ "${SOFTWARE_MATRIX}" == *"nodejs"* ]]; then
    check_nodejs_command
  fi

  if [ ${count} -ne 0 ]; then
    exit 1
  fi
}

main "$@"