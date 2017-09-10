# k8s-sandbox

Alex Moss, 9th September 2017

## Description

My Kubernetes play area! Loads into a GCP GKE cluster with a basic web-app.

Will extend with other things to test/prototype as required.

Accessible via http://demo.moss.work at the moment.

## To Do

- force a rewrite to https
- Terraform a static IP out for it instead of ephemeral
- Can we Terraform the firewall rule updates for IAP?

## Things to Try

01. Istio
02. Helm
03. Pumba
04. IAP
    05. Recycling Pods
06. Reshifter / Ark
07. Sumologic
08. Sysdig
09. Kops
10. Kubicorn
11. InfraKit
12. Seccomp/AppArmor/RBAC
    13. Kube-lego
14. Simulate zero-downtime deploys - need some latency in the app to show it completes requests
    - more complex app needed
15. Liveness/Readiness Probes

## The Done Pile

01. Working nginx image deployed across three nodes with some static HTML. Yeah, that was the easy part!
