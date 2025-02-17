#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

chart_name=$1
chart_dir=$2

#  check jenkins.yaml should be a valid yaml and shared library should be added to the casc
helm template "${chart_name}" "${chart_dir}" > "${chart_name}".yaml
yq eval-all 'select(.metadata.name == "jenkins-casc-config")' "${chart_name}".yaml > "${chart_name}"-casc-config.yaml
yq '.data."jenkins.yaml"' "${chart_name}"-casc-config.yaml > "${chart_name}"_jenkins.yaml
yq -i '.unclassified.globalLibraries = {"libraries": [{"defaultVersion": "main", "name": "amamba-shared-lib", "implicit": true, "retriever": {"modernSCM": {"scm": {"git": {"remote": "'"https://demo/amamba-shared-lib.git"'"}}}}}]}' "${chart_name}"_jenkins.yaml

# Check if the shared library is added to the casc
if ! yq eval '.unclassified.globalLibraries.libraries[0].name' "${chart_name}"_jenkins.yaml | grep -q "amamba-shared-lib"; then
  echo "Failed to add shared library to jenkins.yaml"
  exit 1
fi

rm "${chart_name}".yaml "${chart_name}"-casc-config.yaml "${chart_name}"_jenkins.yaml
