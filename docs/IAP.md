# Google Identity Aware Proxy

**Alex Moss, 10th September 2017**

GCP's IAP is for controlling access to a resource in GCP. It supports Compute Engine, Container Engine, and App Engine (partially). It is important to note that it is _not_ designed to control what a user can do after they've accessed your application, only their access to that resource.

A sensible use-case for it would be to protect access to resources that you want available on the internet, but only to a restricted group of people - e.g. a prototype or testing environment, or restricted API.

It works by integrating directly with GCP's load balancers - i.e. a move away from these would prevent its use.


---

## Notes from my Experimentation:

Enabling through the GCP Console is trivial. For your GCP project, navigate to the **IAM > Identity Aware Proxy** section, populate the OAuth Consent screen details (what your user sees to log in), then toggle on for the frontends in question. Access can also be added here to users/groups/domains as required.



Additionally, in the console, it will warn when configuration allows you to bypass the IAP.
- I followed its advice and locked down (but didn't delete completely - see notes below) some of the default firewall rules for internal access created by GKE, and my simple website did continue to work fine



IAP can be individually toggled for any resources surfaced via a load balancer. Naturally, it must be HTTPS-enabled.
- Intriguingly, it seems to have also set up a redirect somewhere that sends any HTTP traffic to HTTPS automatically. I certainly didn't do it!
- I haven't been able to successfully track down how it has achieved this - Googling suggests this isn't even a supported feature on GCP! Clever ...



Members can be:
- [tested] Google Accounts: e.g. user@gmail.com
- [tested] Google Groups: e.g. commerce-platforms@googlegroups.com
- [untested] Service Accounts: e.g. server@example.gserviceaccount.com
- [tested] G Suite Domains: e.g. the GCP organisation

If you access it from a browser which is already logged into G-Suite with a valid email address, it should just work without prompting, which is rather nice.
If you use another account or a browser without anything like that (or curl it ...) then it should prompt you for authentication with Google.



The configuration does not seem to be granular enough to allow setting of specific access to specific frontends - the GCP project itself acts as the boundary. This would have interesting ramifications if we wanted different levels of access for different environments defined within a project, for example (although I'm not sure that's a good thing in general!). It could be possible to define custom roles for it, but I did not dig that far.



I also noted that updates to the access policy (such as adding or removing users) appears to be relatively sluggish (several minutes). Disabling IAP for a service was even more slow (resulting in the access being revoked - and therefore blocking me from accessing the application - before IAP was switched off to allow me in without authentication). There is also a period of time after IAP is switched off where the site throws 500 errors for a time before resolving itself. In other words, this isn't a service you can easily toggle on and off without expecting to wait a little while for things to sort themselves out.


---

## Firewall Policy Updates

GCP's IAP console stated the following when switching it on for the first time for my GKE cluster:

  > Your settings need to meet the IAP configuration requirements. Use the tutorial to review the issues below, and update your configuration.
  > Some IPs can bypass IAP. The following firewall rules allow some IP addresses to bypass IAP's access controls and connect directly to backend service k8s-be-30080--abcf60250ed78e59.

    default-allow-internal	10.128.0.0/9 - tcp:0-65535; udp:0-65535; icmp
    gke-frontend-cluster-2da5852e-all	10.52.0.0/14 - tcp; udp; icmp; esp; ah; sctp
    gke-frontend-cluster-2da5852e-vms	10.128.0.0/9 - tcp:1-65535; udp:1-65535; icmp

I thought I'd see what happens if I locked these down but didn't delete them (so I could restore config more easily!) - I changed all three to only allow icmp. This did not appear to have any immediate negative consequences - including trying it the following day.


---

## Yes that's all lovely but what about from the command line?

I'm with you on that! Fortunately there are CLI options to enable IAP.



The first step is to get OAuth set up. I'd already sorted the Consent form bit from my manual experimentation, but for the CLI call we need OAuth credentials. Sadly, the GCP guide has you doing this through the GUI as there is no API for creating an OAuth2.0 Client ID at present, which is unfortunate.

To do this via a browser, it is here: https://console.developers.google.com/apis/credentials

The outcome should be an OAuth Client ID (+ Secret) defined for use with a web application, with an authorized redirect URI of _https://<ourURL>/_gcp_gatekeeper/authenticate_.



We're then working with the beta extensions of the GCloud SDK and we're in business:

      gcloud auth login
      gcloud config set project ${GCP_PROJECT_ID}
      gcloud beta compute backend-services list

If it is not easy to work out which backend is the relevant one from its port, this may help:

      gcloud beta compute backend-services describe ${BACKEND_SERVICE_NAME} --global --format=yaml | grep description:

Enabling it then becomes a case of update the backend-services config to set iap=enabled, with the relevant OAuth supplied:

      gcloud beta compute backend-services update ${BACKEND_SERVICE_NAME} --global --iap=enabled,oauth2-client-id=${IAP_CLIENT_ID},oauth2-client-secret=${IAP_SECRET}`

With that done, I've now blocked my app. Awesome! But I should probably add some access back in. There is a role  _roles/iap.httpsResourceAccessor_ in IAM for using IAP, which is just wonderful, as we can do things like this:

      gcloud projects add-iam-policy-binding PROJECT_ID --member user:${USER_EMAIL_ADDRESS} --role roles/iap.httpsResourceAccessor

  In place of `--member user:<value>`, you can specify `group:<value>` and `domain:<value>` too.

  More detail on this command here: https://cloud.google.com/iam/docs/granting-changing-revoking-access

This command spits back the IAM Policy which seems a bit odd to me, but at least you can parse it to check success!


---

## Enabling Audit Logging

This is relatively simple from the command line:

  1. Retrieve the existing IAM policy:

    gcloud projects get-iam-policy ${GCP_PROJECT_ID} > policy.yml

  2. Update policy.yml from above with the following additional configuration:

      ```
      auditConfigs:
      - auditLogConfigs:
        - logType: ADMIN_READ
        - logType: DATA_READ
        - logType: DATA_WRITE
        service: allServices
      ```

  3. Apply the revised policy:

    gcloud projects set-iam-policy ${GCP_PROJECT_ID} policy.yml

Log entries then start appearing in Stackdriver - the text **data_access** shows ones flagged by the auditing.


---

## Beyond the Scope

Google recommend securing your app with signed IAP headers. This protects your app when IAP is accidentally disabled, firewalls are misconfigured, or from access through other circuitous routes (e.g. internally to the project).

As this requires changes to app code, this is not something that we're likely to be interested in for my project (we want it as light-touch as possible!), but something to bear in mind.
- https://cloud.google.com/iap/docs/signed-headers-howto


---

## To Do

- [] Test a ServiceAccount
- [] Track the user's headers (needs better demo app) - https://cloud.google.com/iap/docs/identity-howto
- [] Ping/AD integration
