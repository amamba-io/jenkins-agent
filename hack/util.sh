#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# This function installs a Go tools by 'go get' command.
# Parameters:
#  - $1: package name, such as "sigs.k8s.io/controller-tools/cmd/controller-gen"
#  - $2: package version, such as "v0.4.1"
# Note:
#   Since 'go get' command will resolve and add dependencies to current module, that may update 'go.mod' and 'go.sum' file.
#   So we use a temporary directory to install the tools.
function util::install_tools() {
	local package="$1"
	local version="$2"

	temp_path=$(mktemp -d)
	pushd "${temp_path}" >/dev/null
	GO111MODULE=on go install "${package}"@"${version}"
	GOPATH=$(go env GOPATH | awk -F ':' '{print $1}')
	export PATH=$PATH:$GOPATH/bin
	popd >/dev/null
	rm -rf "${temp_path}"
}

function util::cmd_exist {
	local CMD=$(command -v ${1})
	if [[ ! -x ${CMD} ]]; then
    	return 1
	fi
	return 0
}

# util::cmd_must_exist check whether command is installed.
function util::cmd_must_exist {
    local CMD=$(command -v ${1})
    if [[ ! -x ${CMD} ]]; then
    	echo "Please install ${1} and verify they are in \$PATH."
    	exit 1
    fi
}


# util::wait_pod_ready waits for pod state becomes ready until timeout.
# Parameters:
#  - $1: pod label, such as "app=etcd"
#  - $2: pod namespace, such as "kpanda-system"
#  - $3: time out, such as "200s"
function util::wait_pod_ready() {
    local pod_label=$1
    local pod_namespace=$2
    local timeout=$3

    echo "wait the $pod_label ready..."
    set +e
    util::kubectl_with_retry wait --for=condition=Ready --timeout=${timeout} pods -l app=${pod_label} -n ${pod_namespace}
    ret=$?
    set -e
    if [ $ret -ne 0 ];then
      echo "kubectl describe info: $(kubectl describe pod -l app=${pod_label} -n ${pod_namespace})"
      echo "kubectl logs pod: $(kubectl logs -l app=${pod_label} -n ${pod_namespace})"
    fi
    return ${ret}
}

# util::kubectl_with_retry will retry if execute kubectl command failed
# tolerate kubectl command failure that may happen before the pod is created by StatefulSet/Deployment.
function util::kubectl_with_retry() {
    local ret=0
    local count=0
    for i in {1..10}; do
        kubectl "$@"
        ret=$?
        if [[ ${ret} -ne 0 ]]; then
            echo "kubectl $@ failed, retrying(${i} times)"
            sleep 30
            continue
        else
          ((count++))
          # sometimes pod status is from running to error to running
          # so we need check it more times
          if [[ ${count} -ge 3 ]];then
            return 0
          fi
          sleep 1
          continue
        fi
    done

    echo "kubectl $@ failed"
    kubectl "$@"
    return ${ret}
}


# util::create_cluster creates a kubernetes cluster
# util::create_cluster creates a kind cluster and don't wait for control plane node to be ready.
# Parameters:
#  - $1: cluster name, such as "host"
#  - $2: KUBECONFIG file, such as "/var/run/host.config"
#  - $3: node docker image to use for booting the cluster, such as "kindest/node:v1.19.1"
#  - $4: log file path, such as "/tmp/logs/"
function util::create_cluster() {
	local cluster_name=${1}
	local kubeconfig=${2}
	local kind_image=${3}
	local cluster_config=${4:-}

	rm -f "${kubeconfig}" || true
  kind delete cluster --name="${cluster_name}" || true
  kind create cluster --name "${cluster_name}" --kubeconfig="${kubeconfig}" --image="${kind_image}" --config="${cluster_config}"
  echo "cluster ${cluster_name} created successfully"
}

# util::delete_cluster deletes kind cluster by name
# Parameters:
# - $1: cluster name, such as "host"
function util::delete_cluster() {
  local cluster_name=${1}
  kind delete cluster --name="${cluster_name}"
}
