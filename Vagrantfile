# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "centos_tester"
  config.vm.hostname = "tester"
  config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-puppet.box"
  config.vm.box_check_update
  config.vm.network "forwarded_port", guest: 80, host: 8000
  #config.vm.provision :shell, path: "config.sh"
end
