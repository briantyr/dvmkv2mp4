#!/usr/bin/env bash
#
# Build the Docker Image using docker CLI, with verbose logging
#
# - Automatically setup & utilize absolute paths for portability.
# - Set default variables that can be modified (I recommend leaving $DIR alone)
# - When building a Dockerfile to an image, this script will automatically output
#   the entire build process to a relative local file named 'build.log', which
#   contains more verbose Image build logging then the Docker CLI does, allowing
#   the user to troubleshoot any issues or errors that may occur.
# - Customize variables in the "SET VARIABLES" section below.  The only changes
#   likely neeeded are customizing the $IMAGE_NAME and $TAG variables.
#
# This script should work on POSIX compliant systems including FreeBSD, OpenBSD,
# most Linux distributions, MacOS 10.5+, and other Unix variants.
#

###################################
#### SET VARIOUS ENV VARIABLES ####
###################################

# Name of the Image to build
IMAGE_NAME="btaylormd/dvmkv2mp4"
# Image Tag (default: 'latest')
TAG="latest"

# Reserved for the git commit/revision hash tagging (used if we're within a git repo)
REVISION_TAG=""

###################################

# This loop should assign $SOURCE the proper path to this file,
# which works with aliases, relative path, symlinks, bash script.sh,
# sourcing, and more.
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
  DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
  SOURCE=$(readlink "$SOURCE")
  # if $SOURCE is a symlink, resolve it relative to path
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done

# YOU WON'T LIKELY NEED TO CHANGE THESE VARIABLES.
DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
BUILD_LOG_FILE="${DIR}/build.log" # A more verbose log of the Docker build process.
DOCKERFILE="${DIR}/Dockerfile"    # Name of the Dockerfile to build (default: Dockerfile)

######################
# BEGIN MAIN PROGRAM #
######################

# We should use the git revision/commit hash to tag each time we build, which
# should always be set as the image tag.  Additionally, we should always
# tag the newest revision as 'latest' as well.
# If we're within a git repo folder, add a tag for the revision
if [[ -d "${DIR}/.git" ]]; then
  REVISION_TAG=$(git rev-parse --short=9 HEAD)
fi

# if ! [ -x "$(command -v jq)" ]; then
#     echo "Error: 'jq' is not installed on this sytem." >&2
#     echo "Please consult your OS package manager and " \
#          "install it in order to continue." >&2
#     echo "" >&2
#     echo "e.g. On MacOS, use homebrew.  On Ubuntu/Debian linux, use apt." >&2
#     exit 1
# fi

# if ! [ -x "$(command -v curl)" ]; then
#     echo "Error: 'curl' is not installed on this sytem." >&2
#     echo "Please consult your OS package manager and " \
#          "install it in order to continue." >&2
#     echo "" >&2
#     echo "e.g. On MacOS, use homebrew.  On Ubuntu/Debian linux, use apt." >&2
#     exit 1
# fi

cat <<EOF
We will be running our build with a small modification to see more verbose 
logging of the build phase, with output being captured into the location: '${BUILD_LOG_FILE}'."

EOF

###############################################################################################
#                                 DOCKER IMAGE BUILD PHASE                                    #
###############################################################################################

# * If you need to specify build arguments due to ARG instructions in your Dockerfile,
# * use "docker build --build-arg ARGUMENT_NAME='VALUE' ..." as needed.
#
# * Set build context to the directory where the Dockerfile is in order to be able to
# * use all Docker instructions that use relative paths like 'COPY files/ /'.  In our
# * case, the Dockerfile, build_image.sh, and build.log will all be within the same
# * directory ($DIR).
#
# * All output will be more verbose and persistent in the $BUILD_LOG_FILE location.

# Also, add any custom / necessary build-time arguments for your image below.

if [[ -z "$REVISION_TAG" ]]; then
  cat <<EOF
Building new Docker image:
    * Image Name:           '${IMAGE_NAME}:${TAG}'
    * Source Dockerfile:    '${DOCKERFILE}'
    * Verbose Build Log:     '${BUILD_LOG_FILE}'

EOF
else
  cat <<EOF
Building new Docker image:
    * Image Name:           '${IMAGE_NAME}:${REVISION_TAG}' and '${IMAGE_NAME}:${TAG}'
    * Source Dockerfile:    '${DOCKERFILE}'
    * Verbose Build Log:     '${BUILD_LOG_FILE}'

EOF
fi

if [[ -z "$REVISION_TAG" ]]; then
  docker build -t "${IMAGE_NAME}:${TAG}" --no-cache -f "${DOCKERFILE}" --progress=plain "${DIR}" 2>"${BUILD_LOG_FILE}"
else
  docker build -t "${IMAGE_NAME}:${REVISION_TAG}" -t "${IMAGE_NAME}:${TAG}" --no-cache -f "${DOCKERFILE}" --progress=plain "${DIR}" 2>"${BUILD_LOG_FILE}"
fi

## After successful build, run with the following to include:
## * GPU SUPPORT
## * /dev/dri passthrough (allowing GPU access)
## * Set /convert in container to be mount point where your DV/HDR10+ MKV files are found.
## docker run --device /dev/dri:/dev/dri --gpus all -v /mnt/media-nas/Movie:/convert -it --name test  btaylormd/dvmkv2mp4:latest bash
