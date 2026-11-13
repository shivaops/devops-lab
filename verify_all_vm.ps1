# author  : Shiva Naik
# email   : shivanaik.it@gmail.com
# Mobile  : +973-38053730 Bahrain / +91-9820234089 India
# GitHub: 	 https://github.com/ShivaOps
# LinkedIn:  https://www.linkedin.com/in/shivaops/
# Portfolio: https://shivaops.github.io/
# YouTube:   https://www.youtube.com/@ShivaOps-AI

$ErrorActionPreference = "Continue"

$LabRoot = "C:\vagrant"
$LogDir  = Join-Path $LabRoot "logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "verify_all_vm_$TimeStamp.log"

$VmList = @(
    "nfs-server",
    "jenkins",
    "ansible",
    "docker",
    "kmaster",
    "kworker1",
    "kworker2"
)

$Results = New-Object System.Collections.Generic.List[object]

function Write-BigSection {
    param([string]$Title)

    Write-Host ""
    Write-Host "################################################################" -ForegroundColor Yellow
    Write-Host ("###  {0}" -f $Title) -ForegroundColor Yellow
    Write-Host "################################################################" -ForegroundColor Yellow
}

function Write-StartBlock {
    param(
        [string]$VmName,
        [string]$Title
    )

    Write-Host ""
    Write-Host "################################################################" -ForegroundColor Yellow
    Write-Host ("###  START CHECK : {0} : {1}" -f $VmName, $Title) -ForegroundColor Yellow
}

function Write-EndBlock {
    param(
        [string]$VmName,
        [string]$Title,
        [int]$ExitCode
    )

    Write-Host ""
    if ($ExitCode -eq 0) {
        Write-Host ("###  END CHECK   : {0} : {1} : PASS" -f $VmName, $Title) -ForegroundColor Green
    } else {
        Write-Host ("###  END CHECK   : {0} : {1} : FAIL, ExitCode={2}" -f $VmName, $Title, $ExitCode) -ForegroundColor Red
    }
    Write-Host "################################################################" -ForegroundColor Yellow
    Write-Host ""
}

function Write-RemoteStep {
    param([string]$StepTitle)
    Write-Host ""
    Write-Host ("--- {0} ---" -f $StepTitle) -ForegroundColor Magenta
}


function Show-SuccessBanner {
    param([string]$Message)

	# flashing/blinking banner
    $Banner = @(
        "##################################################################################",
        "###                                                          					###",
        "###        FULLY AUTOMATED LOCAL DEVOPS LAB IS READY AND FULLY FUNCTIONAL   	###",
        "###                                                          					###",
        "##################################################################################"
    )

    $StartLeft = $Host.UI.RawUI.CursorPosition.X
    $StartTop  = $Host.UI.RawUI.CursorPosition.Y

    for ($i = 1; $i -le 200; $i++) {

        $Color = if ($i % 2 -eq 0) { "Yellow" } else { "Green" }

        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $StartLeft, $StartTop

        foreach ($line in $Banner) {
            Write-Host $line -ForegroundColor $Color
        }

        Start-Sleep -Milliseconds 300
		# press enter key or down arrow key to exit loop
		if ([Console]::KeyAvailable) {
			$key = [Console]::ReadKey($true).Key
			if ($key -eq "Enter" -or $key -eq "DownArrow") { break }
		}
    }

    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $StartLeft, $StartTop

    foreach ($line in $Banner) {
        Write-Host $line -ForegroundColor Green
    }

    Write-Host ""
    Write-Host $Message -ForegroundColor Green
}

function Add-Result {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$PassDetail = "",
        [string]$FailDetail = ""
    )

    $DisplayDetail = if ($Passed) { $PassDetail } else { $FailDetail }

    $Results.Add([PSCustomObject]@{
        Check  = $Name
        Status = $(if ($Passed) { "PASS" } else { "FAIL" })
        Detail = $DisplayDetail
    }) | Out-Null

    if ($Passed) {
        if ([string]::IsNullOrWhiteSpace($PassDetail)) {
            Write-Host ("[PASS] {0}" -f $Name) -ForegroundColor Green
        } else {
            Write-Host ("[PASS] {0} - {1}" -f $Name, $PassDetail) -ForegroundColor Green
        }
    } else {
        if ([string]::IsNullOrWhiteSpace($FailDetail)) {
            Write-Host ("[FAIL] {0} failed" -f $Name) -ForegroundColor Red
        } else {
            Write-Host ("[FAIL] {0} failed - {1}" -f $Name, $FailDetail) -ForegroundColor Red
        }
    }
}

