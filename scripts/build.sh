#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() { echo "
Usage:   $0 -v <version> -p <push> -l <latest>
Example: $0 -v 0.1.0 -p true -l true
" 1>&2; exit 1; }

declare repository="ducas/simple-kube-sync"

declare version=""
declare push="false"
declare latest="false"

while getopts ":v:p:l:" arg; do
  case "${arg}" in
    v) version=${OPTARG} ;;
    p) push=${OPTARG} ;;
    l) latest=${OPTARG} ;;
  esac
done
shift $((OPTIND-1))

if [[ -z "$version" ]]; then
  echo "Version (e.g. 0.1.0):"
  read version
  [[ "${version:?}" ]]
fi
if [[ "$push" != "true" && "$push" != "false" ]]; then
  echo "Push (true|false):"
  read push
  [[ "${push:?}" ]]
fi
if [[ "$latest" != "true" && "$latest" != "false" ]]; then
  echo "Latest (true|false):"
  read latest
  [[ "${latest:?}" ]]
fi

echo "Building ${repository} with version: $version, push: $push, latest: $latest"

type docker >/dev/null 2>&1 || { echo >&2 "Prerequisite missing: docker"; exit 1; }

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
SRC_DIR="$SCRIPT_DIR/../src"

pushd $SRC_DIR

for docker_arch in amd64 arm32v7; do
  case ${docker_arch} in
    amd64   ) qemu_arch="amd64" ;;
    arm32v7 ) qemu_arch="arm" ;;
  esac
  
  cp Dockerfile.template Dockerfile.${docker_arch}
  sed -i "" "s|__BASEIMAGE_ARCH__|${docker_arch}|g" Dockerfile.${docker_arch}
  sed -i "" "s|__QEMU_ARCH__|${qemu_arch}|g" Dockerfile.${docker_arch}

  if [ ${docker_arch} == 'amd64' ]; then
    sed -i "" "/__CROSS_/d" Dockerfile.${docker_arch}
  else
    sed -i "" "s/__CROSS_//g" Dockerfile.${docker_arch}
  fi

  docker build -f Dockerfile.${docker_arch} -t "${repository}:${version}-${docker_arch}" .
  if [[ "$latest" == "true" ]]; then
    docker tag "${repository}:${version}-${docker_arch}" "${repository}:latest-${docker_arch}"
    echo "Successfully tagged ${repository}:latest-${docker_arch}"
  fi

  rm Dockerfile.${docker_arch}
done

if [[ "$push" == "true" ]]; then
  for docker_arch in amd64 arm32v7; do
    docker push "${repository}:${version}-${docker_arch}"
    if [[ "$latest" == "true" ]]; then
      docker push "${repository}:latest-${docker_arch}"
    fi
  done

  echo "Creating manifest..."
  docker manifest create --amend "${repository}:${version}" \
    "${repository}:${version}-amd64" \
    "${repository}:${version}-arm32v7"
  echo "Pushing manifest..."
  docker manifest push "${repository}:${version}"
  echo "Successfully pushed ${repository}:${version}"

  if [[ "$latest" == "true" ]]; then
    docker manifest create --amend "${repository}:latest" \
      "${repository}:latest-amd64" \
      "${repository}:latest-arm32v7"
    echo "Pushing manifest..."
    docker manifest push "${repository}:latest"
    echo "Successfully pushed ${repository}:latest"
  fi
fi

popd
