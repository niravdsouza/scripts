#! /bin/bash

controller_ip=
compute_ips=
network_ip=
hostnames=

scriptHelper() {
    echo "
    The script takes 3 mandatory arguments.
    Mandatory Arguments:
        1) controller: The IP Address of the controller.
        2) compute: The IP addresses of compute nodes separated by comma.
        3) network: The IP address of the network node.

    Example:
    ./controller.sh -controller \"192.168.1.1\" -compute \"192.168.1.2,192.168.1.3\" -network \"192.168.1.4\"
    "
    exit
}

# Reference for parsing arguments are taken from 
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash/13359121?noredirect=1#comment29656357_13359121
while [ "$#" -gt 0 ]; do
  case "$1" in
    -controller) 
        controller_ip="$2" 
        shift 2;;
    -compute) 
        IFS=', ' read -r -a compute_ips <<< "$2"
        shift 2;;
    -network) 
        network_ip="$2" 
        shift 2;;
    *) scriptHelper;;
  esac
done

if [ "$controller_ip" == "" ] || [ "$compute_ips" == "" ] || [ "$network_ip" == "" ]; then
    scriptHelper
fi

# $1: IP address to ssh.
_ssh () {
    typeset -f | ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $1 "
    $(cat)
    $2
    "
}

_exit () {
    stty echo
    exit
}

killTimer=
#$1: Command to run.
kill_after () {
    if [ "$killTimer" == "0" ]; then
        echo "Kill Timer not set properly"
        _exit
    fi

    $@ > /dev/null 2>&1 &
    cmd=`echo "$@"`
    count=0
    while true
    do
        sleep 1
        alive=`ps aux | grep "$cmd" | grep -v grep | awk '{print $2}'`

        # Process completed.
        if [ "$alive" == "" ]; then
            break
        fi
        count=`expr $count + 1`

        # Kill on timeout.
        if [ $count -eq $killTimer ]; then
            kill -9 $alive
            echo "Killed"
            return
        fi
    done

    if [ $count -lt 3 ]; then
        echo "No Route"
        return
    fi

    echo "OK"
}

# SSH into all the ips provided as argument and get the IP-hostname mapping.
# $1: IP address to verify access.
verifyAccess () {
    killTimer=7
    ret=`kill_after ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$1 sleep 5`
    if [ "$ret" != "OK" ]; then
        echo "
ERROR: Unable to ssh as root to $1 using keys. Please fix the connectivity/access issue"
        stty echo
        _exit
    fi
}

#Reference: https://stackoverflow.com/questions/929368/how-to-test-an-internet-connection-with-bash
verifyInternetAccess () {
    ret=`_ssh $1 "ping -q -w 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error"`
    if [ "$ret" == "error" ]; then
        echo "
ERROR: Unable to connect to internet at $1."
        _exit
    fi
}

getHostName () {
    hostnames="$hostnames 
$1  `_ssh root@$1 "hostname"`"
}

# The string containing the mapping of IP to hostname is expected.
installBaseImageAndHosts() {
    _ssh $1 "echo \"$2\" >> /etc/hosts"
    _ssh $1 "yum update -y" > /dev/null 2>&1
    _ssh $1 "yum install net-tools -y" > /dev/null 2>&1
}

installPackStack() {
    yum install -y centos-release-openstack-newton > /dev/null 2>&1
    yum update -y > /dev/null 2>&1
    yum install -y openstack-packstack > /dev/null 2>&1
}

updateAnswersFile() {
    sudo packstack --gen-answer-file=~/answers.cfg

    all_compute=
    for ip in "${compute_ips[@]}"
    do
        if [ "$all_compute" == "" ]; then
            all_compute=$ip
        else
            all_compute="$all_compute,$ip"
        fi
    done
    sed -ie "s/^CONFIG_COMPUTE_HOSTS=.*/CONFIG_COMPUTE_HOSTS=$all_compute/" ~/answers.cfg
    sed -ie "s/^CONFIG_NETWORK_HOSTS=.*/CONFIG_NETWORK_HOSTS=$network_ip/" ~/answers.cfg
}

# Packstack answer file is expected as answer.
runPackStack() {
    sudo packstack --answer-file=~/answers.cfg
}

postPackStack() {
    yum install openstack-utils -y > /dev/null
}

initiateOpenStackSetup() {

    # Verify that there is access.
    echo "TEST: Testing if root SSH access is available"
    verifyAccess $controller_ip
    verifyAccess $network_ip
    for ip in "${compute_ips[@]}"
    do
        verifyAccess $ip
    done
    echo "SUCCESSFUL: All systems have SSH root access."

    # Verify that there is internet access for the hosts.
    echo "TEST: Testing if internet access is available to all the devices"
    verifyInternetAccess $controller_ip > /dev/null 2>&1
    verifyInternetAccess $network_ip > /dev/null 2>&1
    for ip in "${compute_ips[@]}"
    do
        verifyInternetAccess $ip > /dev/null 2>&1
    done
    echo "SUCCESSFUL: All systems have internet access."

    # Get the hostname for DNS resolution.
    echo "Retreieving hostnames of devices for local DNS resolution"
    getHostName $controller_ip > /dev/null 2>&1
    getHostName $network_ip > /dev/null 2>&1
    for ip in "${compute_ips[@]}"
    do
        getHostName $ip > /dev/null 2>&1
    done
    echo "SUCCESSFUL: DNS for system resolved locally"

    # Install the base images.
    echo "Initiating software update"
    installBaseImageAndHosts $controller_ip "$hostnames"
    installBaseImageAndHosts $network_ip "$hostnames"
    for ip in "${compute_ips[@]}"
    do
        installBaseImageAndHosts $ip "$hostnames"
    done
    installPackStack
    echo "SUCCESSFUL: Software Update Complete"

    echo "Initiating Openstack Installation. This step takes around 30-35 minutes."
    updateAnswersFile
    runPackStack > /dev/null
    echo "SUCCESSFUL: Openstack installed"

    echo "Installing Openstack CLI"
    postPackStack
    echo "SUCCESSFUL: Openstack CLI installaed"

    echo "SUCCESSFUL: Openstack Installation Complete."
}

# Allow logs with keyword error
#initiateOpenStackSetup 2>&1 | grep ERROR

initiateOpenStackSetup
