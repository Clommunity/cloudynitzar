BUSTER_IMAGE = "debian/buster64"
BIONIC_IMAGE = "bento/ubuntu-18.04"
FOCAL_IMAGE = "bento/ubuntu-20.04"
IMAGE_NAME = BIONIC_IMAGE
N = 1

Vagrant.configure("2") do |config|
    config.vm.network "forwarded_port", guest: 7000, host: 7000
    config.vm.network "public_network", bridge: "br0"
    config.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 2
    end

    config.ssh.insert_key = false
    config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/me.pub"
    config.vm.provision "shell", inline: <<-SHELL
        cat /home/vagrant/.ssh/me.pub >> /home/vagrant/.ssh/authorized_keys
        SHELL
      

    (1..N).each do |i|
        config.vm.define "cloudy-host-#{i}" do |node|
            node.vm.box = IMAGE_NAME
            node.vm.hostname = "cloudy-vm#{i}"
        end
    end
end
