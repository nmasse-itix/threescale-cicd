FROM openshift/origin-base:v3.11

MAINTAINER Nicolas Masse <nmasse@redhat.com>

LABEL io.k8s.display-name="OpenShift Custom builder for Ansible role nmasse-itix.threescale-cicd" \
      io.k8s.description="Deploys an API to 3scale API Management." \
      io.openshift.tags="builder,3scale"

ARG THREESCALE_CICD_GIT_REPOSITORY=https://github.com/nmasse-itix/threescale-cicd.git
ARG THREESCALE_CICD_GIT_BRANCH=master

RUN yum install -y centos-release-scl && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum install -y ansible git python27-python-pip && \
    scl enable python27 "pip install --install-option='--install-purelib=/usr/lib/python2.7/site-packages/' jinja2" && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    mkdir -p /opt/ansible/threescale-cicd && \
    git clone -b ${THREESCALE_CICD_GIT_BRANCH} -- ${THREESCALE_CICD_GIT_REPOSITORY} /opt/ansible/threescale-cicd && \
    cd /opt/ansible/threescale-cicd/support/openshift && mkdir api && \
    ansible-playbook install.yaml

WORKDIR /opt/ansible/threescale-cicd/support/openshift
VOLUME [ "/opt/ansible/threescale-cicd/support/docker/api" ]

ENTRYPOINT [ "/usr/bin/ansible-playbook", "deploy-api.yaml" ]
CMD [ ]
