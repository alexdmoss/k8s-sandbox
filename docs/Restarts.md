
# Experimenting with pod restarts

Alex Moss, 9th September 2017

## References:

- https://pracucci.com/graceful-shutdown-of-kubernetes-pods.html
- https://github.com/kubernetes/kubernetes/issues/13488

## Working Methods:

#### Update a Label

Updating a label (e.g. setting one called timestamp) in the deployment and re-deploying it.
This follows the rollingUpdate strategy specified, but without needing a differently tagged image, as expected.

This was tested using the yaml manifest for the deployment, and it does work. The yaml could be manipulated on-the-fly if necessary, rather than reinitiating from the source file (depending on urgency / ways-of-working expectations).

#### Update an environment variable

A very similar technique to the Label above, but with an environment variable instead.

Personally I favour this, as keeping track of restarts in an environment variable feels more natural than a label (which to me, feels more permanent).

For an existing deployment, a `kubectl patch` command can be used as follows:

  `
  kubectl patch deployment frontend-nginx \
  -p'{"spec":{"template":{"spec":{"containers":[{"name":"frontend-nginx","env":[{"name":"LAST_RESTART_","value":"'$(date "+%Y-%m-%d.%H:%M:%S")'"}]}]}}}}'
  `
In this example, my container named frontend-nginx has an environment variable set called LAST_RESTART which is set to the current timestamp (be careful with the formatting of date here to maintain valid config).

The advantage here is that a reinitiated "proper" deployment clears the variable entirely, so you know when it has been set it has been deliberately manipulated outside the CD pipeline.

It is also easy to see when it was last restarted in this way!

#### Dummy ConfigMap

Dummy ConfigMap mapped to environment variable not tested, but probably similar to the label/env variable technique.

There is a good step-by-step guide here to a potential technique - much more complex than the simple commands above, but perhaps more flexible:
 - https://github.com/kargakis/configmap-rollout

## Additional Notes

It is a good idea to ensure that a clean shutdown is set for pods to avoid potentially aggressive SIGTERMs or SIGKILLs.

This is easily done for most things, e.g.

  `
  spec:
    template:
      spec:
        containers:
          lifecycle:
            preStop:
              exec:
                command: ["/usr/sbin/nginx","-s","quit"]
  `

For docker images that spin up via a CMD that starts with a /bin/sh call, keep in mind that the SIGTERM will kill the shell, not the process running within it. This depends on the shell used - e.g. Bash will pass the signal down to its children (but Alpine's default shell doesn't).


Additionally, for processes that take longer to stop, the timeout (default 30s) can be manipulated easily enough by setting:

  `
  spec:
    template:
      spec:
        terminationGracePeriodSeconds: 60
  `

## Disruptive Techniques

Deleting pods runs the risk of being disruptive, depending on how gracefully the application handles it. This is because the deployment policy is not being honoured here - Kubernetes is just restoring service to something it sees as having failed.

Likewise, using a `kubectl replace` on the pod has the same effect as a delete. Against the deployment this is ineffective (without also updating a field - see above).

Using these techniques would need testing and sequencing correctly to preserve availability.

In other words, you're better off sticking with the labels/environment variable techniques above.
