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
echo "************   PROVISION MACHINE  DOCKER ************"
sudo apt install apt-transport-https ca-certificates net-tools curl lsb-release wget vim nano -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo bash get-docker.sh
sudo apt-get install docker-compose -y
sudo docker version
sudo docker-compose version
sudo docker info
sudo usermod -aG docker vagrant

# ssh from jenkins and ansible to docker
cat /vagrant/secret/jenkins-ssh-key.pub >> /home/vagrant/.ssh/authorized_keys
cat /vagrant/secret/ansible-ssh-key.pub >> /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
