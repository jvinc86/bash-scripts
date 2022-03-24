#!/bin/bash
# Update Repo Index
apt update -y && apt upgrade -y

# Set Timezone
timedatectl set-timezone Europe/Paris
# timedatectl set-local-rtc 1 --adjust-system-clock

# Set Hostname
serveur=jenkins-slave
hostnamectl set-hostname $serveur
sed -i "s/debian11-template/$serveur/g" /etc/hosts

# Set NTP IDN-configuration
systemctl stop systemd-timesyncd
systemctl disable systemd-timesyncd
apt install -y ntp
sed -i -e 's/pool 0.debian.pool.ntp.org iburst/server 192.168.43.252 iburst/g' -e '/pool 1.debian.pool.ntp.org iburst/d' -e '/pool 2.debian.pool.ntp.org iburst/d' -e '/pool 3.debian.pool.ntp.org iburst/d' /etc/ntp.conf
systemctl restart ntp
systemctl enable ntp

# Set sshd_config
sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'
sed -i -e 's/^PasswordAuthentication no/PasswordAuthentication yes/' -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# User for Ansible configuration
usuario=ansibleadmin
id -u $usuario &>/dev/null || (sudo useradd -U $usuario -m -s /bin/bash -G sudo && echo "$usuario:123" | sudo chpasswd  && echo "$usuario ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers)

# -------- Proxy ----------
p1='http_proxy=http://proxy.dev.idnomic.com:3128'
p2='https_proxy=http://proxy.dev.idnomic.com:3128'
p3='ftp_proxy=http://proxy.dev.idnomic.com:3128'
p4='no_proxy=dev.opentrust.com,dev.idnomic.com,localhost,127.0.0.1'
p5='HTTP_PROXY=http://proxy.dev.idnomic.com:3128'
p6='HTTPS_PROXY=http://proxy.dev.idnomic.com:3128'
p7='FTP_PROXY=http://proxy.dev.idnomic.com:3128'
p8='NO_PROXY=dev.opentrust.com,dev.idnomic.com,localhost,127.0.0.1'
adding_proxy() {
  grep -qxF "export $1" /etc/profile.d/proxy.sh || echo "export $1" | tee -a /etc/profile.d/proxy.sh
}
adding_proxy $p1 && adding_proxy $p2 && adding_proxy $p3 && adding_proxy $p4
adding_proxy $p5 && adding_proxy $p6 && adding_proxy $p7 && adding_proxy $p8
source /etc/profile.d/proxy.sh

#----- Proxy for apt -----------
prx='http://proxy.dev.idnomic.com:3128'
adding_proxy_for_apt() {
  grep -qxF "Acquire::http::proxy \"$1\";" /etc/apt/apt.conf || echo "Acquire::http::proxy \"$1\";" | tee -a /etc/apt/apt.conf
  grep -qxF "Acquire::https::proxy \"$1\";" /etc/apt/apt.conf || echo "Acquire::https::proxy \"$1\";" | tee -a /etc/apt/apt.conf
  grep -qxF "Acquire::ftp::proxy \"$1\";" /etc/apt/apt.conf || echo "Acquire::ftp::proxy \"$1\";" | tee -a /etc/apt/apt.conf
}
adding_proxy_for_apt $prx

# Install utilities
apt install -y sudo vim curl wget tree gnupg2 gnupg tmux ca-certificates

# Install Java openjdk 11.0.9.1
# sudo apt install openjdk-11-jdk
wget -P /tmp https://openjdk-sources.osci.io/openjdk11/openjdk-11.0.9.1-ga.tar.xz
tar -xf /tmp/openjdk-11.0.9.1-ga.tar.xz -C /opt
ln -s /opt/jdk-11.0.9.1-ga /opt/java-11
export JAVA_HOME=/opt/java-11
export PATH="$JAVA_HOME/bin:$PATH"

# Docker Installation
apt remove -y docker docker.io containerd runc
apt install -y ca-certificates curl gnupg lsb-release apt-transport-https
apt autoremove -y
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io
usuario=dockeradmin
useradd -U $usuario -m -s /bin/bash -G sudo
echo "$usuario:123" | chpasswd
echo "$usuario ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
usermod -aG docker $usuario

# Maven Installation
wget -P /tmp https://dlcdn.apache.org/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz
tar -xf /tmp/apache-maven-3.8.5-bin.tar.gz -C /opt
ln -s /opt/apache-maven-3.8.5 /opt/maven

# Git Installation
apt install -y git

# Python3 Installation
apt install -y python3

# JQ Installation - Lightweight flexible CLI JSON processor
apt install -y jq
