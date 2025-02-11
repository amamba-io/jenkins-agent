#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source hack/util.sh

# specific a jenkins and agent version
VERSION=${1:-"v0.2.1"}
KUBE_CONF=${2:-}
TARGET_NS=${3:-"jenkins"}

LOCAL_RELEASE_NAME=jenkins

echo "Rendering values.yaml with VERSION=${VERSION}"
envsubst < config/e2e.yaml > /tmp/e2e.yaml

values="-f /tmp/e2e.yaml"

if [[ -n ${KUBE_CONF} ]]; then 
    export KUBECONFIG="${KUBE_CONF}"
fi

set -x

echo "debug: Jenkins chart template: "
helm template $LOCAL_RELEASE_NAME charts/jenkins-full --debug -n "${TARGET_NS}" ${values}

echo "debug: Jenkins using Images: "
helm template $LOCAL_RELEASE_NAME charts/jenkins-full --debug -n "${TARGET_NS}" ${values} | grep "image:"

echo "Deploying Jenkins: "
helm upgrade --install --wait --debug --create-namespace --cleanup-on-fail \
      ${LOCAL_RELEASE_NAME}  charts/jenkins-full \
      -n "${TARGET_NS}" \
      ${values}

set +x

# check it
helm list -n "${TARGET_NS}"

util::wait_pod_ready "${LOCAL_RELEASE_NAME}" "${TARGET_NS}" 600s