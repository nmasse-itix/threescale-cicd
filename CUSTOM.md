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
