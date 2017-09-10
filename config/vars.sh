#!/usr/bin/env bash

# at the moment we assume that nginx & php app version numbers are linked
VERSION=0.1
NGINX_IMAGE_NAME=frontend-nginx

# GCP
# GCP_PROJECT_NAME redacted - see secrets/

# Kubernetes
NAMESPACE=frontend
