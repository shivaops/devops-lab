#!/bin/bash
# author  : Shiva Naik
# email   : shivanaik.it@gmail.com
# Mobile  : +973-38053730 Bahrain / +91-9820234089 India
# GitHub: 	 https://github.com/ShivaOps
# LinkedIn:  https://www.linkedin.com/in/shivaops/
# Portfolio: https://shivaops.github.io/
# YouTube:   https://www.youtube.com/@ShivaOps-AI

# Stop immediately if any command fails.
set -e

# Print commands while executing. Useful for troubleshooting Vagrant provisioning logs.
set -x

echo "************   PROVISION MACHINE  JENKINS ************"

# -------------------------------------------------------------------
# Step 1: Update apt package index
# -------------------------------------------------------------------
sudo apt-get update

# -------------------------------------------------------------------
# Step 2: Prepare SSH key for future Jenkins automation
# Jenkins VM will later connect to Docker/Kubernetes/Ansible machines.
# -------------------------------------------------------------------
mkdir -p /home/vagrant/.ssh

if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 4096 -f "/home/vagrant/.ssh/id_rsa" -N "" -q
fi

sudo chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub

mkdir -p /vagrant/secret
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/secret/jenkins-ssh-key.pub

# -------------------------------------------------------------------
# Step 3: Install Java and required repository tools
# Jenkins requires Java. This lab uses OpenJDK 21.
# -------------------------------------------------------------------
sudo apt-get install -y fontconfig openjdk-21-jre ca-certificates curl gnupg
java -version

# -------------------------------------------------------------------
# Step 4: Configure official Jenkins Debian stable repository
# IMPORTANT:
# Jenkins repository signing key changed from jenkins.io-2023.key to
# jenkins.io-2026.key. Using old key causes NO_PUBKEY 7198F4B714ABFC68.
# -------------------------------------------------------------------
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc
sudo rm -f /etc/apt/keyrings/jenkins-keyring.asc
sudo rm -f /etc/apt/keyrings/jenkins-keyring.gpg

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo gpg --dearmor -o /etc/apt/keyrings/jenkins-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
apt-cache policy jenkins

# -------------------------------------------------------------------
# Step 5: Install Jenkins
# -------------------------------------------------------------------
sudo apt-get install -y jenkins
jenkins --version

# -------------------------------------------------------------------
# Step 6: Increase Jenkins service startup timeout
# Useful for low-resource local VMs where Jenkins may start slowly.
# -------------------------------------------------------------------
if [ -f /lib/systemd/system/jenkins.service ]; then
  sudo sed -i 's/^#\?TimeoutStartSec=.*/TimeoutStartSec=1200/' /lib/systemd/system/jenkins.service
fi

sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# -------------------------------------------------------------------
# Step 7: Verify Jenkins service
# -------------------------------------------------------------------
sleep 10
sudo systemctl is-active jenkins
sudo systemctl status jenkins --no-pager -l

echo "************   JENKINS PROVISIONING COMPLETED SUCCESSFULLY ************"
echo "Jenkins URL: http://172.16.0.15:8080"
echo "Initial admin password command: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
