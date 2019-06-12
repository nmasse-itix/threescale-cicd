FROM centos:7

MAINTAINER Nicolas Masse <nmasse@redhat.com>

LABEL io.k8s.display-name="Ansible role nmasse-itix.threescale-cicd" \
      io.k8s.description="Deploys an API to 3scale API Management." \
      io.openshift.tags="3scale"

ARG THREESCALE_CICD_GIT_REPOSITORY=https://github.com/nmasse-itix/threescale-cicd.git

# This one is by convention used by the Docker Build services. 
# See https://docs.docker.com/docker-hub/builds/advanced/
ARG SOURCE_BRANCH=master

RUN yum --enablerepo=extras install -y epel-release centos-release-scl && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum install -y ansible git python27-python-pip && \
    # Remove the existing jinja2 library and its dependencies before re-installing it
    # This is mandatory to prevent any leftover from a previous install
    rm -rf /usr/lib/python2.7/site-packages/markupsafe /usr/lib/python2.7/site-packages/jinja2 && \
    scl enable python27 "pip install --install-option='--install-purelib=/usr/lib/python2.7/site-packages/' jinja2" && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    mkdir -p /opt/ansible/threescale-cicd && \
    git clone -b ${SOURCE_BRANCH} -- ${THREESCALE_CICD_GIT_REPOSITORY} /opt/ansible/threescale-cicd && \
    cd /opt/ansible/threescale-cicd/support/docker && mkdir api && \
    ansible-playbook install.yaml

WORKDIR /opt/ansible/threescale-cicd/support/docker
VOLUME [ "/opt/ansible/threescale-cicd/support/docker/api" ]

ENTRYPOINT [ "/usr/bin/ansible-playbook", "deploy-api.yaml" ]
CMD [ ]
