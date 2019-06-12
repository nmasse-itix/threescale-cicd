FROM openshift/jenkins-slave-base-centos7:v3.11

MAINTAINER Nicolas Masse <nmasse@redhat.com>

# Labels consumed by Red Hat build service
LABEL name="openshift3/jenkins-agent-ansible-26-centos7" \
        version="v3.11" \
        architecture="x86_64" \
        io.k8s.display-name="Jenkins Agent Ansible" \
        io.k8s.description="The jenkins agent ansible image has the Ansible engine on top of the jenkins slave base image." \
        io.openshift.tags="openshift,jenkins,agent,ansible"

USER root

# Set a safe value for the temporary directory. Otherwise the ansible-playbook command fails when run from a jenkins slave:
# AnsibleError: Unable to create local directories(/home/jenkins/.ansible/tmp): [Errno 13] Permission denied: '/home/jenkins/.ansible/tmp'
ENV DEFAULT_LOCAL_TMP=/tmp

RUN yum install -y epel-release && \
    yum install -y 'ansible >= 2.6' && \
    yum install -y python27-python-pip && \
    # Remove the existing jinja2 library and its dependencies before re-installing it
    # This is mandatory to prevent any leftover from a previous install
    rm -rf /usr/lib/python2.7/site-packages/markupsafe /usr/lib/python2.7/site-packages/jinja2 && \
    scl enable python27 "pip install --install-option='--install-purelib=/usr/lib/python2.7/site-packages/' jinja2" && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    chown -R 1001:0 $HOME && \
    chmod -R g+rw $HOME

USER 1001
