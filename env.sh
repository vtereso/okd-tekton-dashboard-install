# Fill in, else prompted later
export DOCKER_USERNAME=''
export DOCKER_PASSWORD=''

# Optionally configure
export INSTALL_NAMESPACE="default"
export IP=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
export HOST="${IP}.nip.io"
export HTPASSWD_FILE='/etc/origin/master/htpasswd'
export USERNAME=${USERNAME:="$(whoami)"}
export PASSWORD=${PASSWORD:='password'}
export API_PORT='7443'
export RELEASE='release-3.11'
export KO_DOCKER_REPO="docker.io/${DOCKER_USERNAME}"
export GO_VERSION='1.12.4'

# Used within Knative operator
export KUBE_SSH_USER=${USERNAME}
export KUBE_SSH_KEY='~/.ssh/id_rsa'

# Used to test Pipelineruns
export DASHBOARD_SERVICE_ACCOUNT='default'
export APP_NAME='hello-world'
export APP_GIT_REPO='https://github.com/a-roberts/knative-helloworld'
