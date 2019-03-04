# Using this Ansible role from Jenkins

You can use this Ansible role from Jenkins to include 3scale in your Continuous
Deployment pipeline.

To use this role from Jenkins, you will need to:

- Create the Jenkins Slave image for Ansible
- Install the Ansible Jenkins plugin
- Create the pipeline that calls Ansible
- Give your 3scale Access Token to Jenkins
- Run the pipeline!

## Create the Jenkins Slave image for Ansible

You can create the Jenkins Slave image for Ansible by executing the following command **in the same project as your Jenkins master**:

```sh
oc create -f https://raw.githubusercontent.com/nmasse-itix/threescale-cicd/master/support/jenkins/jenkins-slave-template-centos.yaml
oc new-app --template=jenkins-slave-template
```

Alternatively, if you are a Red Hat customer, you can build your images based on RHEL with the following commands:

```sh
oc create -f https://raw.githubusercontent.com/nmasse-itix/threescale-cicd/master/support/jenkins/jenkins-slave-template-rhel.yaml
oc new-app --template=jenkins-slave-template
```

Wait for the build to finish:

```sh
oc logs -f bc/jenkins-ansible-slave
```

## Install the Ansible Jenkins plugin

- Connect to your Jenkins instance
- Click **Manage Jenkins** > **Manage Plugins**
- Go to the **Available** tab
- In the **Filter** text field, type `Ansible`
- In the list, find the **Ansible plugin** and check its box in the **Enabled** column
- Click **Install without restart**

## Create the pipeline that calls Ansible

You can create the Jenkins pipeline that calls Ansible with the following command:

```sh
oc create -f https://raw.githubusercontent.com/nmasse-itix/threescale-cicd/master/support/jenkins/deploy-3scale-api-pipeline.yaml
oc new-app --template=deploy-3scale-api
```

## Give your 3scale Access Token to Jenkins

You can give your 3scale Access Token to Jenkins with the following command:

```sh
oc create secret generic 3scale-access-token --from-literal="secrettext=1234...5678"
oc label secret 3scale-access-token credential.sync.jenkins.openshift.io=true
```

Replace `1234...5678` with your actual 3scale token. Do not change the name of the key (`secrettext=`) since is used by the OpenShift Jenkins Sync plugin to create the correct credentials in Jenkins.

If you plan to deploy APIs secured with OpenID Connect, also give your *OpenID Connect Issuer Endpoint* to Jenkins with:

```sh
oc create secret generic oidc-issuer-endpoint --from-literal="secrettext=https://<client_id>:<client_secret>@<host>/auth/realms/<realm>"
oc label secret oidc-issuer-endpoint credential.sync.jenkins.openshift.io=true
```

## Run the pipeline!

- Connect to your Jenkins master
- Click on the name of your OpenShift project
- Click on **deploy-3scale-api**
- Click on **Build with Parameters**
- For the first run, do not enter any information. This step is mandatory to [initialize the pipeline parameters](https://dev.to/pencillr/jenkins-pipelines-and-their-dirty-secrets-2).
- Wait for the pipeline to finish. **An error is normal at this step.**
- Click on **Build with Parameters**
- This time you can fill-in the relevant information:
  - **THREESCALE_CICD_ACCESS_TOKEN** is your 3scale Access Token (`*-3scale-access-token`)
  - **THREESCALE_CICD_SSO_ISSUER_ENDPOINT** is your OpenID Connect Issuer Endpoint (`*-oidc-issuer-endpoint`, required only if you are deploying APIs secured with OpenID Connect)
  - **THREESCALE_PORTAL_HOSTNAME** is the hostname of your 3scale admin portal (`<tenant>-admin.3scale.net`)
  - **GIT_REPOSITORY** is the URL of the GIT repository that contains the OpenAPI Specification (`https://github.com/nmasse-itix/rhte-api.git`)
  - **GIT_BRANCH** is the branch or tag of the GIT repository that contains the OpenAPI Specification (`master`)
  - **OPENAPI_FILE** is the path to the OpenAPI Specification file in the GIT repository (`openapi-spec.yaml`)
  - **THREESCALE_CICD_PRIVATE_BASE_URL** is the URL of your backend to protect with 3scale (`https://echo-api.3scale.net`)

## Use this pipeline from another pipeline

When you need to provision an API from within a Jenkins Pipeline, you can use the `build` step to call the `deploy-3scale-api` Pipeline:

```groovy
build(job: '<namespace>-deploy-3scale-api',
      parameters: [ credentials(name: 'THREESCALE_CICD_ACCESS_TOKEN', value: '<namespace>-3scale-access-token'),
                    credentials(name: 'THREESCALE_CICD_SSO_ISSUER_ENDPOINT', value: '<namespace>-oidc-issuer-endpoint'),
                    string(name: 'THREESCALE_PORTAL_HOSTNAME', value: '<tenant>-admin.3scale.net'),
                    string(name: 'GIT_REPOSITORY', value: 'https://github.com/nmasse-itix/rhte-api.git'),
                    string(name: 'GIT_BRANCH', value: 'master'),
                    string(name: 'OPENAPI_FILE', value: 'openapi-spec.yaml'),
                    string(name: 'THREESCALE_CICD_PRIVATE_BASE_URL', value: 'https://echo-api.3scale.net') ])
```