function Invoke-VagrantBash {
    param(
        [string]$VmName,
        [string]$Title,
        [string]$BashScript
    )

    Write-StartBlock -VmName $VmName -Title $Title

    $BashScript = $BashScript -replace "`r`n", "`n" -replace "`r", "`n"
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($BashScript)
    $B64   = [Convert]::ToBase64String($Bytes)

    $RemoteCommand = "echo $B64 | base64 -d | bash"
    $Output = & vagrant ssh $VmName -c $RemoteCommand 2>&1
    $ExitCode = $LASTEXITCODE

    $Output | ForEach-Object { Write-Host $_ }

    Write-EndBlock -VmName $VmName -Title $Title -ExitCode $ExitCode

    return [PSCustomObject]@{
        ExitCode = $ExitCode
        Output   = ($Output -join "`n")
    }
}

Start-Transcript -Path $LogFile -Append | Out-Null

Set-Location $LabRoot

Write-BigSection "HOST TOOL VERSION CHECK"

$vagrantVersion = (& vagrant --version 2>&1) -join "`n"


#$vbVersion = (& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version 2>&1) -join "`n"
$VBoxInstallDir = (Get-ItemProperty "HKLM:\SOFTWARE\Oracle\VirtualBox" -ErrorAction SilentlyContinue).InstallDir

if ($VBoxInstallDir) {
    $VBoxManagePath = Join-Path $VBoxInstallDir "VBoxManage.exe"
} else {
    $VBoxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
}

if (Test-Path $VBoxManagePath) {
    $vbVersion = (& $VBoxManagePath --version 2>&1) -join "`n"
} else {
    $vbVersion = "VBoxManage.exe not found. VirtualBox path not FOUND OR may not be installed properly."
}

Add-Result "Vagrant installation verification" ($vagrantVersion -match "^Vagrant\s+\d+\.\d+") $vagrantVersion "Vagrant command not found or version output is invalid. Check whether Vagrant is installed and available in PATH."
Add-Result "VirtualBox installation verification" ($vbVersion -match "^\d+\.\d+") $vbVersion "VirtualBox version could not be detected. Check whether VirtualBox is installed and VBoxManage.exe is accessible."

Write-BigSection "VAGRANT VM STATUS CHECK"

$statusOutput = & vagrant status 2>&1
$statusOutput | ForEach-Object { Write-Host $_ }

$RunningVMs  = New-Object System.Collections.Generic.List[string]
$PowerOffVMs = New-Object System.Collections.Generic.List[string]
$OtherVMs    = New-Object System.Collections.Generic.List[string]

foreach ($vm in $VmList) {
    $vmStatus = (& vagrant status $vm 2>&1) -join "`n"

    if ($vmStatus -match "running \(virtualbox\)") {
        $RunningVMs.Add($vm) | Out-Null
        Add-Result "VM : $vm" $true "running" "VM is not running. Start existing VM using: vagrant up $vm --no-provision"
    } elseif ($vmStatus -match "poweroff \(virtualbox\)") {
        $PowerOffVMs.Add($vm) | Out-Null
        Add-Result "VM : $vm" $false "running" "VM is poweroff. Start it using: vagrant up $vm --no-provision"
    } elseif ($vmStatus -match "not created \(virtualbox\)") {
        $OtherVMs.Add($vm) | Out-Null
        Add-Result "VM : $vm" $false "running" "VM is not created. Create/provision it using: vagrant up $vm --provision"
    } else {
        $OtherVMs.Add($vm) | Out-Null
        Add-Result "VM : $vm" $false "running" "VM is not in running state. Check with: vagrant status $vm"
    }
}

