#!/usr/bin/env bash
set -eux

if which ggrep; then
    # so we can run this locally on MacOS
    # (run `brew install grep` to install this)
    GREP=ggrep
else
    GREP=grep
fi

PDAL_VER="$(${GREP} -Po '(?<=project\(PDAL VERSION )\d+\.\d+\.\d+' CMakeLists.txt)"

DIST=$1
DEB_BASE_VERSION="${PDAL_VER}"
DEB_VERSION="${DEB_BASE_VERSION}+kx-ci${BUILDKITE_BUILD_NUMBER-0}-$(git show -s --date=format:%Y%m%d --format=git%cd.%h)"
echo "Debian Package Version: ${DEB_VERSION}"

if [ -n "${BUILDKITE_AGENT_ACCESS_TOKEN-}" ]; then
    buildkite-agent meta-data set deb-base-version "$DEB_BASE_VERSION"
    buildkite-agent meta-data set deb-version "$DEB_VERSION"
    echo -e ":debian: Package Version: \`${DEB_VERSION}\`" |
        buildkite-agent annotate --style info --context deb-version
fi

BUILDS_DIR=$(realpath "./build-${DIST}")
mkdir -p "${BUILDS_DIR}"

SRC_DIR=$(realpath "$(dirname -- "${BASH_SOURCE[0]}")/..")

echo "Building for $DIST/$(uname -m) ..."
docker pull "${ECR}/kx-base-${DIST}-py3-build"
docker run --rm -it \
    -v "${SRC_DIR}:/src" \
    -v "${BUILDS_DIR}:/builds" \
    --tmpfs /tmp:exec \
    ${BUILD_DOCKER_OPTS-} \
    --mount type=volume,target=/mnt/build \
    -w /src \
    "${ECR}/kx-base-${DIST}-py3-build" \
    ${2-/src/.buildkite/_compile.sh "${DEB_VERSION}"}

echo "✅ debs are in ${BUILDS_DIR} ---"
