
# Kube-lego

Alex Moss, 10th September 2017

Trying out kube-lego to automatically generate SSL certificates using Let's Encrypt.

kube-lego is a project created by JetStack:
- https://www.jetstack.io/engineering/kube-lego/
- https://github.com/jetstack/kube-lego/tree/master/examples/gce

## How To

Deploy the kube-lego pod with `kubectl apply -f k8s/`
- this consists of a Deployment of a single Pod, and a ConfigMap

Set the following in the application's ingress (assumes GCE LoadBalancer):

  `kubernetes.io/tls-acme: "true"

  tls:
  - hosts:
    - demo.moss.work
    secretName: frontend-nginx-tls`

## Why Kube-Lego?

- Supports configuring both GCE Ingress Controllers and NGINX ingress controllers with LetsEncrypt Certs (I'm using GCE in this example).
- Supports automatic renewals and the automated proof of ownership needed by LetsEncrypt.
- It’s standalone. The LetsEncrypt code isn’t embedded in the LoadBalancer (Ingress Controller) code itself

## Troubleshooting

GCE has a limit of 5 backend services by default. Use the command below to verify if you're reaching the limits.

  `kubectl get events -w --all-namespaces`
