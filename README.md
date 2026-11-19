# ShivaOps DevOps Lab

## Fully Automated Local DevOps Environment — One Command Setup

**ShivaOps DevOps Lab** is a fully automated, multi-VM local DevOps practice environment built using **Vagrant** and **Oracle VirtualBox** on a Windows laptop.

With just one command:

```powershell
vagrant up --provision
```

Vagrant creates and configures the seven Ubuntu virtual machines, while Linux shell provisioning scripts automate the installation and configuration of the DevOps infrastructure.

**The automated provisioning process includes:**

- Creating seven Ubuntu virtual machines with predefined hostnames, private IP addresses, and networking.
- Installing and configuring **Jenkins, Docker, Ansible, and NFS** for CI/CD, containers, configuration management, and shared storage practice.
- Setting up the **Kubernetes control plane and two worker nodes**, including automatically joining the workers to the cluster.
- Configuring Kubernetes cluster networking and verifying node readiness.
- Installing the **NGINX Ingress Controller** to route traffic to applications in Kubernetes.
- Installing and configuring **MetalLB** to provide local LoadBalancer IP addresses.
- Configuring **NFS shared storage** and Kubernetes storage provisioning for persistent application data.
- Preparing the lab for future application deployments, Jenkins pipelines, Docker, Kubernetes, and CI/CD demonstrations.

The goal is to provide a **repeatable, hands-on DevOps lab** for learning, experimentation, demonstrations, troubleshooting, and future CI/CD deployment scenarios. The same Vagrant configuration and shell scripts can be used to rebuild the environment without manually repeating each setup task.

This is the **base DevOps infrastructure platform**. In a future demonstration, I plan to use my **Smart Trip — AI-Assisted Airline Booking Simulator** as a real application for Docker, Kubernetes, Jenkins, and end-to-end CI/CD workflows on this lab.

