#!/bin/bash


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

## install ansible
yum install ansible -y 

## create vagrant directory for compute-node
mkdir ~/compute-node 
cp /src/comVagrantFile ~/compute-node/VagrantFile


## create vagrant directory for network-node
mkdir ~/network-node 
cp /src/netVagrantFile ~/network-node/VagrantFile

## create vagrant directory for management-node
mkdir ~/management-node 
cp /src/mnVagrantFile ~/management-node/VagrantFile

## run the compute-node
cd ~/compute-node
vagrant up

## run the network-node
cd ~/network-node
vagrant up

## run the management-node
cd ~/management-node
vagrant up


## run the ansible to install the openstack
ansible-playbook -i inventory ansible.yaml

## ansible 
#1. first install packstack 
#2. create default answer file
#3. run the userinput script which will edit answer file.
#4. run the packstack with answer file.

## Pre-req
#1. copy the inventory file to the iso images. 
#2. copy the ansible.yaml file to the iso images. 
#3. copy the vagrant-file's to the iso images. 
#4. copy the installation scripts to the iso images. (you can ignore this)
