#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

set -x

if ! command -v yq &> /dev/null; then
  wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64.tar.gz -O - | tar xz &&  yq --version
  yq --version
fi

chart_path="charts/jenkins-full"
version_file="version.yaml"
relok8s_file=$chart_path"/.relok8s-images.yaml"

function update_chart_value() {
  chart_values_path=$chart_path"/values.yaml"
  languages=$(yq eval '.Agent | keys' "$version_file" | sed 's/^- //g')
  for lang in $languages; do
    versions=$(yq eval ".Agent.${lang}[]" "$version_file")
    if [[ -n "$versions" ]]; then
      if ! yq eval ".Agent.Builder.${lang}" "$chart_values_path" >/dev/null 2>&1; then
        yq eval -i ".Agent.Builder.${lang} = { Versions: [] }" "$chart_values_path"
      fi
      existing_versions=$(yq eval ".Agent.Builder.${lang}.Versions[]" "$chart_values_path" | sed 's/^"//;s/"$//')
      first=true
      while IFS= read -r version; do
        if [[ -z "$version" || "$first" == true ]]; then
          first=false
          continue
        fi
        formatted_version="latest-$version"
        if ! echo "$existing_versions" | grep -q "^${formatted_version}$"; then
          yq eval -i ".Agent.Builder.${lang}.Versions += [\"${formatted_version}\"]" "$chart_values_path"
        fi
      done <<< "$versions"
    fi
  done
  echo "chart values updated successfully."
}

function update_github_ci() {
  build_amd_ci_file=".github/workflows/build_agent_image_amd.yaml"
  build_arm_ci_file=".github/workflows/build_agent_image_arm.yaml"
  build_ci_file=".github/workflows/build_main.yaml"

  languages=$(yq eval '.Agent | keys' "$version_file" | sed 's/^- //g')
  for lang in $languages; do
    versions=$(yq eval ".Agent.${lang}[]" "$version_file")
    if [[ -n "$versions" ]]; then
      clean_versions=$(echo "$versions" | sed 's/^jdk//')
      versions_array=$(echo "$clean_versions" | awk '{print "\"" $0 "\""}' | paste -sd, -)
      action_name="build-agent-$(echo "$lang" | tr '[:upper:]' '[:lower:]')"
      yq eval -i ".jobs.${action_name}.strategy.matrix.version = [${versions_array}]" "$build_amd_ci_file"
      yq eval -i ".jobs.${action_name}.strategy.matrix.version = [${versions_array}]" "$build_arm_ci_file"

      build_action_name="push-jenkins-agent-$(echo "$lang" | tr '[:upper:]' '[:lower:]')-manifest"
      yq eval -i ".jobs.${build_action_name}.strategy.matrix.version = [${versions_array}]" "$build_ci_file"
    fi
  done
  echo "github ci updated successfully."
}

function update_rego() {
    base_path=$1
    rego_file=$base_path"/deny.rego"
    suffix=$2
    output="agents_output.tmp"
    agents=$(yq eval '.Agent' "$version_file")

    {
      echo "package main"
      echo "agents := {"
      echo '  "base": {"container": "base", "image": "ghcr.io/amamba-io/jenkins-agent-base:latest'"${suffix}"'"},'

      for lang in $(echo "$agents" | yq eval 'keys' - | sed 's/- //g'); do
        lang_lower=$(echo "$lang" | tr '[:upper:]' '[:lower:]')
        versions=$(yq eval ".Agent.${lang}[]" "$version_file")

        if [ "$lang_lower" == "golang" ]; then
          lang_lower="go"
        fi

        first_version=true
        for version in $versions; do
          if [[ "$first_version" == true ]]; then
            if [[ "${lang_lower}" == "maven" ]] || [[ "${lang_lower}" == "go" ]]; then
              echo '  "'"${lang_lower}"'": {"container": "'"${lang_lower}"'", "image": "ghcr.io/amamba-io/jenkins-agent-'"${lang_lower}"':latest-'"${version}"'-ubuntu'"${suffix}"'"},'
              first_version=false
            else
              echo '  "'"${lang_lower}"'": {"container": "'"${lang_lower}"'", "image": "ghcr.io/amamba-io/jenkins-agent-'"${lang_lower}"':latest-'"${version}""${suffix}"'"},'
              first_version=false
            fi
          else
            echo '  "'"${lang_lower}"'-'"${version}"'": {"container": "'"${lang_lower}"'", "image": "ghcr.io/amamba-io/jenkins-agent-'"${lang_lower}"':latest-'"${version}"'-ubuntu'"${suffix}"'"},'
          fi
        done
      done | sed '$ s/,$//'

      echo "}"
    } > $base_path"/agents.rego"
    rm -f $output
    echo "rego file $base_path/deny.rego updated successfully."
}

function process_builder() {
    local builder_name=$1
    local image="{{ .Agent.Builder.$builder_name.Image }}"
    local versions=($(yq eval ".Agent.Builder.$builder_name.Versions[]" "$chart_values_path"))
    local runtime=("docker" "podman")
    local os=("centos" "ubuntu")
    for os_type in "${os[@]}"; do
        for rt in "${runtime[@]}"; do
            for version in "${versions[@]}"; do
              relok8sPlaceholder="{{ .Agent.relok8sPlaceholder }}"
                suffix=""
                if [ "$os_type" == "ubuntu" ]; then
                    suffix=$suffix"-ubuntu"
                fi
                if [ "$rt" == "podman" ]; then
                    suffix=$suffix"-podman"
                fi
                entry="- \"{{ .image.registry }}/$image:$relok8sPlaceholder$version$suffix\""
                if [ "$os_type" == "centos" ]; then
                  if [ "$builder_name" == "Golang" ] && [[ "$version" =~ "1.17.13" ]]; then
                     if ! grep -F "$image:$relok8sPlaceholder$version$suffix" "$relok8s_file"; then
                        echo "$entry" >> "$relok8s_file"
                     fi
                  fi
                else
                    if ! grep -F "$image:$relok8sPlaceholder$version$suffix" "$relok8s_file"; then
                        echo "$entry" >> "$relok8s_file"
                    fi
                fi
            done
        done
    done
}

function update_relok8s_images() {
  process_builder "NodeJs"
  process_builder "Maven"
  process_builder "Golang"
  process_builder "Python"
  echo "relok8s images updated successfully."
}

update_chart_value
update_github_ci
update_relok8s_images
update_rego "test/default-registry" "-podman"
update_rego "test/runtime" ""
