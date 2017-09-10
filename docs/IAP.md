# Google Identity Aware Proxy

Alex Moss, 10th September 2017

GCP's IAP is for controlling access to a resource in GCP. It supports Compute Engine, Container Engine, and App Engine (partially). It is important to note that it is not designed to control what a user can do after they've accessed your application.

A sensible use-case would be to protect access to resources that you want available on the internet, but only to a restricted group of people - e.g. a prototype or testing environment, or restricted API.

It works by integrating with GCP's load balancers - a move away from these would prevent its use.

Updates to the access policy (such as adding or removing users) appears to be relatively sluggish - many minutes.

## Notes:

In Console, it will warn when configuration allows you to bypass the IAP.
- have not yet tried disabling this config (as may break K8s)

Can be toggled for any resources surfaced via a load balancer. Naturally, it must be HTTPS.

Members can be:
- [tested] Google Accounts: e.g. user@gmail.com
- [tested] Google Groups: e.g. commerce-platforms@googlegroups.com
- Service Accounts: e.g. server@example.gserviceaccount.com
- [tested] G Suite Domains: e.g. the GCP organisation

---

If you access it from a browser which is already logged into G-Suite with a valid email address, it should just work
If you use another gmail account or a browser without anything like that (or curl it ...) then it should prompt you for authentication with Google.

---

## Firewall Policy Updates

GCP's IAP console stated the following when switching it on for the first time for my GKE cluster:

  Your settings need to meet the IAP configuration requirements . Use the tutorial to review the issues below, and update your configuration.

  Some IPs can bypass IAP. The following firewall rules allow some IP addresses to bypass IAP's access controls and connect directly to backend service k8s-be-30080--abcf60250ed78e59.

    `default-allow-internal	10.128.0.0/9 - tcp:0-65535; udp:0-65535; icmp
    gke-frontend-cluster-2da5852e-all	10.52.0.0/14 - tcp; udp; icmp; esp; ah; sctp
    gke-frontend-cluster-2da5852e-vms	10.128.0.0/9 - tcp:1-65535; udp:1-65535; icmp`

I thought I'd see what happens if I locked these down but didn't delete them (so I could restore config more easily!) - I changed all three to only allow icmp.
- this did not appear to have any immediate negative consequences

---

## Enabling Audit Logging

This is relatively simple from the command line:

  1. Retrieve the existing IAM policy:

      `gcloud projects get-iam-policy PROJECT_ID > policy.yml`

  2. Update policy.yml from above with the following additional configuration:

      `auditConfigs:
      - auditLogConfigs:
        - logType: ADMIN_READ
        - logType: DATA_READ
        - logType: DATA_WRITE
        service: allServices`

  3. Apply the revised policy:

    `gcloud projects set-iam-policy PROJECT_ID policy.yml`

Log entries then start appearing in Stackdriver - the text 'data_access' shows ones flagged by the auditing.

---

## Beyond the Scope

Google recommend securing your app with signed IAP headers. This protects your app when IAP is accidentally disabled, firewalls are misconfigured, or from access through other circuitous routes (e.g. internally to the project).
As this requires changes to app code, this is not something that we're likely to be interested in for my project (we want it as light-touch as possible!), but something to bear in mind.
- https://cloud.google.com/iap/docs/signed-headers-howto

---

## To Do

- Configured from the command line
- Test a serviceaccount
- Track the user's headers (needs better demo app) - https://cloud.google.com/iap/docs/identity-howto
- Ping/AD integration
