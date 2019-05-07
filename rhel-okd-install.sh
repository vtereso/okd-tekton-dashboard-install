#!/usr/bin/env bash

# Source variables
. env.sh

# Clone repo
OPENSHIFT_DIR="../openshift-ansible"
git clone -b ${RELEASE} https://github.com/openshift/openshift-ansible.git ${OPENSHIFT_DIR}


# Replace variables stubs
envsubst < hosts.ini > /tmp/hosts.ini
mv -f /tmp/hosts.ini hosts.ini

# Create password file used within OKD install/playbook
mkdir -p ${HTPASSWD_FILE%/*}
touch ${HTPASSWD_FILE}

# Run OKD install
ansible-playbook -i hosts.ini ${OPENSHIFT_DIR}/playbooks/prerequisites.yml
ansible-playbook -i hosts.ini ${OPENSHIFT_DIR}/playbooks/deploy_cluster.yml

# Adds username/password
htpasswd -b ${HTPASSWD_FILE} ${USERNAME} ${PASSWORD}

# Add permissions to new user
oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

# Login
echo "******"
echo "* Your console is https://console.$HOST:$API_PORT"
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "*"
echo "* Login using:"
echo "*"
echo "$ oc login -u ${USERNAME} -p ${PASSWORD} https://console.$HOST:$API_PORT/"
echo "******"
oc login -u ${USERNAME} -p ${PASSWORD} https://$HOST:$API_PORT/
./dashboard-install.sh
