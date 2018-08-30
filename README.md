# ansible-cicd

[![Build Status](https://travis-ci.org/nmasse-itix/threescale-cicd.svg?branch=master)](https://travis-ci.org/nmasse-itix/threescale-cicd)
[![MIT licensed][mit-badge]][mit-link]
[![Galaxy Role][role-badge]][galaxy-link]

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

```sh
pip install jmespath
```

A recent version of Jinja (2.8) is also required. You can upgrade your Jinja version with:

```sh
pip install -U Jinja2
```

If your control node runs on RHEL7, you can run
[this playbook](https://github.com/nmasse-itix/OpenShift-Lab/blob/master/common/verify-local-requirements.yml)
to install the missing dependencies.

## Example: Deploy an API on 3scale SaaS with hosted APIcast gateways

If you want to deploy the classic "Echo API" on a SaaS 3scale instance using API Keys,
you can do it in three steps:

 1. Craft a Swagger file for your Echo API
 2. Build your inventory file
 3. Write the playbook
 4. Run the playbook!

First, make sure your swagger file (`api-swagger.yaml`) has the required information:

```yaml
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

- `x-threescale-system-name` is used as a basis for the system_name for the
  configuration objects in 3scale.
- `title` is used as the name of the service definition.
- `version` is used for proper versioning and follows the [semver scheme](https://semver.org/).
- `host` is the DNS name of the existing API backend to expose.
- the `operationId` fields are used as the system_name for the methods/metrics.
- the `summary` and `description` fields are used as name and description for the methods/metrics.
- `x-threescale-smoketests-operation` is used to flag one operation as usable for smoke tests. The method needs to be idempotent, read-only and without parameters. If no method is flagged as smoke tests, the smoke tests are just skipped.
- the `security` and `securityDefinitions` are used to determine the security scheme of the exposed API. In this example, we are using the API Keys scheme.

Then, write the `inventory` file:

```ini
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

You can now write the playbook (`deploy-api.yaml`):

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_openapi_file: 'api-swagger.yaml'
  roles:
  - nmasse-itix.threescale-cicd
```

The main parts are:

- `threescale_cicd_openapi_file` is the path to the swagger file defined in step 1.
- the `nmasse-itix.threescale-cicd` role is used.
- `gather_facts: no` needs to be used since there is no SSH connection to the target systems.

Finally, you can run the playbook:

```sh
ansible-galaxy install nmasse-itix.threescale-cicd
ansible-playbook -i inventory deploy-api.yaml
```

## Inventory

The 3scale Admin Portal that will be provisionned is the one that is referenced
in the playbook that includes this role. For instance, in the previous example,
the provisioned 3scale Admin Portal will be `<TENANT>-admin.3scale.net` because
the main playbook specifies `hosts: threescale` and the `threescale` group
contains only one host: `<TENANT>-admin.3scale.net`.

If you specifies multiple hosts for the 3scale Admin Portal, they all will be
provisionned with the exact same configuration (useful for multi-site deployments).

To connect to the 3scale Admin Portal, you will have to provide an Access Token
having read/write privileges on the Account Management API. You can provide this
token at the host level, group level or globally with the
`threescale_cicd_access_token` variable.

At the host level, it is defined as such:

```ini
[threescale]
tenant1-admin.3scale.net threescale_cicd_access_token=123...456
tenant2-admin.3scale.net threescale_cicd_access_token=789...012
```

At the group level, you can define it as such:

```ini
[threescale:vars]
threescale_cicd_access_token=123...456

[threescale]
tenant1-admin.3scale.net
tenant2-admin.3scale.net
```

And you can also define it globally, for instance as playbook vars:

```yaml
- hosts: threescale
  vars:
    threescale_cicd_access_token: 123...456
```

The Red Hat SSO instance (currently there can only be one), is defined by
the `threescale_cicd_sso_issuer_endpoint` variable of the `threescale` group.

Its syntax is `https://<client_id>:<client_secret>@hostname/auth/realms/<realm>`.
The `client_id`/`client_secret` are used by Zync to synchronize the 3scale
applications with Red Hat SSO.

Example:

```ini
threescale_cicd_sso_issuer_endpoint=https://3scale:123@sso.acme.corp/auth/realms/acme
```

The APIcast instances are defined from the following extra variables:

- `threescale_cicd_apicast_sandbox_endpoint`
- `threescale_cicd_apicast_production_endpoint`

Example:

```ini
threescale_cicd_apicast_sandbox_endpoint=http://api-test.acme.corp
threescale_cicd_apicast_production_endpoint=https://api.acme.corp
```

## OpenAPI Specification fields

This role currently supports only OpenAPI Specifications v2.0 (aka. Swagger 2.0).

The following extended fields of the OpenAPI Specifications can be used:

- `x-threescale-system-name`, in the `info` structure is used as basis
  to construct the system_name for the configuration objects in 3scale.
- `x-threescale-smoketests-operation` in a method definition is used to flag
  this operation as usable for smoke tests. The method needs to be idempotent,
  read-only and without parameters. If no method is flagged as smoke tests,
  the smoke tests are just skipped.

If the extended fields cannot be used (if for instance you do not want to alter
your API Contract), you can use the corresponding extra variable:

- `threescale_cicd_api_base_system_name`
- `threescale_cicd_openapi_smoketest_operation`

Here is an example of an OpenAPI Specification using those extended fields:

```yaml
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

Namely, `echo-api` would be used as a basis to construct the system_name
of the 3scale service definition and a `GET` on `/` would be used as
smoketests.

To achieve the same effect without the OpenAPI extended fields, you would have
to pass the following extra variables:

```ini
threescale_cicd_api_base_system_name=echo-api
threescale_cicd_openapi_smoketest_operation=Echo # The operationId of the "GET /" method
```

The following standard fields of the OpenAPI Specifications are used.

In the `info` section:

- `title` is used as the display name of the 3scale service definition.
- `version` is used for proper versioning and follows the [semver scheme](https://semver.org/).
- `host` is the DNS name of the existing API backend to expose.

For each defined method:

- the `operationId` fields is used as the system_name for the corresponding
  methods/metrics.
- the `summary` and `description` fields are used as name and description
  for the methods/metrics.
- the `security` and `securityDefinitions` are used to determine the security
  scheme of the exposed API.

To have a one-to-one mapping between the OpenAPI Specifications and the 3scale features,
some restrictions are applied on the `security`/`securityDefinitions` structures.
Namely, there must be one and exactly one security requirement in the `security`
structure. The security requirement needs to be applied globally (not on a per
method basis).

The security definitions also have restrictions: you can choose between only two
security schemes:

- OAuth / OpenID Connect
- API Key

The App Key Pair scheme proposed by 3scale has no corresponding definition in the
OpenAPI Specifications and is currently not supported by this role.

So to be more concrete, to secure your API with API Key, use this excerpt in your
OpenAPI Specification file:

```yaml
securityDefinitions:
  apikey:
    name: api-key
    in: header
    type: apiKey
security:
- apikey: []
```

You can of course, choose the HTTP header name that will be used to send the
API Key by changing the `name` field (in this example: `api-key`).

And to secure it with OpenID Connect use this excerpt in your OpenAPI
Specification file:

```yaml
securityDefinitions:
  oidc:
    type: oauth2
    flow: accessCode
    scopes:
      openid: Get an OpenID Connect token
security:
- oidc:
  - openid
```

You can of course use the OpenID Connect flow of your choice:

- `implicit`
- `password`
- `application`
- `accessCode`

## Role Variables

This section presents extensively all the variables used by this role. As a
foreword, this role adopt a convention-over-configuration scheme. This means
that sensible defaults and opinionated naming schemes are provided out-of-the-box.

### `threescale_cicd_openapi_file`

Specifies the OpenAPI Specification file to read.

- **Syntax:** Complete path to the OpenAPI Specification, on the local filesystem.
  Avoid relative paths, prefer absolute ones. If you need to read a file that is
  relative to your playbook, use the `{{ playbook_dir }}` placeholder.
- **Required:** yes
- **Examples:** `/tmp/openapi.yaml` or `{{ playbook_dir }}/git/openapi.json`

### `threescale_cicd_openapi_file_format`

Specifies the format (JSON or YAML) of the OpenAPI Specification file to read.

- **Syntax:** `JSON` or `YAML`
- **Required:** no
- **Default value:** `YAML`
- **Example:** `YAML`

### `threescale_cicd_api_system_name`

Defines the system_name of the 3scale Service that will be provisioned.

- **Syntax:** lower case alphanumeric + underscore
- **Required:** no
- **Default value:** if not defined, the system_name is taken from the
  `threescale_cicd_api_base_system_name` variable. This base system_name
  is then suffixed by the API major version number and prefixed by the
  environment name (only if `threescale_cicd_api_environment_name` is defined).
- **Example:** `dev_my_wonderful_service_1`

### `threescale_cicd_api_base_system_name`

Is used as a basis to compute the `threescale_cicd_api_system_name`.

- **Syntax:** lower case alphanumeric + underscore
- **Required:** no
- **Default value:** if not defined, the OpenAPI Specification
  `x-threescale-system-name` extended field or as a last resort, the `title`
  field is sanitized and then used.
  If no title can be found, the default value `API` is used. If no version
  number can be found, `0` is used.
- **Example:** `my_wonderful_service`

Note: If both `threescale_cicd_api_base_system_name` and `threescale_cicd_api_system_name`
are set, the later has precedence.

### `threescale_cicd_wildcard_domain`

Automatically defines the APIcast public URLs based on a scheme.

- **Syntax:** DNS domain suffix
- **Required:** no
- **Default value:** if defined, computes the `threescale_cicd_apicast_sandbox_endpoint`
  and `threescale_cicd_apicast_production_endpoint` from the API system_name.
  The sandbox APIcast will be `<system_name>-staging.<wildcard_domain>` and the
  production APIcast will be `<system_name>.<wildcard_domain>`. The suffix for the
  staging (`-staging`) and the production (empty) can be customized with the
  `threescale_cicd_default_staging_suffix` and `threescale_cicd_default_production_suffix`
  variables.
- **Example:** the following two variables

  ```ini
  threescale_cicd_wildcard_domain=acme.corp
  threescale_cicd_api_base_system_name=my_wonderful_service
  ```

  are equivalent to:

  ```ini
  threescale_cicd_apicast_sandbox_endpoint=https://my-wonderful-service-staging.acme.corp/
  threescale_cicd_apicast_production_endpoint=https://my-wonderful-service.acme.corp/
  ```

### `threescale_cicd_api_basepath`

Defines a `basePath` on which is deployed the backend API, overriding the `basePath` field
of the OpenAPI Specification. The resulting value is used to define the mapping rules of the
3scale API Gateway, prepending this base path to paths of different methods/operations.

- **Syntax:** URI part with starting /
- **Required:** no
- **Default value:** the `basePath` field of the OpenAPI Specification.
- **Examples:** `/api` or `/context`

### `threescale_cicd_api_backend_hostname`

Defines the backend hostname, overriding the `host` field of the OpenAPI Specification.
The resulting value is used to define the `threescale_cicd_private_base_url` variable
if missing.

- **Syntax:** FQDN with an optional port
- **Required:** no
- **Default value:** the `host` field of the OpenAPI Specification.
- **Examples:** `mybackend.acme.corp` or `mybackend.acme.corp:8080`

### `threescale_cicd_api_backend_scheme`

Defines the scheme to use to connect to the backend, overriding the `schemes` field of the OpenAPI Specification.
The resulting value is used to define the `threescale_cicd_private_base_url` variable
if missing.

- **Syntax:** `http` or `https`
- **Required:** no
- **Default value:** the first item of the `scheme` field of the OpenAPI Specification,
  defaulting to `http` if missing.
- **Example:** `https`

### `threescale_cicd_private_base_url`

Defines the 3scale Private Base URL.

- **Syntax:** `<schem>://<host>:<port>`
- **Required:** no
- **Default value:** `<threescale_cicd_api_backend_scheme>://<threescale_cicd_api_backend_hostname>`
- **Example:** `http://mybackend.acme.corp:8080`

### `threescale_cicd_apicast_policies_cors`

Allows to enable the CORS policy onto APICast gateway. In case your API should support cross-origin
and browser based invocations and you do not have included the `OPTIONS` verb on correct path into
your OpenAPI Specification file...

- **Syntax:** boolean `yes` or `no`
- **Required:** no
- **Default value:** `no`
- **Example:** `yes` if you want to activate CORS policy on APICast

### `threescale_cicd_openapi_smoketest_operation`

Defines the OpenAPI Specification method to use for smoke tests.

- **Syntax:** the `operationId` of the OpenAPI Specification method
- **Required:** no
- **Default value:** none. If this variable is undefined and if there is no operation
  flagged with `x-threescale-smoketests-operation` in the OpenAPI Specification, the
  smoke tests are skipped.
- **Example:** `GetName`

### `threescale_cicd_api_environment_name`

Prefixes all services with an environment name to prevent any name collision
when deploying the same API multiple times on the same 3scale instance.

- **Syntax:** lowercase, alphanumeric + underscore
- **Required:** no
- **Default value:** none, no prefixing is performed.
- **Examples:** `dev`, `test` or `prod`

### `threescale_cicd_validate_openapi`

Validates the OpenAPI Specification file against the official schema. To do this,
the [go-swagger](https://goswagger.io/) tool is used.

You can pre-install this tool somewhere in your `PATH`. Alternatively, you can
also point the complete path to the `swagger` command with the
`threescale_cicd_goswagger_command` extra variable.

If the tool is missing, it will be automatically downloaded from GitHub and
installed in `{{ threescale_cicd_local_bin_path }}`.

- **Syntax:** boolean (`yes`, `no`, `true`, `false`)
- **Required:** no
- **Default value:** `yes`
- **Examples:**
  - `threescale_cicd_validate_openapi=no`
  - `threescale_cicd_goswagger_command=/usr/local/bin/swagger`
  - `threescale_cicd_local_bin_path=/tmp`

### Miscellaneous variables

Miscellaneous variables defined in [defaults/main.yml](defaults/main.yml)
provide sensible defaults. Have a look at them.

## Dependencies

This role has no dependencies on other roles, but it has dependencies on:

- Ansible (at least version 2.4)
- JMESPath
- Jinja (at least version 2.8)

## Usage in Ansible Tower

If you want to use this role in Ansible Tower, the easiest way to do so is:

- to have an inventory for each of your environments (dev, test, prod, etc.)
- in those inventories, define a group (let's say `threescale`) containing
  the 3scale Admin Portal(s) of this environment
- set all the variables that depends on the environment (`threescale_cicd_wildcard_domain`, `threescale_cicd_api_environment_name`, etc.) as
  group variables
- create a playbook, committed in your GIT repository and reference it as a Project
  in Tower
- in this playbook, use the `assert` module to do some surface checks and set the variables that depends on the API being provisioned (such as `threescale_cicd_private_base_url`)
- create the corresponding Job Template

A very minimalistic playbook could be:

```yaml
---
- name: Deploy an API on a 3scale instance
  hosts: threescale
  gather_facts: no
  pre_tasks:
  - assert:
      that:
      - "git_repo is defined"
  - name: Clone the git repo containing the API Definition
    git:
      repo: '{{ git_repo }}'
      dest: '{{ playbook_dir }}/api'
      version: '{{ git_branch|default(''master'') }}'
    delegate_to: localhost
  - set_fact:
      threescale_cicd_openapi_file: '{{ playbook_dir }}/api/{{ openapi_file|default(''openapi-spec.yaml'') }}'
  roles:
  - nmasse-itix.threescale-cicd
```

Then, make sure to reference this module in your `roles/requirements.yml` file:

```yaml
---
- src: nmasse-itix.threescale-cicd
  version: 0.0.4
```

You can reference a specific version like in this example or leave the `version`
field out. This will pick the latest version available.

**Caution:** once the role has been installed locally, it will never be
automatically updated, even if you change the `version` field.

To update this role to a more recent version use:

```sh
ansible-galaxy install -f nmasse-itix.threescale-cicd,0.0.5 -p roles/
```

## License

MIT

## Author Information

- Nicolas Massé, Red Hat

[mit-badge]: https://img.shields.io/badge/license-MIT-blue.svg
[mit-link]: https://raw.githubusercontent.com/nmasse-itix/threescale-cicd/master/LICENSE
[role-badge]: https://img.shields.io/badge/role-threescale--cicd-green.svg
[galaxy-link]: https://galaxy.ansible.com/nmasse-itix/threescale-cicd/
