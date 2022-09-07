Vagrant.configure("2") do |config|
  # if you don't want to use docker
  config.vm.box = "bento/ubuntu-20.04"

  # https://stackoverflow.com/a/45251752
  config.vm.synced_folder "#{Dir.home}/.aws", "/home/vagrant/.aws"

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true

    vb.cpus = "2"
    # Customize the amount of memory on the VM:
    vb.memory = "2048"
  end
  config.vm.provision "docker" do |d|
    d.post_install_provision "shell", privileged: false, inline: <<-SHELL
    # https://elrey.casa/bash/scripting/harden
    set -euxvo pipefail
    curl -fsSL 'https://git.io/JtVlL' | sudo bash -xs
    sudo apt-get install -y vagrant
SHELL

    d.build_image "/vagrant/src"
  end

end
