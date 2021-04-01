# cloudynitzar [![Build Status](https://travis-ci.org/Clommunity/cloudynitzar.svg?branch=master)](https://travis-ci.org/Clommunity/cloudynitzar)

### About
Cloudynitzar is a shell script that turns your plain Debian or Ubuntu system into a community networking cloud in a box (i.e. a full-featured Cloudy device). It might as well work on Debian and Ubuntu derivatives, like Linux Mint. Feel free to test and report!

### Requirements
*Recommended*: a fresh and updated Debian 10 *Buster* installation with `curl`, `lsb-release` and an Internet connection.

Cloudynitzar will also work on a Debian 9 *Stretch* installation. It has also been tested on Ubuntu 18.04 and Raspian.

### Procedure
From your Debian system run, as root:

```sh
apt-get update; apt-get install -y curl lsb-release
curl -k https://raw.githubusercontent.com/Clommunity/cloudynitzar/master/cloudynitzar.sh | bash -
```

and let the magic begin! After the process has finished, you can browse the Cloudy web interface at [http://cloudy_device_ip:7000](http://cloudy_device_ip:7000).

In order to Cloudynitzar  serveral machines you can use Ansible:

- The first step that you must do is add your hosts on [hosts file](./hosts)
- Then, you should launch the next command:

```sh
ansible-playbook -i hosts playbook.yml --ask-pass --extra-vars "hosts=cloudy user=your_user_name"
```

**NOTE:** To proceed with this step you will need [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) installed.

### Log
The output of the whole Cloudynitzar process is logged to `/var/log/cloudy/cloudynitzar.log`.

## Ansible and Deployment

ansible-galaxy install xanmanning.k3s

Ansible is an extremely powerful tool that can automate all stages of a deployment lifecycle. 

python-apt must be installed to use check mode

### Use Cases and Workflows

* Convert a base OS install into a Cloudy node
* Convert one or more Cloudy nodes into a Kubernetes cluster
* Add or remove nodes from an existing Kubernetes cluster

base-to-cloudy-playbook.yml
cloudy-nodes-to-kube-cluster.yml
add-remove-kube-nodes.yml



### Inventory

We seperate inventory into three groups: Cloudy only hosts, K3s masters, and K3s workers.

By grouping inventory like this we can target only specific subsets of all hosts. 

### Roles

The roles/ directory contains the Ansible roles.

The directory structure is

```
group_vars/
    Variable files defined per inventory group
roles/
    <role_name>/
        meta/
            Metadata for Ansible Galaxy.
        tasks/
            Task files
        vars/
            Variables files
```

The current roles are:

    * k3s-worker: A worker node.
    * k3s-master: k3s node acting as the master. All worker nodes must join via the master.
    * cloudy: A host with cloudy installed. This is currently (30-Mar-2021) applied to all hosts.