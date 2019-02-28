# Using this Ansible role from Jenkins

To use this role from Jenkins, you will need to:

- Create the Jenkins Slave image for Ansible
- Install the Ansible Jenkins plugin
- Create the pipeline that calls Ansible

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
