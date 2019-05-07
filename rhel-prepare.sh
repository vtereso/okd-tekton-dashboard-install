#!/usr/bin/env bash

# Source variables
. env.sh

# Passwordless SSH into self
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Install packages
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
policycoreutils-python \
docker-1.13.1 \
wget \
git \
yum-utils \
setroubleshoot \
dnsmasq \
net-tools \
bind-utils \
iptables-services \
bridge-utils \
bash-completion \
kexec-tools \
sos \
psacct

# Get updates
yum update -y

# Install ansible
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install ansible pyOpenSSL

# Enable SE linux
cat << EOD > /etc/selinux/config
SELINUX=enforcing
SELINUXTYPE=targeted
EOD

# Relabel the file-system for SELinux
touch /.autorelabel

# Start and enable NetworkManager
systemctl enable NetworkManager && systemctl start NetworkManager

# Enable ipv4 forward
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf

# Enable and start dnsmasq
systemctl enable dnsmasq && service dnsmasq start

# Enable and start docker
systemctl enable docker && systemctl start docker

# Update bash PATH
echo "export PATH=/bin:/sbin:$PATH" >> .bashrc

# Update bashrc to include `/bin:/sbin` in PATH
cat << EOD > ~/.bashrc
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
export PATH=/bin:/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
EOD

# Enable fusefs
sudo setsebool -P virt_sandbox_use_fusefs on && sudo setsebool -P virt_use_fusefs on

# Reboot
reboot
