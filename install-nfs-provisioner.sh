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

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

kubectl create namespace nfs-provisioner

helm install nfs-client nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace nfs-provisioner \
  --set nfs.server=172.16.0.20 \
  --set nfs.path=/srv/nfs/kubedata \
  --set storageClass.name=nfs-client \
  --set storageClass.defaultClass=true

kubectl get pods -n nfs-provisioner
kubectl get storageclass
