#!/usr/bin/env bash
#
# [ADM, 2017-09-09] install.sh
#
# Deploys latest image to GKE by applying Kubernetes deployment manifest,
# after automatically updating with latest image tag in GCR.

# source global variables
. ./config/vars.sh
GCP_PROJECT_NAME=$(cat secrets/project.name)

# check required variables set
if [[ -z ${GCP_PROJECT_NAME} ]];  then echo "[ERROR] GCP_PROJECT_NAME not set, aborting.";  exit 1; fi
if [[ -z ${NGINX_IMAGE_NAME} ]];  then echo "[ERROR] NGINX_IMAGE_NAME not set, aborting.";  exit 1; fi

echo "Have you updated terraform/main.tf with the correct GCP Project Name?"
read input
if [[ $input == "Y "]] || [[ $input == "y" ]]; then
  cd terraform/
  terraform apply
  cd ../
else
  echo "[ERROR] You must do this first!"
  exit
fi

NGINX_BUILD_IMAGE=eu.gcr.io/${GCP_PROJECT_NAME}/${NGINX_IMAGE_NAME}

# get latest build info pushed to GCR (assumes NGINX & PHP version are linked)
LATEST_TAG=$(gcloud container images list-tags ${NGINX_BUILD_IMAGE} --sort-by="~timestamp" --limit=1 --format='value(tags)')
if [[ $(echo $LATEST_TAG | grep -c ",") -gt 0 ]]; then LATEST_TAG=$(echo $LATEST_TAG | awk -F, '{print $2}'); fi

set -x

kubectl apply -f ./k8s/00-create-namespace.yml
cat ./k8s/01-nginx-deployment.yml | sed 's#${IMAGE_VERSION}#'${LATEST_TAG}'#g' | kubectl apply -f -
kubectl apply -f ./k8s/02-nginx-svc.yml
kubectl apply -f ./k8s/03-create-ingress.yml
