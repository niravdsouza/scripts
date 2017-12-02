#!/bin/bash

## Pre-req
#1. Copy all scripts and vagrantfile to /src folder
#2. Ensure access to internet is present
#3. Rajeev's script is added to this repo in the same folder
#4. In mnVagrantFile, in the last para, add the script to be run

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
yum install VirtualBox-5.2

## Fedora 27/26/25/24/23/22/21/20/19 and CentOS/RHEL 7 ##
/usr/lib/virtualbox/vboxdrv.sh setup

## install vagrant + dependent rpm (rsync) 
yum -y install https://releases.hashicorp.com/vagrant/2.0.1/vagrant_2.0.1_x86_64.rpm rsync

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


