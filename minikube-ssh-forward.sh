#!/bin/bash

VM_NAME=minikube
DOCKER_MACHINE_CONFIG=${MINIKUBE_HOME-~}/.minikube/machines/${VM_NAME}/config.json

function die {
    echo "$@" >&2
    exit 1
}

# Check VBoxManage exists
VBOX_MANAGE_SEARCH=${VBOX_MSI_INSTALL_PATH+$(/usr/bin/realpath "$VBOX_MSI_INSTALL_PATH")/}VBoxManage
VBOX_MANAGE=$(which "$VBOX_MANAGE_SEARCH" 2>/dev/null) || die "File ${VBOX_MANAGE_SEARCH} not found! Put to path or set env variable VBOX_MSI_INSTALL_PATH!"

# Read local SSH port (expected by docker-machine)
[ -r "$DOCKER_MACHINE_CONFIG" ] || die "File $DOCKER_MACHINE_CONFIG not found!"
LOCAL_SSH_PORT=$(grep SSHPort "$DOCKER_MACHINE_CONFIG" | grep --perl-regexp --only-matching '\d+')
[ -n "$LOCAL_SSH_PORT" ] || die "No SSH port in $DOCKER_MACHINE_CONFIG found!"
echo "Local SSH port: $LOCAL_SSH_PORT"

# Wait until VM is started
echo -n 'Waiting until Virtual Machine is running...'
while ! "$VBOX_MANAGE" showvminfo "$VM_NAME" --machinereadable | egrep '^VMState=' | grep -q 'running'; do
    echo -n '.'
    sleep 5
done
echo

# Get IP of running VM
echo -n 'Waiting for Virtual Machine IP...'
VM_IP=
while [ -z "$VM_IP" ]; do
    VM_IP=$(grep IPAddress "$DOCKER_MACHINE_CONFIG" | grep --perl-regexp --only-matching '\d+\.\d+\.\d+\.\d+')
    if test -z "$VM_IP"; then
        echo -n '.'
        sleep 5
    fi
done
echo " $VM_IP"

# Start SSH port forwarding
echo 'SSH port forwarding started'
SELF_DIR=$(dirname "$0")
while ! /usr/bin/perl "$SELF_DIR/tcp-proxy2.pl" "${LOCAL_SSH_PORT}" "${VM_IP}:22"; do
    sleep 1
    echo 'Restart SSH port forwarding after unexpected termination'
done
