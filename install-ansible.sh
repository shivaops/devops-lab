#!/bin/bash
# author  : Shiva Naik
# email   : shivanaik.it@gmail.com
# Mobile  : +973-38053730 Bahrain / +91-9820234089 India
# GitHub: 	 https://github.com/ShivaOps
# LinkedIn:  https://www.linkedin.com/in/shivaops/
# Portfolio: https://shivaops.github.io/
# YouTube:   https://www.youtube.com/@ShivaOps-AI

# set -e  # Exit immediately if a command exits with a non-zero status.
set -x  # Print each command before executing it.

# install ansible
echo "************   PROVISION MACHINE  ANSIBLE ************"
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt update -y
sudo apt install ansible -y
ansible --version

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo bash get-docker.sh
sudo docker version
sudo docker info
sudo usermod -aG docker vagrant

ssh-keygen -t rsa -b 4096 -f "/home/vagrant/.ssh/id_rsa" -N "" -q
# This will generate a public key (~/.ssh/id_rsa.pub) and a private key (~/.ssh/id_rsa).
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/secret/ansible-ssh-key.pub

# ssh from jenkins to ansible
cat /vagrant/secret/jenkins-ssh-key.pub >> /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
