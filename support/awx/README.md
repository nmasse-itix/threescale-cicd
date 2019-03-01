# Using this Ansible role from AWX / Ansible Tower

Install the Tower CLI:

```sh
sudo yum install python2-ansible-tower-cli
```

Review the [tower-assets.yaml](tower-assets.yaml) and adjust it to match your environment.
Search for those placeholders to replace:

- YOUR_ACCESS_TOKEN
- CLIENT_ID
- CLIENT_SECRET
- SSO_HOST
- REALM
- TENANT

Use the tower-cli to create the resources in Tower:

```sh
tower-cli send -h ansible.app.itix.fr -u admin -p secret support/awx/tower-assets.yaml
```

You can now provision an API from your favourite CI/CD tool. For example, from Jenkins you could use:

```groovy
def towerExtraVars = [
    git_repo: "https://github.com/nmasse-itix/rhte-api.git",
    git_branch: "master",
    openapi_file: "openapi-spec.yaml",
    threescale_cicd_api_base_system_name: "event_api",
    threescale_cicd_private_base_url: "https://echo-api.3scale.net",
    threescale_cicd_api_environment_name: "prod",
    threescale_cicd_wildcard_domain: "prod.app.openshift.test"
]

ansibleTower towerServer: "tower",
             inventory: "3scale",
             jobTemplate: "Deploy an API to 3scale",
             extraVars: JsonOutput.toJson(towerExtraVars)
```
