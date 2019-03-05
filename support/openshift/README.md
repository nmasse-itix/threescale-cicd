# Using this Ansible role from Kubernetes

You can use the provided OpenShift template to create all the mandatory objects:

- An ImageStream to keep track of the [provided docker image](https://hub.docker.com/r/nmasse/threescale-cicd).
- A custom BuildConfig that checkout the GIT repository containing the OpenAPI Specification and runs the Ansible role on it
- A Secret holding the credentials to access the 3scale Admin Portal

```sh
oc create -f openshift-template.yaml
oc new-app --template=deploy-3scale-api -p THREESCALE_CICD_VERSION=stable -p THREESCALE_ADMIN_PORTAL_ACCESS_TOKEN=1234..5678 -p THREESCALE_ADMIN_PORTAL_HOSTNAME=TENANT-admin.3scale.net -p API_NAME=echo-api -p THREESCALE_CICD_PRIVATE_BASE_URL=https://echo-api.3scale.net -p API_GIT_URI=https://github.com/nmasse-itix/rhte-api.git
```

You will have to change at least the value of:

- the `THREESCALE_ADMIN_PORTAL_ACCESS_TOKEN` parameter to match the Access Token of your 3scale Admin Portal
- the `THREESCALE_ADMIN_PORTAL_HOSTNAME` parameter to match the hostname of your 3scale Admin Portal

This template will create a BuildConfig with the name of your API:

```raw
$ oc get bc
NAME                         TYPE      FROM                     LATEST
deploy-3scale-api-echo-api   Custom    threescale-cicd:stable   7
```

Start the build to deploy the API to 3scale:

```sh
oc start-build deploy-3scale-api-echo-api
```

Wait for the build to complete:

```sh
oc logs -f bc/deploy-3scale-api-echo-api
```
