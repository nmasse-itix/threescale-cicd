# Using this Ansible role from Kubernetes

Open [job.yaml](job.yaml) and to tailor it to your environment. Update at least
the `hostname` and `access_token` fields of the `Secret` object.

You can also edit the `sso_issuer_endpoint` field if your API needs to be secured
with OpenID Connect.

Once finished, you can create the job:

```sh
kubectl create -f job.yaml
```

And wait for the job to complete:

```sh
kubectl get pods -l job-name=deploy-3scale-api -w
```
