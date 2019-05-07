#!/usr/bin/env bash

# source env
. env.sh

# Create known host entry
# ssh -o StrictHostKeyChecking=no ${KUBE_SSH_USER}@${HOST} ':'
ssh-keyscan ${HOST} >> ~/.ssh/known_hosts

# Knative Operator - Installs istio, knative, and OLM
KNATIVE_DIR="../knative-operators"
git clone https://github.com/openshift-cloud-functions/knative-operators ${KNATIVE_DIR}
oc login -u ${USERNAME} -p ${PASSWORD} https://$HOST:$API_PORT/
${KNATIVE_DIR}/etc/scripts/install.sh -q

# Tektond Operator
TEKTON_DIR="../tektoncd-pipeline-operator"
git clone https://github.com/openshift/tektoncd-pipeline-operator ${TEKTON_DIR}
kubectl apply -f ${TEKTON_DIR}/deploy/crds/*_crd.yaml
kubectl apply -f ${TEKTON_DIR}/deploy/ -n tekton-pipelines
kubectl apply -f ${TEKTON_DIR}/deploy/crds/*_cr.yaml

go version # Check if Go is installed/in path
# Install Go, if DNE
if [[ $? != 0 ]];then
    echo "Go not installed, pulling latest stable"
    wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz -O go-${GO_VERSION}.tar.gz
    tar -xzf go-${GO_VERSION}.tar.gz
    mv go /usr/local
    echo 'export GOROOT=/usr/local/go' >> ~/.bash_profile
    echo 'export GOPATH=$HOME/go' >> ~/.bash_profile
    echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> ~/.bash_profile
    source ~/.bash_profile
    go version
    if [[ $? != 0 ]];then
        echo "Error installing or configuring Go. Exiting..."
        exit 1
    fi
fi

# Install Ko
go get github.com/google/ko/cmd/ko
# Install dep
go get -u github.com/golang/dep/cmd/dep

# If DOCKER_USERNAME not provided
if [[ -z ${DOCKER_USERNAME} ]];then
    echo "No value found for \$DOCKER_USERNAME. Please enter now."
    while [[ -z ${DOCKER_USERNAME} ]];do
        read -p -r -s "DOCKER_USERNAME=" DOCKER_USERNAME
    done
    # Write back to env.sh
    sed -i 's|DOCKER_USERNAME=.*|DOCKER_USERNAME="'${DOCKER_USERNAME}'"|'env.sh
fi

# If DOCKER_PASSWORD not provided
if [[ -z ${DOCKER_PASSWORD} ]];then
    echo "No value found for \$DOCKER_PASSWORD. Please enter now."
    while [[ -z ${DOCKER_PASSWORD} ]];do
        read -p -r -s "DOCKER_PASSWORD=" DOCKER_PASSWORD
    done
    # Write back to env.sh
    sed -i 's|DOCKER_PASSWORD=.*|DOCKER_PASSWORD="'${DOCKER_PASSWORD}'"|'env.sh
fi

# Docker login
#docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
cat env.sh | sed -n 's|.*DOCKER_PASSWORD="\(.*\)"|\1|p' | docker login --username ${DOCKER_USERNAME} --password-stdin

# Dashboard Install
DASHBOARD_DIR="$HOME/go/src/github.com/tektoncd/dashboard"
git clone https://github.com/tektoncd/dashboard ${DASHBOARD_DIR}
pushd ${DASHBOARD_DIR}
dep ensure -v
ko apply -f config -n ${INSTALL_NAMESPACE}
popd

# Verify Dashboard is up
# resp=$(kubectl describe pods -n ${INSTALL_NAMESPACE} -l app=webhooks-extension)
# while [[ -z ${resp} ]];do
#     resp=$(kubectl describe pods -n ${INSTALL_NAMESPACE} -l app=webhooks-extension)
#     sleep 1
# done
# ip=$(echo "${resp}" | awk '/Readiness:/ {print $2;exit}')
# readinessProbe=$(echo "${resp}" | awk '/IP:/ {print $3;exit}' | sed 's|//:|//'$ip':|')

# while [[ $(curl ${readinessProbe} -w %{http_code}) != 204 ]];do
#     sleep 1
# done


# # Make SA privileged to enable hostPath volumes (used within pipelineruns)
# oc adm policy add-scc-to-user privileged system:serviceaccount:${INSTALL_NAMESPACE}:${DASHBOARD_SERVICE_ACCOUNT}
# # Apply sample pipeline and create run
# PIPELINE_HOTEL="$HOME/go/src/github.com/pipeline-hotel/example-pipelines"
# # Fork of pipeline-hotel/example-pipelines with variable stubs
# git clone https://github.com/vtereso/example-pipelines ${PIPELINE_HOTEL}
# pushd ${PIPELINE_HOTEL}
# # Create 'registry-secret' tekton registry secret and patch to dashboard SA
# ./create-tekton-docker-secret.sh
# # Create pipeline and related CRDs
# kubectl apply -f config -n ${INSTALL_NAMESPACE}
# # Replace variables stubs
# envsubst < runner.yaml > /tmp/runner.yaml
# mv -f /tmp/runner.yaml runner.yaml

# # Create PVs for TaskPods
# for i in {1..10};do
# DIRNAME="vol$i"
# mkdir -p /mnt/data/$DIRNAME 
# chcon -Rt svirt_sandbox_file_t /mnt/data/$DIRNAME
# chmod 777 /mnt/data/$DIRNAME
# cat << PV | oc create -f -
# apiVersion: v1
# kind: PersistentVolume
# metadata:
#   name: vol${i}
# spec:
#   capacity:
#     storage: 10Gi 
#   accessModes:
#     - ReadWriteOnce     
#     - ReadWriteMany
#   persistentVolumeReclaimPolicy: Recycle
#   hostPath:
#     path: /mnt/data/vol${i}
# PV
# done
# # Create pipelinerun
# kubectl apply -f runner.yaml
# popd

# Install Dashboard webhooks
# EXPERIMENTAL_DASHBOARD_REPO="$HOME/go/src/github.com/tektoncd/experimental"
# git clone https://github.com/tektoncd/experimental ${EXPERIMENTAL_DASHBOARD_REPO}
# pushd ${EXPERIMENTAL_DASHBOARD_REPO}/webhooks-extension
# dep ensure -v
# ko apply -f config -n ${INSTALL_NAMESPACE}
# popd