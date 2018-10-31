# -*- mode: ruby -*-
# vi: set ft=ruby :

# This Vagrant script assumes that you are running on a system with virtualbox
# installed.

# Modify the network settings to match your environment.

# Make sure to be using the vagrant-vbguest plugin

client_box    = 'bento/ubuntu-16.04'
client_cpus   = '1'
client_memory = '1024'
validator_box    = 'bento/ubuntu-16.04'
validator_cpus   = '1'
validator_memory = '1024'
clientip1 = '10.20.30.101'
nodeip1 = '10.20.30.201'
nodeip2 = '10.20.30.202'
nodeip3 = '10.20.30.203'
nodeip4 = '10.20.30.204'
nodeiplist = "#{nodeip1},#{nodeip2},#{nodeip3},#{nodeip4}"

# TODO: change the 'repo' default back to master
# Cannot use master due to version pinning in master version of sovtoken package
# Both sovtoken and indy-node dep on indy-plenum, libindy, etc. and indy-node
# also pins to a specific version, but a version that only exists in master.
# We can't have two versions of indy-plenum, libindy, etc. Use stable until
# sovtoken changes it's '=' designation to '>='.
#repo = "master"
repo = "stable"

# modify this for your timezone
timezone = '/usr/share/zoneinfo/America/Denver'
sshuser = 'vagrant'

# The user must run the setup.sh script before running 'vagrant up'
# Ensure the ssh directory exists and has expected content
filepath = File.expand_path(File.dirname(__FILE__))
directory = File.join("#{filepath}", "ssh")
if !Dir.exists?(directory)
  $stderr.puts "Please run the setup.sh script to setup the SSH configuration "\
    "for this project."
  $stderr.puts "#{directory} not found."
  exit 1
end

ssh_private_key = File.join("#{directory}", "id_rsa")
ssh_public_key = File.join("#{directory}", "id_rsa.pub")
pemfile = File.join("#{directory}", "chaos.pem")
if !File.exists?("#{ssh_private_key}") ||
   !File.exists?("#{ssh_public_key}") ||
   !File.exists?("#{pemfile}")
  $stderr.puts "The ssh directory in the root of this project does not contain"\
    "all the expected files (id_rsa, id_rsa.pub, and chaos.pem)."
  $stderr.puts "Please run the setup.sh script to setup the SSH configuration "\
    "for this project."
  exit 1
end

Vagrant.configure("2") do |config|

  config.vm.define "cli01", autostart: true do |cli|
    cli.vm.box = client_box
    cli.vm.host_name = "cli01"
    cli.vm.network 'private_network', ip: clientip1
    cli.ssh.private_key_path = ['ssh/id_rsa', '~/.vagrant.d/insecure_private_key']
    cli.ssh.username = sshuser
    cli.ssh.insert_key = false
    cli.vm.provider "virtualbox" do |vb|
      vb.name   = "cli01"
      vb.gui    = false
      vb.memory = client_memory
      vb.cpus   = client_cpus
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end
    cli.vm.provision "indy", type: "shell", path: "scripts/client.sh", args: [timezone, nodeiplist, repo]
  end

  config.vm.define "validator01" do |validator|
    validator.vm.box = validator_box
    validator.vm.host_name = "validator01"
    validator.vm.network 'private_network', ip: nodeip1
    validator.ssh.private_key_path = ['ssh/id_rsa', '~/.vagrant.d/insecure_private_key']
    validator.ssh.username = sshuser
    validator.ssh.insert_key = false
    validator.vm.provider "virtualbox" do |vb|
      vb.name   = "validator01"
      vb.gui    = false
     vb.memory = validator_memory
      vb.cpus   = validator_cpus
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end
    validator.vm.provision "indy", type: "shell", path: "scripts/validator.sh", args: ["Node1", nodeip1, "9701", nodeip1, "9702", timezone, nodeiplist, repo]
  end

  config.vm.define "validator02" do |validator|
    validator.vm.box = validator_box
    validator.vm.host_name = "validator02"
    validator.vm.network 'private_network', ip: nodeip2
    validator.ssh.private_key_path = ['ssh/id_rsa', '~/.vagrant.d/insecure_private_key']
    validator.ssh.username = sshuser
    validator.ssh.insert_key = false
    validator.vm.provider "virtualbox" do |vb|
      vb.name   = "validator02"
      vb.gui    = false
      vb.memory = validator_memory
      vb.cpus   = validator_cpus
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end
    validator.vm.provision "indy", type: "shell", path: "scripts/validator.sh", args: ["Node2", nodeip2, "9703", nodeip2, "9704", timezone, nodeiplist, repo]
  end


  config.vm.define "validator03" do |validator|
    validator.vm.box = validator_box
    validator.vm.host_name = "validator03"
    validator.vm.network 'private_network', ip: nodeip3
    validator.ssh.private_key_path = ['ssh/id_rsa', '~/.vagrant.d/insecure_private_key']
    validator.ssh.username = sshuser
    validator.ssh.insert_key = false
    validator.vm.provider "virtualbox" do |vb|
      vb.name   = "validator03"
      vb.gui    = false
      vb.memory = validator_memory
      vb.cpus   = validator_cpus
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end
    validator.vm.provision "indy", type: "shell", path: "scripts/validator.sh", args: ["Node3", nodeip3, "9705", nodeip3, "9706", timezone, nodeiplist, repo]
  end

  config.vm.define "validator04" do |validator|
    validator.vm.box = validator_box
    validator.vm.host_name = "validator04"
    validator.vm.network 'private_network', ip: nodeip4
    validator.ssh.private_key_path = ['ssh/id_rsa', '~/.vagrant.d/insecure_private_key']
    validator.ssh.username = sshuser
    validator.ssh.insert_key = false
    validator.vm.provider "virtualbox" do |vb|
      vb.name   = "validator04"
      vb.gui    = false
      vb.memory = validator_memory
      vb.cpus   = validator_cpus
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end
    validator.vm.provision "indy", type: "shell", path: "scripts/validator.sh", args: ["Node4", nodeip4, "9707", nodeip4, "9708", timezone, nodeiplist, repo]
    validator.vm.provision "file", source: "ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"
  end

end
