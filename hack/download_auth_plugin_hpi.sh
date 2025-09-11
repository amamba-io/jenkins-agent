#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

VERBOSE=false
VERSION=""
TARGET_PATH="/tmp/daocloud-oic-auth.hpi"

wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -t|--target)
      TARGET_PATH="$2"
      shift 2
      ;;
    -V|--version)
      VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "${VERSION}" ]]; then
  if [[ ! -f "version.yaml" ]]; then
    echo "Error: version.yaml file not found"
    exit 1
  fi
  
  VERSION=$(yq e '.AuthPlugin' version.yaml)
  if [[ -z "${VERSION}" ]]; then
    echo "Error: failed to get auth plugin version from version.yaml"
    exit 1
  fi
fi

if [[ "${VERBOSE}" == "true" ]]; then
  echo "Using auth plugin version: ${VERSION}"
fi

downloadUrl="https://github.com/amamba-io/daocloud-oic-auth-plugin/releases/download/${VERSION}/daocloud-oic-auth.hpi"

if [[ "${VERBOSE}" == "true" ]]; then
  echo "Download URL: ${downloadUrl}"
  echo "Target path: ${TARGET_PATH}"
fi

echo "Downloading auth plugin HPI version: ${VERSION}"

if ! wget -O "${TARGET_PATH}" "${downloadUrl}"; then
  echo "Error: Failed to download from ${downloadUrl}"
  exit 1
fi

if [[ ! -f "${TARGET_PATH}" ]]; then
  echo "Error: Download failed - file not found at ${TARGET_PATH}"
  exit 1
fi

file_size=$(stat -c%s "${TARGET_PATH}" 2>/dev/null || stat -f%z "${TARGET_PATH}")
if [[ ${file_size} -eq 0 ]]; then
  echo "Error: Downloaded file is empty"
  exit 1
fi

echo "Successfully downloaded auth plugin HPI to ${TARGET_PATH}"
echo "File size: ${file_size} bytes"

if [[ "${VERBOSE}" == "true" ]]; then
  echo "File details:"
  ls -la "${TARGET_PATH}"
fi