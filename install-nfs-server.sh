#!/bin/bash
# author  : Shiva Naik
# email   : shivanaik.it@gmail.com
# Mobile  : +973-38053730 Bahrain / +91-9820234089 India
# GitHub: 	 https://github.com/ShivaOps
# LinkedIn:  https://www.linkedin.com/in/shivaops/
# Portfolio: https://shivaops.github.io/
# YouTube:   https://www.youtube.com/@ShivaOps-AI

	 provisioning_vm="$1"
     echo "************   PROVISIONING MACHINE  $provisioning_vm ************"
     #set -e  # Exit immediately if a command exits with a non-zero status.
     set -x  # Print each command before executing it.

	#NOTE vagrant run under root user so no need to specify sudo
	echo "login user is $(whoami)"
	apt-get update
	apt install apt-transport-https nano vim curl wget -y
	apt install nfs-kernel-server -y
	mkdir -p /srv/nfs/kubedata
	chown nobody:nogroup /srv/nfs/kubedata
	chmod 777 /srv/nfs/kubedata
	echo "/srv/nfs/kubedata 172.16.0.0/24(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports > /dev/null
	exportfs -a
	systemctl restart nfs-kernel-server
