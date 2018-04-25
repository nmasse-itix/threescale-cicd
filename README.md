# ansible-cicd

[![Build Status](https://travis-ci.org/nmasse-itix/threescale-cicd.svg?branch=master)](https://travis-ci.org/nmasse-itix/threescale-cicd)

Enables Continuous Delivery with Red Hat 3scale API Management Platform (3scale AMP).

## Requirements

This role requires:
 - an instance of 3scale API Management Platform (hosted or on-premise)
 - an instance of Red Hat SSO if you plan to use OpenID Connect authentication
 - two APIcast gateways (staging and production), either hosted or self-managed
 - a Swagger 2.0 file describing the API you want to publish

All the components are driven through APIs, so no SSH connection is required!

On the control node, the `jmespath` library is required. If it is not already there,
you can install it with:
```
pip install jmespath
```

## Role Variables

TODO

## Dependencies

This role has no dependencies.

## Example: Deploy an API on 3scale SaaS with hosted APIcast gateways

If you want to deploy the classic "Echo API" on a SaaS 3scale instance using API Keys,
you can do it in three steps:
 1. Craft a Swagger file for your Echo API
 2. Build your inventory file
 3. Write the playbook
 4. Run the playbook!

First, make sure your swagger file (`api-swagger.yaml`) has the required information:
```
swagger: '2.0'
info:
  x-threescale-system-name: 'echo-api'
  title: 'Echo API'
  version: '1.0'
host: 'echo-api.3scale.net'
paths:
  /:
    get:
      operationId: Echo
      summary: 'Get an echo'
      description: 'Get an echo from the server'
      x-threescale-smoketests-operation: true
      responses:
        200:
          description: 'An Echo from the server'
security:
- apikey: []
securityDefinitions:
  apikey:
    name: api-key
    in: header
    type: apiKey
```

In this Swagger file, the following fields are used:
- `x-threescale-system-name` is used as system_name for the configuration objects in 3scale.
- `title` is used as the name of the service definition.
- `version` is used for proper versioning and follows the [semver scheme](https://semver.org/).
- `host` is the DNS name of the existing API backend to expose.
- the `operationId` fields are used as the system_name for the methods/metrics.
- the `summary` and `description` fields are used as name and description for the methods/metrics.
- `x-threescale-smoketests-operation` is used to flag one operation as usable for smoke tests. The method needs to be idempotent, read-only and without parameters. If no method is flagged as smoke tests, the smoke tests are just skipped.
- the `security` and `securityDefinitions` are used to determine the security scheme of the exposed API. In this example, we are using the API Keys scheme.

Then, write the `inventory` file:
```
[all:vars]
ansible_connection=local

[threescale]
<TENANT>-admin.3scale.net

[threescale:vars]
threescale_cicd_access_token=<ACCESS_TOKEN>
```

The important bits of the inventory file are:
- the 3scale admin portal needs to be declared in a group named `threescale`.
- the [3scale access token](https://access.redhat.com/documentation/en-us/red_hat_3scale/2.saas/html-single/accounts/index#access_tokens) needs to be set in the `threescale_cicd_access_token` variable.
- since no SSH connection is needed (we only use the 3scale Admin APIs), `ansible_connection=local` is set to the whole inventory.

You can now write the playbook:
```
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_openapi_file: '/path/to/api-swagger.yaml'
  roles:
  - threescale-cicd
```

The main parts are:
- `threescale_cicd_openapi_file` is the path to the swagger file defined in step 1.
- the `threescale-cicd` role is used.
- `gather_facts: no` needs to be used since there is no SSH connection to the target systems.

## License

BSD

## Author Information

- Nicolas Massé, Red Hat
