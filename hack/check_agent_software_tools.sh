#!/usr/bin/env bash

set -x

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

function check_go_command() {
  if ! command -v go &> /dev/null; then
    highlight_message "red" "go is not executable"
    count=$((count+1))
  else
    highlight_message "green" "go is executable"
  fi

  go_version=$(go version)
  MATRIX=$(echo "${SOFTWARE_MATRIX}" | sed 's/go-//')
  if [[ $go_version == *"${MATRIX}"* ]]; then
    highlight_message "green" "go version is right"
  else
    highlight_message "red" "go version is error"
    count=$((count+1))
  fi

  # go project
  if [ -f "/tmp/go-agent/main.go" ]; then
    cd tmp/go-agent && go mod init go-agent && go build || true
    res=$(./go-agent)
    if [ "${res}" == "Hello World" ]; then
      highlight_message "green" "go project run success"
    else
      highlight_message "red" "go project run failed"
      count=$((count+1))
    fi
  else
    highlight_message "red" "go project is not found in path /tmp/go-agent/"
    count=$((count+1))
  fi
}

function check_maven_command() {
  if ! command -v mvn &> /dev/null; then
    highlight_message "red" "mvn is not executable"
    count=$((count+1))
  else
    highlight_message "green" "mvn is executable"
  fi

  # validate mvn configuration
  if mvn -h 2>&1 | grep -q "JAVA_HOME"; then
    highlight_message "red" "mvn configuration is error, JAVA_HOME is not set"
    count=$((count+1))
  fi

  # maven project
  if [ -f "/tmp/maven-agent/pom.xml" ]; then
    cd /tmp/maven-agent/ && mvn package || true
    res=$(java -jar target/maven-agent-1.0-SNAPSHOT.jar)
    if [ "${res}" == "Hello World" ]; then
      highlight_message "green" "maven project run success"
    else
      highlight_message "red" "maven project run failed"
      count=$((count+1))
    fi
  else
    highlight_message "red" "maven project is not found in path /tmp/maven-agent/"
    count=$((count+1))
  fi
}

function check_nodejs_command() {
  if ! command -v node &> /dev/null; then
    highlight_message "red" "node is not executable"
    count=$((count+1))
  else
    highlight_message "green" "node is executable"
  fi

  node_version=$(node --version)
  MATRIX=$(echo "${SOFTWARE_MATRIX}" | sed 's/nodejs-//')
  if [[ "${node_version}" == *"${MATRIX}"* ]]; then
    highlight_message "green" "node version is right"
  else
    highlight_message "red" "node version is error"
    count=$((count+1))
  fi

  # nodejs project
  if [ -f "/tmp/nodejs-agent/index.js" ]; then
    cd /tmp/nodejs-agent && npm init -y || true
    if [ -f "package.json" ]; then
      res=$(node index.js)
      if [ "${res}" == "Hello World" ]; then
        highlight_message "green" "nodejs project run success"
      else
        highlight_message "red" "nodejs project run failed"
        count=$((count+1))
      fi
    else
      highlight_message "red" "npm run failed"
      count=$((count+1))
    fi
  else
    highlight_message "red" "nodejs project is not found in path /tmp/nodejs-agent/"
    count=$((count+1))
  fi
}

function check_python_command() {
  if ! command -v python &> /dev/null; then
    highlight_message "red" "python is not executable"
    count=$((count+1))
  else
    highlight_message "green" "python is executable"
  fi

  if ! command -v pip &> /dev/null; then
    highlight_message "red" "pip is not executable"
    count=$((count+1))
  else
    highlight_message "green" "pip is executable"
  fi

  python_version=$(python --version 2>&1)
  MATRIX=$(echo "${SOFTWARE_MATRIX}" | sed 's/python-//')
  if [[ "${python_version}" == *"${MATRIX}"* ]]; then
    highlight_message "green" "python version is right"
  else
    highlight_message "red" "python version is error"
    count=$((count+1))
  fi

  # python project
  if [ -f "/tmp/python-agent/test.py" ]; then
    pip install -r /tmp/python-agent/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple || true
    res=$(python /tmp/python-agent/test.py)
    if [ "${res}" == "Hello World" ]; then
      highlight_message "green" "python project run success"
    else
      highlight_message "red" "python project run failed"
      count=$((count+1))
    fi
  else
    highlight_message "red" "python project is not found in path /tmp/python-agent/"
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