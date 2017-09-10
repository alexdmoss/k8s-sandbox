#!/usr/bin/env bash
#
# [ADM, 2017-09-09] deploy.sh
#
# Deploys latest image to GKE by applying Kubernetes deployment manifest,
# after automatically updating with latest image tag in GCR.

# source global variables
. ./config/vars.sh
GCP_PROJECT_NAME=$(cat secrets/project.name)

# check required variables set
if [[ -z ${GCP_PROJECT_NAME} ]];  then echo "[ERROR] GCP_PROJECT_NAME not set, aborting.";  exit 1; fi
if [[ -z ${NGINX_IMAGE_NAME} ]];  then echo "[ERROR] NGINX_IMAGE_NAME not set, aborting.";  exit 1; fi

NGINX_BUILD_IMAGE=eu.gcr.io/${GCP_PROJECT_NAME}/${NGINX_IMAGE_NAME}

# get latest build info pushed to GCR (assumes NGINX & PHP version are linked)
LATEST_TAG=$(gcloud container images list-tags ${NGINX_BUILD_IMAGE} --sort-by="~timestamp" --limit=1 --format='value(tags)')
if [[ $(echo $LATEST_TAG | grep -c ",") -gt 0 ]]; then LATEST_TAG=$(echo $LATEST_TAG | awk -F, '{print $2}'); fi

set -x

# substitute in version and bucket info into NGINX manifest and apply it
cat ./k8s/01-nginx-deployment.yml | \
    sed 's#${IMAGE_VERSION}#'${LATEST_TAG}'#g' | \
    sed 's#${GCP_PROJECT_NAME}#'${GCP_PROJECT_NAME}'#g' | \
    kubectl apply -f -
