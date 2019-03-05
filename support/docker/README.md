# Using this Ansible role from Docker

You can use this Ansible role as a container image and provision an API in
3scale very quickly.

You would first need to provision your 3scale Admin Portal hostname, access token
and optionally the Red Hat SSO Issuer Endpoint in the same format as a Kubernetes
secret:

```sh
mkdir -p /tmp/secrets
cat > /tmp/secrets/hostname <<EOF
TENANT-admin.3scale.net
EOF
cat > /tmp/secrets/access_token <<EOF
1234..5678
EOF
```

If your API is secured with OpenID Connect, you will need to provision the Red Hat
SSO Issuer Endpoint as well:

```sh
cat > /tmp/secrets/sso_issuer_endpoint <<EOF
https://CLIENT_ID:CLIENT_SECRET@HOSTNAME/auth/realms/REALM
EOF
```

You can then run this Ansible role as a Docker container:

```sh
docker run -it --rm --name threescale-cicd -v /tmp/secrets:/tmp/secrets:ro docker.io/nmasse/threescale-cicd:stable -e git_repository=https://github.com/nmasse-itix/rhte-api.git -e git_ref=master -e threescale_cicd_openapi_file=openapi-spec.yaml -e threescale_cicd_api_base_system_name=echo-api -e threescale_cicd_private_base_url=https://echo-api.3scale.net
```

This command is composed of the following arguments:

- `-it` will run the Ansible command interactively
- `--rm` will remove the container once finished
- `--name threescale-cicd` will give a friendly name to the created container
- `-v /tmp/secrets:/tmp/secrets:ro` will mount the secrets created above inside the container
- `docker.io/nmasse/threescale-cicd:stable` is the name of the pre-built docker image.
  `stable` is the latest released version. `master` is the development version.
  You can also target a specific version with for instance `1.0.0`.
- `-e git_repository=https://github.com/nmasse-itix/rhte-api.git` will checkout the
  forementioned GIT repository to extract the OpenAPI Specification file.
- `-e git_ref=master` will checkout this specific branch or tag of the GIT repository.
- `-e threescale_cicd_openapi_file=openapi-spec.yaml` sets the path to the OpenAPI
  Specification file inside the GIT repository.
- `-e threescale_cicd_api_base_system_name=echo-api` sets the base name that will be used
  to generate the 3scale system_name.
- `-e threescale_cicd_private_base_url=https://echo-api.3scale.net` sets the 3scale
  Private Base URL.

If your GIT repository is already checked out somewhere, you can re-use your
local copy by removing the `-e git_*` arguments and mounting your GIT repository
under `/opt/ansible/threescale-cicd/support/docker/api`.

```sh
docker run -it --rm --name threescale-cicd -v /path/to/git:/opt/ansible/threescale-cicd/support/docker/api:ro -v /tmp/secrets:/tmp/secrets:ro docker.io/nmasse/threescale-cicd:stable -e threescale_cicd_openapi_file=path/to/openapi-spec.yaml -e threescale_cicd_api_base_system_name=echo-api -e threescale_cicd_private_base_url=https://echo-api.3scale.net
```
