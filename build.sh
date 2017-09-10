#!/usr/bin/env bash
#
# [ADM, 2017-09-09] build.sh
#
# Builds docker images and publishes to Google Container Registry
#
# Notes:
# - As part of CD pipeline, version should be passed in by CI tool, but
#   for this implementation, it is set as global variable.


# source global variables
. ./config/vars.sh
GCP_PROJECT_NAME=$(cat secrets/project.name)

if [[ -z ${GCP_PROJECT_NAME} ]];  then echo "[ERROR] GCP_PROJECT_NAME not set, aborting."; exit 1; fi
if [[ -z ${NGINX_IMAGE_NAME} ]];  then echo "[ERROR] NGINX_IMAGE_NAME not set, aborting."; exit 1; fi
if [[ -z ${VERSION} ]];           then echo "[ERROR] VERSION not set, aborting.";          exit 1; fi

set -x

NGINX_BUILD_IMAGE=eu.gcr.io/${GCP_PROJECT_NAME}/${NGINX_IMAGE_NAME}:${VERSION}

find . -name '*.DS_Store' -exec rm {} \;

# build NGINX image
docker build -t ${NGINX_BUILD_IMAGE} -f ./Dockerfile.nginx .

# push to GCR - assumes command line already authenticated
gcloud docker -- push ${NGINX_BUILD_IMAGE}
