#!/bin/bash

## Pre-req
#1. Copy all scripts and vagrantfile to /src folder
#2. Ensure access to internet is present
#3. Rajeev's script is added to this repo in the same folder
#4. In mnVagrantFile, in the last para, add the script to be run

## Creating all requisite directories
mkdir -p /openstack
cp controller.sh /openstack
## create vagrant directory for compute-node
mkdir -p /openstack/compute-node 
cp comVagrantFile /openstack/compute-node/Vagrantfile
## create vagrant directory for network-node
mkdir -p /openstack/network-node 
cp netVagrantFile /openstack/network-node/Vagrantfile
## create vagrant directory for management-node
mkdir -p /openstack/management-node 
cp mnVagrantFile /openstack/management-node/Vagrantfile

cd /etc/yum.repos.d/


## Install wget
yum install wget

## CentOS 7.4/6.9 and Red Hat (RHEL) 7.4/6.9 users
wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo

## Fedora 21/20/19/18/17/16 and CentOS/RHEL 7/6/5 ##
yum update

rpm -qa kernel |sort -V |tail -n 1

uname -r

## CentOS 7 and RHEL 7 ##
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

## Fedora 21/20/19/18/17/16 and CentOS/RHEL 7/6/5 ##
yum install binutils gcc make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel dkms

## CentOS/RHEL 7/6 ##
yum install VirtualBox-5.1

## Fedora 27/26/25/24/23/22/21/20/19 and CentOS/RHEL 7 ##
/usr/lib/virtualbox/vboxdrv.sh setup

## install vagrant + dependent rpm (rsync) 
yum -y install https://releases.hashicorp.com/vagrant/1.9.6/vagrant_1.9.6_x86_64.rpm rsync

## run the compute-node
cd /openstack/compute-node 
vagrant up

## run the network-node
cd /openstack/network-node
vagrant up

## run the management-node
cd /openstack/management-node
vagrant up

## Copy keys so that packstack can run
cp /openstack/compute-node/.vagrant/machines/default/virtualbox/private_key /openstack/ComputeNode
cp /openstack/network-node/.vagrant/machines/default/virtualbox/private_key /openstack/NetworkNode

cd /openstack/management-node
vagrant ssh << EOF
  touch SSHWorks
EOF
