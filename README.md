# OKD Tekton-Dashboard
This repository provides utility scripts to:
- Automate the tekton-dashboard installation on OKD (as well as all prerequisites)
- Install OKD with single VM configuration (See: https://docs.openshift.com/container-platform/3.11/install/prerequisites.html)

Please note this repository has been only been tested on RHEL7 VMs AND assumes `subscription-manager` has been appropriately configured. To use these scripts, update the `$DOCKER_USERNAME` and `$DOCKER_PASSWORD` parameters within `env.sh` file as the tekton-dashboard uses ko and will publish to your dockerhub account, otherwise you will be prompted for them. Specific to OKD installation, you may also optionally update the `$USERNAME` and `$PASSWORD` variables, which correspond to your OKD login credentials. These OKD credentials are stored at `$HTPASSWD_FILE`. If the values are not provided, you will be prompted.

### Install OKD and Dashboard
To install OKD, run the `rhel-prepare.sh` file to ensure you have the necessary prequisites followed by the `rhel-okd-install.sh` for OKD install. The prepare script will reboot the VM so you will need to wait a moment to ssh back to run the installer. At the end of OKD installation script, `dashboard-install.sh` is automatically executed to install the dashboard.

### Install Dashboard AND Prequisite Operators
If you already have OKD installed and just want to install the tekton-dashboard, you can run `dashboard-install.sh`. This script assumes that you do not have Knative/Istio/OLM/Tekton installed, behavior is undefined/unknown otherwise.