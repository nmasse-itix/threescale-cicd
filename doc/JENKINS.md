# Using this Ansible role from Jenkins

To use this role from Jenkins, you will need to:

- Create a custom Jenkins Slave image
- Register this image in the Jenkins configuration
- Commit your inventory and playbooks in a GIT repository
- Create an Ansible Vault to store your 3scale Access Token and OIDC issuer endpoint
- Create a Jenkins pipeline

## Create a custom Jenkins Slave image

First, create a Dockerfile containing:

```dockerfile
FROM openshift3/jenkins-slave-base-rhel7:v3.11

MAINTAINER Nicolas Masse <nmasse@redhat.com>

# Labels consumed by Red Hat build service
LABEL name="openshift3/jenkins-agent-ansible-26-rhel7" \
      version="3.11" \
      architecture="x86_64" \
      io.k8s.display-name="Jenkins Agent Ansible" \
      io.k8s.description="The jenkins agent ansible image has the Ansible engine on top of the jenkins slave base image." \
      io.openshift.tags="openshift,jenkins,agent,ansible"

USER root
RUN yum install -y --enablerepo=rhel-7-server-ansible-2.6-rpms ansible && \
    yum install -y --enablerepo=rhel-server-rhscl-7-rpms python27-python-pip && \
    scl enable python27 "pip install --install-option='--install-purelib=/usr/lib/python2.7/site-packages/' jinja2" && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    chown -R 1001:0 $HOME && \
    chmod -R g+rw $HOME

USER 1001
```

Create an OpenShift project to hold the image and BuildConfig we will create:

```sh
oc new-project jenkins-ansible
```

Then, import the Jenkins base image in the current project:

```sh
oc import-image jenkins-slave-base-rhel7:v3.11 --from=registry.access.redhat.com/openshift3/jenkins-slave-base-rhel7:v3.11 --scheduled --confirm
```

Replace the `v3.11` tag with the OpenShift version you are currently running.

Create a BuildConfig based on this ImageStream and the Dockerfile created before.

```sh
oc new-build -D - --name=jenkins-agent-ansible-26-rhel7 --image-stream=jenkins-slave-base-rhel7:v3.11 --to=jenkins-agent-ansible-26-rhel7:latest < Dockerfile
```

Wait for the BuildConfig to complete and tag the new image in the `openshift` namespace:

```sh
oc tag jenkins-agent-ansible-26-rhel7:latest openshift/jenkins-agent-ansible-26-rhel7:latest
```

## Register the image in the Jenkins configuration

- Connect to your Jenkins instance
- Click **Manage Jenkins** > **Configure System**
- Scroll down to the **Cloud** section
- Scroll down and click **Add Pod Template** and select **Kubernetes Pod Template**
- Fill in the Kubernetes Pod Template with the following information:
  - **Name**: `ansible`
  - **Labels**: `ansible`
  - **Timeout in seconds for Jenkins connection**: `100`
- Click **Add Container** and select **Container Template**
- Fill in the Container Template with the following information:
  - **Name**: `jnlp`
  - **Docker image**: `docker-registry.default.svc:5000/openshift/jenkins-agent-ansible-26-rhel7:latest`
  - **Always pull image**: *checked*
  - **Working directory**: `/tmp`
  - **Command to run**: *empty*
  - **Arguments to pass to the command**: `${computer.jnlpmac} ${computer.name}`
  - **Allocate pseudo-TTY**: *unchecked*
- Scroll down and click **Save**
