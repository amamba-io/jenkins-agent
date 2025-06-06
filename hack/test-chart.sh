#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

OUTPUT=${OUTPUT:-"stdout"}

set -x

function validate() {
    local test_path="$1"
    local chart_path="$2"
    local value_file="$3"
    helm template jenkins "${chart_path}" --debug -n jenkins -f "${value_file}" > "tmp.yaml"
    conftest test -o ${OUTPUT} --policy "${test_path}" "tmp.yaml"
    rm tmp.yaml
}

function main() {
    local full_jenkins="./charts/jenkins-full"
    local base_jenkins="./charts/jenkins"

    local test_cases="test/rego/*"

    for test_path in ${test_cases}; do
        # if subpath has full or base, use the corresponding chart
        if [[ -d "${test_path}/full" ]]; then
            validate "${test_path}/full" "${full_jenkins}" "${test_path}/values.yaml" 
        fi
        if [[ -d "${test_path}/base" ]]; then
            validate "${test_path}/base" "${base_jenkins}" "${test_path}/values.yaml" 
        fi
        if [[ -d "${test_path}/common" ]]; then
            validate "${test_path}/common" "${full_jenkins}" "${test_path}/values.yaml" 
            validate "${test_path}/common" "${base_jenkins}" "${test_path}/values.yaml" 
        fi
    done
}

main "$@"