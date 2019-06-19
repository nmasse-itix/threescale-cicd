# Test Environment setup

## 3scale SaaS with APIcast Self-Managed

Create a project in an OpenShift cluster:

```sh
oc new-project apicast-3scale-ci
```

Deploy two 3scale gateways (staging and production):

```sh
oc create secret generic 3scale-tenant-<NAME> --from-literal=password=https://<TOKEN>@<NAME>-admin.3scale.net
oc create -f https://raw.githubusercontent.com/3scale/apicast/v3.4.0/openshift/apicast-template.yml
oc new-app --template=3scale-gateway --name=apicast-<NAME>-staging -p CONFIGURATION_URL_SECRET=3scale-tenant-<NAME> -p CONFIGURATION_CACHE=0 -p RESPONSE_CODES=true -p LOG_LEVEL=info -p CONFIGURATION_LOADER=lazy -p APICAST_NAME=apicast-<NAME>-staging -p DEPLOYMENT_ENVIRONMENT=sandbox -p IMAGE_NAME=quay.io/3scale/apicast:v3.4.0
oc new-app --template=3scale-gateway --name=apicast-<NAME>-production -p CONFIGURATION_URL_SECRET=3scale-tenant-<NAME> -p CONFIGURATION_CACHE=60 -p RESPONSE_CODES=true -p LOG_LEVEL=info -p CONFIGURATION_LOADER=boot -p APICAST_NAME=apicast-<NAME>-production -p DEPLOYMENT_ENVIRONMENT=production -p IMAGE_NAME=quay.io/3scale/apicast:v3.4.0
oc scale dc/apicast-<NAME>-staging --replicas=1
oc scale dc/apicast-<NAME>-production --replicas=1
oc create route edge apicast-nmasse-redhat-staging --service=apicast-nmasse-redhat-staging --hostname=wildcard.nmasse-redhat-staging.app.itix.fr --insecure-policy=Allow
oc create route edge apicast-nmasse-redhat-production --service=apicast-nmasse-redhat-production --hostname=wildcard.nmasse-redhat-production.app... --insecure-policy=Allow
```

Provision the Red Hat SSO tenants with the included playbooks:

```sh
ansible-playbook tests/setup/setup-sso.yml -e sso_admin_password=secret -e sso_hostname=sso.app.example.test
```

## 3scale on-premise

Create a project in an OpenShift cluster:

```sh
oc new-project 3scale-ci-23 --display-name="3scale CI 2.3"
```

Deploy 3scale AMP 2.3:

```sh
oc create -f https://raw.githubusercontent.com/3scale/3scale-amp-openshift-templates/2.3.0.GA/amp/amp.yml
oc new-app --template=3scale-api-management -p WILDCARD_DOMAIN=3scale-ci-23.app.example.test -p WILDCARD_POLICY=Subdomain
```

Create two tenants: `pool1` and `pool2` and expose them:

```sh
oc expose svc/system-provider --hostname pool1-admin.3scale-ci-23.app.example.test --overrides='{ "apiVersion": "route.openshift.io/v1", "kind": "Route", "spec": { "tls": { "insecureEdgeTerminationPolicy": "Allow", "termination": "edge" } } }' --name=pool1-admin
oc expose svc/system-provider --hostname pool2-admin.3scale-ci-23.app.example.test --overrides='{ "apiVersion": "route.openshift.io/v1", "kind": "Route", "spec": { "tls": { "insecureEdgeTerminationPolicy": "Allow", "termination": "edge" } } }' --name=pool2-admin
```

Provision the Red Hat SSO tenants with the included playbooks:

```sh
ansible-playbook tests/setup/setup-sso.yml -e sso_admin_password=secret -e sso_hostname=sso.app.example.test
```

Delete the wildcard route and recreate it with two more routes:

```sh
oc delete route apicast-wildcard-router
oc expose svc/apicast-wildcard-router --wildcard-policy=Subdomain --overrides='{ "apiVersion": "route.openshift.io/v1", "kind": "Route", "spec": { "tls": { "insecureEdgeTerminationPolicy": "Allow", "termination": "edge" } } }'  --hostname=apicast-wildcard.pool1.3scale-ci-23.app.example.test --name=pool1-apicast-wildcard-router
oc expose svc/apicast-wildcard-router --wildcard-policy=Subdomain --overrides='{ "apiVersion": "route.openshift.io/v1", "kind": "Route", "spec": { "tls": { "insecureEdgeTerminationPolicy": "Allow", "termination": "edge" } } }'  --hostname=apicast-wildcard.pool2.3scale-ci-23.app.example.test --name=pool2-apicast-wildcard-router
oc expose svc/apicast-wildcard-router --wildcard-policy=Subdomain --overrides='{ "apiVersion": "route.openshift.io/v1", "kind": "Route", "spec": { "tls": { "insecureEdgeTerminationPolicy": "Allow", "termination": "edge" } } }'  --hostname=apicast-wildcard.3scale-ci-23.app.example.test --name=apicast-wildcard-router
```

Do the same with other versions of 3scale.
