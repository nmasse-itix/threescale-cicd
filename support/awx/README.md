# Using this Ansible role from AWX / Ansible Tower

Ansible has powerful concepts to separate the HOW (how to deploy an API) from
the WHERE (where to deploy an API). Ansible Tower / AWX can push this to the
next level by enforcing RBAC, having audit logs and providing to developers
*Deploy an API to 3scale* as-a-service.

You can have a look at those two blog posts that present this approach in greater
details:

- [Integrating Ansible with Jenkins in a CI/CD process](https://www.redhat.com/en/blog/integrating-ansible-jenkins-cicd-process)
- [Take Ansible and Jenkins Integration to the next level: CI/CD with Ansible Tower](https://www.redhat.com/en/blog/take-ansible-and-jenkins-integration-next-level-cicd-ansible-tower)

## Setup

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
tower-cli send -h tower.hostname -u admin -p secret support/awx/tower-assets.yaml
```

You can now provision an API from your favourite CI/CD tool. For example, from Jenkins you could use:

```groovy
def towerExtraVars = [
    git_repository: "https://github.com/nmasse-itix/rhte-api.git",
    git_ref: "master",
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

## Advanced usage

If you need to customize the playbooks, the inventory or both, you can follow this guide:

- define an inventory for each of your environments (dev, test, prod, etc.)
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
  version: 1.1.0
```

You can reference a specific version like in this example or leave the `version`
field out. This will pick the latest version available.

**Caution:** once the role has been installed locally, it will never be
automatically updated, even if you change the `version` field.

To update this role to a more recent version use:

```sh
ansible-galaxy install -f nmasse-itix.threescale-cicd,1.1.0 -p roles/
```
