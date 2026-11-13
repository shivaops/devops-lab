
# author  : Shiva Naik
# email   : shivanaik.it@gmail.com
# Mobile  : +973-38053730 Bahrain / +91-9820234089 India
# GitHub: 	 https://github.com/ShivaOps
# LinkedIn:  https://www.linkedin.com/in/shivaops/
# Portfolio: https://shivaops.github.io/
# YouTube:   https://www.youtube.com/@ShivaOps-AI


Vagrant.configure("2") do |config|
  config.vm.box_check_update = false


  ############   nfs-server   ############

  config.vm.define "nfs-server", autostart: true do |v|
    v.vm.hostname = "nfs-server"
    v.vm.box = "ubuntu/jammy64"
	  v.vm.boot_timeout = 1200  # Increase the timeout to 20 minutes
    v.vm.network :private_network, ip: "172.16.0.20"

    v.vm.provider "virtualbox" do |vb|
      vb.name = "nfs-server"
      vb.gui = false
      vb.memory = 1024
      vb.cpus = 1
    end

    # Add shell provisioner with log redirection
	v.vm.provision "shell", inline: <<-SHELL
    # You can also ensure that the dos/windows base edited script is converted
    # to unix/linux base before running it
	  tr -d '\\r' < /vagrant/install-nfs-server.sh > /vagrant/install-nfs-server-unix.sh
    mv /vagrant/install-nfs-server-unix.sh /vagrant/install-nfs-server.sh
    chmod +x /vagrant/install-nfs-server.sh
    bash /vagrant/install-nfs-server.sh | tee -a /vagrant/install-nfs-server.log
	echo "Appending /vagrant/hosts_file_list.txt to /etc/hosts to simplify ping/ssh"
    cat /vagrant/hosts_file_list.txt | sudo tee -a /etc/hosts > /dev/null
	SHELL
  end


  #############  jenkins-server  ############

  config.vm.define "jenkins", autostart: true do |v|
    v.vm.hostname = "jenkins"
    v.vm.box = "ubuntu/jammy64"
	v.vm.boot_timeout = 1200  # Increase the timeout to 20 minutes
    v.vm.network :private_network, ip: "172.16.0.15"

    v.vm.provider "virtualbox" do |vb|
      vb.name = "jenkins"
      vb.gui = false
      vb.memory = 1024
      vb.cpus = 1
    end

    # Add shell provisioner
	v.vm.provision "shell", inline: <<-SHELL
    # You can also ensure that the dos/windows base edited script is converted
    # to unix/linux base before running it
    tr -d '\\r' < /vagrant/install-jenkins.sh > /vagrant/install-jenkins-unix.sh
    mv /vagrant/install-jenkins-unix.sh /vagrant/install-jenkins.sh
    chmod +x /vagrant/install-jenkins.sh
    bash /vagrant/install-jenkins.sh | tee -a /vagrant/provision.log
	echo "Appending /vagrant/hosts_file_list.txt to /etc/hosts..."
    cat /vagrant/hosts_file_list.txt | sudo tee -a /etc/hosts > /dev/null
	SHELL
  end

  #############    ansible-server   ############

  config.vm.define "ansible", autostart: true do |v|
    v.vm.hostname = "ansible"
    v.vm.box = "ubuntu/jammy64"
	v.vm.boot_timeout = 1200  # Increase the timeout to 20 minutes
    v.vm.network :private_network, ip: "172.16.0.16"

    v.vm.provider "virtualbox" do |vb|
      vb.name = "ansible"
      vb.gui = false
      vb.memory = 1024
      vb.cpus = 1
    end

    # Add shell provisioner
	v.vm.provision "shell", inline: <<-SHELL
    # You can also ensure that the dos/windows base edited script is converted
    # to unix/linux base before running it
    tr -d '\\r' < /vagrant/install-ansible.sh > /vagrant/install-ansible-unix.sh
    mv /vagrant/install-ansible-unix.sh /vagrant/install-ansible.sh
    chmod +x /vagrant/install-ansible.sh
    bash /vagrant/install-ansible.sh | tee -a /vagrant/provision.log
	  echo "Appending /vagrant/hosts_file_list.txt to /etc/hosts..."
    cat /vagrant/hosts_file_list.txt | sudo tee -a /etc/hosts > /dev/null
	SHELL
  end

  #############   docker-server   ############

  config.vm.define "docker", autostart: true do |v|
    v.vm.hostname = "docker"
    v.vm.box = "ubuntu/jammy64"
	v.vm.boot_timeout = 1200  # Increase the timeout to 20 minutes
    v.vm.network :private_network, ip: "172.16.0.14"

    v.vm.provider "virtualbox" do |vb|
      vb.name = "docker"
      vb.gui = false
      vb.memory = 1024
      vb.cpus = 1
    end

    # Add shell provisioner
	v.vm.provision "shell", inline: <<-SHELL
    # You can also ensure that the dos/windows base edited script is converted
    # to unix/linux base before running it
    tr -d '\\r' < /vagrant/install-docker.sh > /vagrant/install-docker-unix.sh
    mv /vagrant/install-docker-unix.sh /vagrant/install-docker.sh
    chmod +x /vagrant/install-docker.sh
    bash /vagrant/install-docker.sh  | tee -a /vagrant/provision.log
	echo "Appending /vagrant/hosts_file_list.txt to /etc/hosts..."
    cat /vagrant/hosts_file_list.txt | sudo tee -a /etc/hosts > /dev/null
    SHELL
  end

  #############   kubernetes server - control plane node    ############

  config.vm.define "kmaster", autostart: true do |v|
    v.vm.hostname = "kmaster"
    v.vm.box = "ubuntu/jammy64"
	v.vm.boot_timeout = 1200  # Increase the timeout to 20 minutes
    v.vm.network :private_network, ip: "172.16.0.11"

    v.vm.provider "virtualbox" do |vb|
      vb.name = "kmaster"
      vb.gui = false
      vb.memory = 2048
      vb.cpus = 2
    end

    # Add shell provisioner
		v.vm.provision "shell", inline: <<-SHELL
    # You can also ensure that the dos/windows base edited script is converted
    # to unix/linux base before running it
		tr -d '\\r' < /vagrant/install-kubernetes.sh > /vagrant/install-kubernetes-unix.sh
		mv /vagrant/install-kubernetes-unix.sh /vagrant/install-kubernetes.sh
		chmod +x /vagrant/install-kubernetes.sh
		# log output to provision.log
		bash /vagrant/install-kubernetes.sh kmaster | tee -a /vagrant/provision.log
		echo "Appending /vagrant/hosts_file_list.txt to /etc/hosts..."
		cat /vagrant/hosts_file_list.txt | sudo tee -a /etc/hosts > /dev/null
    SHELL
  end

  #############   kubernetes worker node1 and node2   ############

  (1..2).each do |i|
  config.vm.define "kworker#{i}", autostart: true do |v|
    v.vm.hostname = "kworker#{i}"
    v.vm.box = "ubuntu/jammy64"
	v.vm.boot_timeout = 1200  # Increase the timeout to 20 minutes
    # Assign different IP addresses
        v.vm.network :private_network, ip: "172.16.0.#{11 + i}"
    v.vm.provider "virtualbox" do |vb|
      vb.name = "kworker#{i}"
      vb.gui = false
      vb.memory = 1024
      vb.cpus = 1
    end

    # Add shell provisioner
	v.vm.provision "shell", inline: <<-SHELL
  bash /vagrant/install-kubernetes.sh kworker#{i} | tee -a /vagrant/provision.log
	echo "Appending /vagrant/hosts_file_list.txt to /etc/hosts..."
  cat /vagrant/hosts_file_list.txt | sudo tee -a /etc/hosts > /dev/null
  SHELL
  end
  end
end