**Watch the DevOps Lab demonstration:** [ShivaOps DevOps Lab — One Command Setup](https://youtu.be/xB-PuEIRJpQ)

**Watch the Smart Trip application series:** [Smart Trip — AI-Assisted Airline Booking Simulator — Built with the Power of AI](https://www.youtube.com/playlist?list=PLYkaOC9kXnifZLmJb9NehgmZYqmCEaiQ6)

**ShivaOps Portfolio:** [https://shivaops.github.io/](https://shivaops.github.io/)

---

## 1. Lab Architecture

| Virtual Machine | Private IP | Role |
|---|---|---|
| `nfs-server` | `172.16.0.20` | Shared NFS storage |
| `jenkins` | `172.16.0.15` | CI/CD automation |
| `ansible` | `172.16.0.16` | Configuration automation |
| `docker` | `172.16.0.14` | Docker and container practice |
| `kmaster` | `172.16.0.11` | Kubernetes control plane |
| `kworker1` | `172.16.0.12` | Kubernetes worker |
| `kworker2` | `172.16.0.13` | Kubernetes worker |

**Included features:** automatic Kubernetes worker joining, NFS-based Kubernetes storage, Ingress routing, MetalLB LoadBalancer networking, and PowerShell verification.

## 2. Prerequisites

Install these tools on your Windows computer:

| Software | Version used in the demonstration |
|---|---|
| [Oracle VirtualBox](https://www.virtualbox.org/wiki/Downloads) | 7.2.14 |
| [HashiCorp Vagrant](https://developer.hashicorp.com/vagrant/install) | 2.4.9 |
| [Git for Windows](https://git-scm.com/downloads/win) | 2.54.0 |
| Windows PowerShell | Included with Windows |
| Ubuntu Vagrant box | `ubuntu/jammy64` (downloaded by Vagrant) |

**Recommended host:** Windows 10/11, 8 CPU cores, 32 GB RAM, 80 GB free disk space, hardware virtualization enabled, and Internet access.

Use **Windows PowerShell** for the commands below. Git Bash is not required.

## 3. Configure VirtualBox Networking

In VirtualBox Manager, open **Tools → Network → Host-only Networks** and configure the lab adapter:

```text
IPv4 Address : 172.16.0.1
Subnet Mask  : 255.255.255.0
DHCP Server  : Disabled
```

- **NAT** provides Internet access for software installation.
- **Host-Only networking** connects Windows and the lab VMs on the private `172.16.0.0/24` network.
- VM addresses are statically defined in the `Vagrantfile`.

Use the Host-Only adapter expected by your Vagrant configuration. Do not overwrite an adapter required by another VM project.

## 4. Quick Start — Windows PowerShell

After completing the prerequisites and network setup, **open a new Windows PowerShell window**.

### Step 1 — Allow trusted scripts for this session

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

This temporarily relaxes execution-policy checks in the current PowerShell process. It does **not** permanently change the computer's policy or override Group Policy. Run only trusted scripts.

### Step 2 — Verify the tools

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
vagrant --version
git --version
```

### Step 3 — Clone the project

```powershell
git clone https://github.com/shivaops/devops-lab.git C:\vagrant
cd C:\vagrant
```

**Important:** The project expects to be located directly at `C:\vagrant`, which is shared into the Ubuntu VMs as `/vagrant`. Clone into a fresh folder, not `C:\vagrant\devops-lab`.

### Step 4 — Validate and inspect initial state

```powershell
vagrant validate
vagrant status
```

On a fresh setup, the seven machines should display **`not created`**.

### Step 5 — Build the lab

```powershell
vagrant up --provision
```

Vagrant creates the VMs and runs the configured installation scripts. The first run may download the Ubuntu base box and software packages.

### Step 6 — Check VM status

```powershell
vagrant status
```

All seven VMs should display **`running`**. Continue with the service checks below; VM status alone does not prove that all services are healthy.

## 5. Verify the Lab Manually

These commands demonstrate how to check individual components. Run them from **`C:\vagrant` in Windows PowerShell**.

| Component | Command | What to check |
|---|---|---|
| All VMs | `vagrant status` | Seven machines show `running` |
| Kubernetes nodes | `vagrant ssh kmaster -c "kubectl get nodes -o wide"` | Master and both workers show `Ready` |
| Kubernetes pods | `vagrant ssh kmaster -c "kubectl get pods -A"` | Review pod states; investigate failures |
| NFS StorageClass | `vagrant ssh kmaster -c "kubectl get storageclass"` | NFS provisioner StorageClass is listed |
| Ingress | `vagrant ssh kmaster -c "kubectl get svc -n ingress-nginx"` | Ingress service and assigned IP |
| MetalLB | `vagrant ssh kmaster -c "kubectl get ipaddresspool -A"` | Configured local IP pool |
| NFS server | `vagrant ssh nfs-server -c "systemctl is-active nfs-server && showmount -e localhost"` | Service active and exports visible |
| Docker | `vagrant ssh docker -c "docker --version && docker compose version && systemctl is-active docker"` | Docker, Compose, service |
| Ansible | `vagrant ssh ansible -c "ansible --version"` | Ansible installed |
| Jenkins | `vagrant ssh jenkins -c "systemctl is-active jenkins && ss -ltn"` | Jenkins active and port 8080 listening |

The intended Ingress LoadBalancer IP is **`172.16.0.100`**. Actual resource and service status must be confirmed from command output.

**Why check manually?** These commands help beginners understand what each service does and provide a starting point for troubleshooting.

## 6. Automated Verification — `verify_all_vm.ps1`

Instead of repeating manual checks after every lab startup, run the included PowerShell verification script it will performs all the above manual task in single execution:

```powershell
cd C:\vagrant
.\verify_all_vm.ps1
```

If you opened a new PowerShell session, first run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` again, if required.

The script checks:

- VirtualBox and Vagrant installation; seven VM states
- NFS service and exports; Jenkins service and port 8080
- Docker and Compose; Ansible and Python
- SSH connectivity from Ansible to Docker and Kubernetes master
- Kubernetes node/pod listings, StorageClass, Ingress and MetalLB resources
- Kubernetes worker services and required tools

**Benefits:** one repeatable verification run, visible PASS/FAIL results, and timestamped technical logs stored under **`C:\vagrant\logs`**.


## 7. Access Jenkins

Open **http://172.16.0.15:8080** from the Windows host.

To retrieve the initial Jenkins administrator password:

```powershell
vagrant ssh jenkins
```

Then run **inside the Linux VM**:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Do not publish the password in recordings or repository files.

## 8. Useful Vagrant Commands

Run from `C:\vagrant`:

| Task | Command |
|---|---|
| Check status | `vagrant status` |
| Start existing VMs without provisioning | `vagrant up --no-provision` |
| Create/start and provision as applicable | `vagrant up --provision` |
| Stop VMs | `vagrant halt` |
| SSH to Kubernetes master | `vagrant ssh kmaster` |
| Destroy Vagrant-managed VMs | `vagrant destroy -f` |

**Warning:** `vagrant destroy -f` deletes the project VMs and their virtual disks, including data stored only on those disks. To rebuild the lab afterward, run `vagrant up --provision`.

## 9. Repository Files

| File | Purpose |
|---|---|
| `Vagrantfile` | Seven-VM infrastructure definition |
| `install-nfs-server.sh`, `install-nfs-provisioner.sh` | NFS server and Kubernetes storage |
| `install-jenkins.sh` | Jenkins installation |
| `install-ansible.sh` | Ansible installation |
| `install-docker.sh` | Docker installation |
| `install-kubernetes.sh` | Kubernetes master and workers |
| `install-ingress-metallb.sh` | Ingress and MetalLB setup |
| `hosts_file_list.txt` | Hostname-to-IP mapping |
| `verify_all_vm.ps1` | Automated checks and log collection |

**Security:** This is a learning lab, not a production-hardened deployment. Never commit credentials, SSH private keys, Kubernetes join tokens, or runtime secrets. Keep `.vagrant/`, `logs/`, `secret/`, and generated join-token files out of version control.

---

**Created for:** DevOps learning, infrastructure automation and future Smart Trip CI/CD demonstrations.

[Smart Trip — AI-Assisted Airline Booking Simulator](https://www.youtube.com/playlist?list=PLYkaOC9kXnifZLmJb9NehgmZYqmCEaiQ6) · [ShivaOps GitHub](https://github.com/shivaops) ·

**License: MIT**
