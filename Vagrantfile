BUSTER_IMAGE = "debian/buster64"
BIONIC_IMAGE = "bento/ubuntu-18.04"
FOCAL_IMAGE = "bento/ubuntu-20.04"
IMAGE_NAME = BIONIC_IMAGE
N = 1

Vagrant.configure("2") do |config|
    config.vm.network "forwarded_port", guest: 7000, host: 7000

    config.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 2
    end

    config.ssh.insert_key = false
      
    (1..N).each do |i|
        config.vm.define "cloudy-host-#{i}" do |node|
            node.vm.box = IMAGE_NAME
            node.vm.hostname = "cloudy-vm#{i}"
            node.vm.provision "ansible" do |ansible|
                ansible.playbook = "playbook.yml"
            end
        end
    end
end