if (($PowerOffVMs.Count + $OtherVMs.Count) -eq $VmList.Count) {
    Write-BigSection "VERIFICATION STOPPED"

    Write-Host "All ShivaOps DevOps Lab VMs are currently not running." -ForegroundColor Red
    Write-Host "Main component verification cannot continue because vagrant ssh works only when the VM is running." -ForegroundColor Red
    Write-Host ""
    Write-Host "If VMs are already created but powered off, start them without re-running provisioning:" -ForegroundColor Yellow
    Write-Host "vagrant up --no-provision" -ForegroundColor White
    Write-Host ""
    Write-Host "If VMs are not created yet, create and provision them using:" -ForegroundColor Yellow
    Write-Host "vagrant up --provision" -ForegroundColor White
    Write-Host ""
    Write-Host "After all VMs are running, execute this verification script again." -ForegroundColor Yellow
    Write-Host ""

    Write-BigSection "FINAL VERIFICATION SUMMARY"

    foreach ($item in $Results) {
        if ($item.Status -eq "PASS") {
            Write-Host ("[PASS] {0} - {1}" -f $item.Check, $item.Detail) -ForegroundColor Green
        } else {
            Write-Host ("[FAIL] {0} - {1}" -f $item.Check, $item.Detail) -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "################################################################" -ForegroundColor Yellow
    Write-Host "###  Full technical log saved at:" -ForegroundColor Yellow
    Write-Host ("###  {0}" -f $LogFile) -ForegroundColor Yellow
    Write-Host "################################################################" -ForegroundColor Yellow

    Stop-Transcript | Out-Null
    exit 1
}

Write-BigSection "MAIN COMPONENT VERIFICATION"

$nfsCheck = @'
set -e
echo ""
echo "###  VERIFYING: NFS service status"
sudo systemctl is-active nfs-server

echo ""
echo "###  VERIFYING: NFS exports"
sudo exportfs -v

echo ""
echo "###  VERIFYING: NFS export folder"
ls -ld /srv/nfs/kubedata
'@
$r = Invoke-VagrantBash -VmName "nfs-server" -Title "NFS server verification" -BashScript $nfsCheck
Add-Result "NFS server verification" ($r.ExitCode -eq 0) "NFS service, exports, and export folder checked successfully" "Check whether nfs-server VM is running, NFS service is active, and /srv/nfs/kubedata is exported."

$jenkinsCheck = @'
set -e
echo ""
echo "###  VERIFYING: Java version"
java -version 2>&1 | head -3

echo ""
echo "###  VERIFYING: Jenkins service"
sudo systemctl is-active jenkins

echo ""
echo "###  VERIFYING: Jenkins web port 8080"
ss -ltnp | grep ':8080'

echo ""
echo "###  VERIFYING: Jenkins package"
dpkg -l | grep jenkins

echo ""
echo "###  VERIFYING: Jenkins URL"
JENKINS_IP=$(hostname -I | tr ' ' '\n' | grep '^172\.16\.' | head -1)
echo "Jenkins URL: http://${JENKINS_IP}:8080"

echo ""
echo "###  JENKINS INITIAL ADMIN PASSWORD"
echo "To view Jenkins initial admin password, run:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
'@
$r = Invoke-VagrantBash -VmName "jenkins" -Title "Jenkins verification" -BashScript $jenkinsCheck
Add-Result "Jenkins verification" ($r.ExitCode -eq 0) "Jenkins service, URL, and port 8080 checked successfully" "Check whether jenkins VM is running, Jenkins service is active, Jenkins URL is reachable, and port 8080 is listening."

$dockerCheck = @'
set -e
echo ""
echo "###  VERIFYING: Docker version"
docker --version

echo ""
echo "###  VERIFYING: Docker Compose version"
docker compose version || docker-compose --version

echo ""
echo "###  VERIFYING: Docker service"
sudo systemctl is-active docker

echo ""
echo "###  VERIFYING: Docker info summary"
docker info 2>/dev/null | grep -E "Server Version|Storage Driver|Cgroup Driver|Operating System" || true
'@
$r = Invoke-VagrantBash -VmName "docker" -Title "Docker host verification" -BashScript $dockerCheck
Add-Result "Docker host verification" ($r.ExitCode -eq 0) "Docker, Compose, and Docker service checked successfully" "Check whether docker VM is running, Docker service is active, and Docker Compose is installed."

$ansibleCheck = @'
set -e
echo ""
echo "###  VERIFYING: Ansible version"
ansible --version

echo ""
echo "###  VERIFYING: Python version"
python3 --version

echo ""
echo "###  VERIFYING: SSH key files"
ls -la ~/.ssh || true
'@
$r = Invoke-VagrantBash -VmName "ansible" -Title "Ansible verification" -BashScript $ansibleCheck
Add-Result "Ansible verification" ($r.ExitCode -eq 0) "Ansible and Python checked successfully" "Check whether ansible VM is running, Ansible is installed, and Python is available."

$ansibleSshCheck = @'
set -e
echo ""
echo "###  VERIFYING:  SSH from ansible to docker"
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 vagrant@docker "hostname"

echo ""
echo "###  VERIFYING:  SSH from ansible to kmaster"
ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 vagrant@kmaster "hostname"
'@
$r = Invoke-VagrantBash -VmName "ansible" -Title "Ansible SSH connectivity smoke test" -BashScript $ansibleSshCheck
Add-Result "Ansible SSH connectivity verification" ($r.ExitCode -eq 0) "SSH connectivity from ansible VM to docker and kmaster checked successfully" "SSH test from ansible VM failed. Check ansible VM status, SSH key setup, hostnames, and network connectivity to docker and kmaster."

$k8sMasterCheck = @'
set -e

echo ""
echo "################################################################"
echo "###  KMASTER STEP 1: KUBERNETES CLIENT VERSION"
echo "################################################################"
kubectl version --client=true --output=yaml 2>/dev/null || kubectl version --client

echo ""
echo "################################################################"
echo "###  KMASTER STEP 2: CLUSTER NODES"
echo "################################################################"
kubectl get nodes -o wide

echo ""
echo "################################################################"
echo "###  KMASTER STEP 3: KUBERNETES NODE STATUS SUMMARY"
echo "################################################################"

NOT_READY_NODES=$(kubectl get nodes --no-headers | awk '$2 != "Ready" {print $1 " = " $2}')

if [ -z "$NOT_READY_NODES" ]; then
    echo "All Kubernetes nodes are Ready."
else
    echo "WARNING: Some Kubernetes nodes are not Ready."
    echo "$NOT_READY_NODES"
    echo "This does not mean kmaster verification failed."
    echo "It means cluster status was collected, but one or more worker nodes need attention."
fi

echo ""
echo "################################################################"
echo "###  KMASTER STEP 4: ALL KUBERNETES PODS"
echo "################################################################"
kubectl get pods -A -o wide

echo ""
echo "################################################################"
echo "###  KMASTER STEP 5: DEFAULT STORAGECLASS"
echo "################################################################"
kubectl get storageclass

echo ""
echo "################################################################"
echo "###  KMASTER STEP 6: INGRESS CONTROLLER SERVICE"
echo "################################################################"
kubectl get svc -n ingress-nginx -o wide

echo ""
echo "################################################################"
echo "###  KMASTER STEP 7: METALLB PODS"
echo "################################################################"
kubectl get pods -n metallb-system -o wide

echo ""
echo "################################################################"
echo "###  KMASTER STEP 8: METALLB IPADDRESSPOOL"
echo "################################################################"
kubectl get ipaddresspool -A -o wide

echo ""
echo "################################################################"
echo "###  KMASTER STEP 9: METALLB L2ADVERTISEMENT"
echo "################################################################"
kubectl get l2advertisement -A -o wide

echo ""
echo "################################################################"
echo "###  KMASTER VERIFICATION COMPLETED"
echo "################################################################"
'@
$r = Invoke-VagrantBash -VmName "kmaster" -Title "Kubernetes cluster verification" -BashScript $k8sMasterCheck
Add-Result "Kubernetes master status verification" ($r.ExitCode -eq 0) "kmaster, kubectl, node status, pods, StorageClass, Ingress, and MetalLB status printed successfully" "Check whether kmaster VM is running and kubectl is configured correctly."


foreach ($worker in @("kworker1", "kworker2")) {
    $workerCheck = @'
set -e
echo ""
echo "###  VERIFYING: Kubelet service"
sudo systemctl is-active kubelet

echo ""
echo "###  VERIFYING: Containerd service"
sudo systemctl is-active containerd

echo ""
echo "###  VERIFYING: Kubelet version"
kubelet --version

echo ""
echo "###  VERIFYING: Kubeadm version"
kubeadm version -o short

echo ""
echo "###  VERIFYING: NFS client package"
dpkg -l | grep nfs-common
'@

    $r = Invoke-VagrantBash -VmName $worker -Title "Kubernetes worker verification" -BashScript $workerCheck
    Add-Result "Worker verification: $worker" ($r.ExitCode -eq 0) "Kubelet, containerd, kubeadm, and nfs-common checked successfully" "Check whether $worker VM is running, kubelet is active, containerd is active, kubeadm is available, and nfs-common is installed."
}

Write-BigSection "FINAL VERIFICATION SUMMARY"

foreach ($item in $Results) {
    if ($item.Status -eq "PASS") {
        Write-Host ("[PASS] {0} - {1}" -f $item.Check, $item.Detail) -ForegroundColor Green
    } else {
        Write-Host ("[FAIL] {0} - {1}" -f $item.Check, $item.Detail) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "################################################################" -ForegroundColor Yellow
Write-Host "###  Full technical log saved at:" -ForegroundColor Yellow
Write-Host ("###  {0}" -f $LogFile) -ForegroundColor Yellow
Write-Host "################################################################" -ForegroundColor Yellow

Stop-Transcript | Out-Null

if (($Results | Where-Object { $_.Status -eq "FAIL" }).Count -gt 0) {
    Write-Host ""
    Write-Host "Some checks failed. Open the log file above for troubleshooting." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Show-SuccessBanner "All main Verification/checks passed. ShivaOps DevOps Lab is ready."
    exit 0
}
