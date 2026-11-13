#!/bin/bash

# author  : Shiva Naik
# email   : shivanaik.it@gmail.com
# Mobile  : +973-38053730 Bahrain / +91-9820234089 India
# GitHub: 	 https://github.com/ShivaOps
# LinkedIn:  https://www.linkedin.com/in/shivaops/
# Portfolio: https://shivaops.github.io/
# YouTube:   https://www.youtube.com/@ShivaOps-AI


provisioning_vm="$1"

echo "************   PROVISION MACHINE  $provisioning_vm ************"
# set -e
set -x

echo "************ Kubernetes cluster Provisioning start ************"

echo "Login user is $(whoami)"
# note script will run under root user. can be ignore sudo prefix

sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release wget vim nano nfs-common -y

# Install containerd v2.0.5
wget https://github.com/containerd/containerd/releases/download/v2.0.5/containerd-2.0.5-linux-amd64.tar.gz
tar Czxvf /usr/local containerd-2.0.5-linux-amd64.tar.gz
rm containerd-2.0.5-linux-amd64.tar.gz

# containerd service setup
sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /usr/lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Install runc (v1.1.9 latest stable)
sudo wget -O /usr/local/sbin/runc https://github.com/opencontainers/runc/releases/download/v1.1.9/runc.amd64
sudo chmod 755 /usr/local/sbin/runc

containerd --version
runc --version

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Add Kubernetes v1.32.3 apt repo (latest)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# Install Kubernetes v1.32.3
sudo apt-get install -y kubeadm=1.32.3-1.1 kubelet=1.32.3-1.1 kubectl=1.32.3-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Disable swap (required by K8s)
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

# Enable required kernel modules
# sudo modprobe br_netfilter
# sudo sysctl -w net.ipv4.ip_forward=1

# Purpose: Run on ALL nodes (master + workers)
# Load kernel module
sudo modprobe br_netfilter
echo "br_netfilter" | tee /etc/modules-load.d/br_netfilter.conf

# Apply sysctl
tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Restart required services
sudo systemctl restart containerd
sudo systemctl restart kubelet


# MASTER NODE SETUP
if [ "$provisioning_vm" == "kmaster" ]; then
    until kubeadm init --kubernetes-version=1.32.3 --apiserver-advertise-address=172.16.0.11 --pod-network-cidr=10.244.0.0/16; do
        echo "kubeadm init failed. Retrying in 30 seconds..."
        sleep 30
    done

    sudo -u vagrant mkdir -p /home/vagrant/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    sudo chown vagrant:vagrant /home/vagrant/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf

    sudo kubeadm token create --print-join-command > /vagrant/join-token-command.sh
    sudo chmod 777 /vagrant/join-token-command.sh

    # Flannel CNI plugin
    # kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
    # calico CNI plugin
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

    # Wait for Kubernetes API
    while ! kubectl get nodes; do
        echo "Waiting for Kubernetes API..."
        sleep 20
    done

    # Allow SSH from Jenkins & Ansible to kubernetes master node
    # note jenkin ansible already provisioned before kubernetes master node.
    # /vagrant/secret/jenkins-ssh-key.pub & /vagrant/secret/ansible-ssh-key.pub already created in mount folder /vagrant
    # see vagrantfile sequence/order of vm
    if [ -f "/vagrant/secret/jenkins-ssh-key.pub" ]; then
	  cat /vagrant/secret/jenkins-ssh-key.pub >> /home/vagrant/.ssh/authorized_keys
	fi

    if [ -f "/vagrant/secret/ansible-ssh-key.pub" ]; then
      cat /vagrant/secret/ansible-ssh-key.pub >> /home/vagrant/.ssh/authorized_keys
    fi
    # cat /vagrant/jenkins-ssh-key.pub >> /home/vagrant/.ssh/authorized_keys
    # cat /vagrant/ansible-ssh-key.pub >> /home/vagrant/.ssh/authorized_keys
    chmod 600 /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh

    # Fix MetalLB IP Assignment
    METALLB_IP="172.16.0.100"
    IFACE=$(ip -o -4 route show to default | awk '{print $5}')
    echo "Checking MetalLB External IP on $IFACE..."
    if ! ip addr show "$IFACE" | grep -q "$METALLB_IP"; then
        echo "MetalLB IP $METALLB_IP missing! Re-adding it..."
        sudo ip addr add $METALLB_IP/24 dev "$IFACE"
    else
        echo "MetalLB IP $METALLB_IP already present."
    fi

    # Install Helm
    if ! command -v helm &> /dev/null; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    sleep 20
    # Run NFS Provisioner
    sudo apt-get install dos2unix -y
    dos2unix /vagrant/install-nfs-provisioner.sh
	chmod +x /vagrant/install-nfs-provisioner.sh
    bash /vagrant/install-nfs-provisioner.sh > /vagrant/nfs-provisioner.log 2>&1

    # Run Ingress + MetalLB setup in background
	dos2unix /vagrant/install-ingress-metallb.sh
	chmod +x /vagrant/install-ingress-metallb.sh
    nohup bash /vagrant/install-ingress-metallb.sh > /vagrant/install-ingress-metallb.log 2>&1 &
fi

# WORKER NODE JOIN
if [[ "$provisioning_vm" == "kworker1" || "$provisioning_vm" == "kworker2" ]]; then
    echo "Executing Join Token on $provisioning_vm"
    bash /vagrant/join-token-command.sh
fi
