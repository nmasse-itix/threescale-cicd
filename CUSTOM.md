# How to customize the behavior of this role

## Speed-up the deployments

Go save precious seconds during deployments, you can override the
`threescale_cicd_throttling` variable.

**WARNING:** the throttling is there to let the 3scale Admin Portal
digest your changes. Use at your own risk!

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_throttling: 0
  roles:
  - nmasse-itix.threescale-cicd
```

## Customize the 3scale Service display name

To have the 3scale Service display name generated from a different pattern
(`ENV[name-vX.Y]` in the following example), override the `threescale_cicd_api_name`
variable.

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    myenv: TEST
    threescale_cicd_api_name: '{{ myenv }}[{{ threescale_cicd_api_default_name }}-v{{ threescale_cicd_api_version }}]'
  roles:
  - nmasse-itix.threescale-cicd
```

## Provision a custom policy chain

To provision a custom policy chain, you would need to store your custom policy
in a file and reference it from the `threescale_cicd_policies_to_update` variable.

**custom-policy-chain.json**:

```json
[
  { "name": "cors", "version": "builtin", "configuration": {}, "enabled": true },
  { "name": "headers", "version": "builtin", "configuration": { "request": [ { "op": "set", "header": "X-TEST", "value_type": "plain", "value": "foo" } ] }, "enabled": true },
  { "name": "apicast", "version": "builtin", "configuration": {}, "enabled": true }
]
```

**deploy-api.yaml**:

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_policies_to_update: '{{ lookup(''file'', playbook_dir ~ ''/custom-policy-chain.json'')|from_json }}'
  roles:
  - nmasse-itix.threescale-cicd
```

## Implement the url_rewriting policy

If you want to deploy an API that is not yet implemented and would like to route requests to a mock such as [Microcks](http://microcks.github.io/), you will need to implement the `url_rewriting` policy.

The `url_rewriting` policy will help you add a prefix to the URL before calling the Mock server:
`GET /beers` becomes `GET /rest/Echo+API/1.0/beers`.

**custom-policy-chain.json.j2**:

```json
[
  { "name": "apicast", "version": "builtin", "configuration": {}, "enabled": true },
  { "name": "url_rewriting", "version": "builtin", "configuration": { "query_args_commands": [], "commands": [ { "op": "sub", "regex": "^/", "replace": "/rest/{{ api_name|urlencode }}/{{ threescale_cicd_api_version }}/" } ] }, "enabled": true }
]
```

**deploy-api.yaml**:

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    api_name: Echo API
    threescale_cicd_policies_to_update: '{{ lookup(''template'', playbook_dir ~ ''/custom-policy-chain.json.j2'') }}'
  roles:
  - nmasse-itix.threescale-cicd
```

## Choose the Account in which the smoke test application is created

By default, the playbook will create a client application in the default first
account of your tenant (the Account that contains "john"). But you can choose
the Account to use by overriding the `threescale_cicd_default_account_id`
variable.

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_default_account_id: '2445582535751'
  roles:
  - nmasse-itix.threescale-cicd
```

You can find the Account id by navigating to **Audience** > **Accounts** >
**Listing** and clicking on the Account of your choice. The ID is the
last part of the URL (`/buyers/accounts/{id}`).

## Override the default versioning scheme

By default, the playbook will version your APIs based on the
[Semantic Versioning](https://semver.org/) scheme. This means minor versions
(1.0, 1.1, 1.2, etc) will be deployed continously to the same 3scale service.
Major versions are deployed side-by-side (one service for each major version).

If you want to deploy all versions to the same service, no matter what:

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_api_version_major: '0' # or whatever you want as long as it remains static
  roles:
  - nmasse-itix.threescale-cicd
```

If you want to release minor versions as major versions:

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_api_version_major: '{{ threescale_cicd_api_version_components|first }}-{{ threescale_cicd_api_version_components[1] if threescale_cicd_api_version_components|length > 1 else 0 }}'
  roles:
  - nmasse-itix.threescale-cicd
```
