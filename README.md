ansible-cicd
=========
[![Build Status](https://travis-ci.org/nmasse-itix/threescale-cicd.svg?branch=master)](https://travis-ci.org/nmasse-itix/threescale-cicd)
Enables Continuous Delivery with Red Hat 3scale API Management Platform (3scale AMP).

Requirements
------------

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

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

This role has no dependencies.

Example: Deploy an API on 3scale SaaS with hosted APIcast gateways
----------------

If you want to deploy the classic "Echo API" on a SaaS 3scale instance using API Keys,
you can do it in three steps:
 1. Craft a Swagger file for your Echo API
 2. Build your inventory file
 3. Write the playbook
 4. Run the playbook!

First, make sure your swagger file has the required information:
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
- `x-threescale-system-name` is used as system_name for the configuration objects in 3scale
- `title` is used as the name of the service definition
- `version` is used for proper versioning and follows the [semver scheme](https://semver.org/).
- `host` is the DNS name of the existing API backend to expose
- `schemes` is the



```
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_openapi_file: '/path/to/api-swagger.yaml'
  roles:
  - threescale-cicd
```

License
-------

BSD

Author Information
------------------

- Nicolas Massé, Red Hat
