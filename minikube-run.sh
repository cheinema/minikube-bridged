#!/bin/bash

function die {
    echo "$@" >&2
    exit 1
}

VM_NAME=minikube
VM_MEMORY=4096

# Check minikube exists
MINIKUBE=$(which 'minikube' 2>/dev/null) || die 'Minikube not found in path!'

# Check VBoxManage exists
VBOX_MANAGE_SEARCH=${VBOX_MSI_INSTALL_PATH+$(/usr/bin/realpath "$VBOX_MSI_INSTALL_PATH")/}VBoxManage
VBOX_MANAGE=$(which "$VBOX_MANAGE_SEARCH" 2>/dev/null) || die "File ${VBOX_MANAGE_SEARCH} not found! Put to path or set env variable VBOX_MSI_INSTALL_PATH!"

# Check VM exists
if ! "$VBOX_MANAGE" showvminfo "$VM_NAME" &>/dev/null; then
    # Get name of first WiFi Adapter
    WIFI_ADAPTER=$(netsh wlan show interfaces | grep -oP "(Beschreibung|Description)\s+: \K.+" | head -1)
    test -n "$WIFI_ADAPTER" || die "No WiFi Adapter found!"

    # Create new VM
    echo "Virtual machine $VM_NAME does not exist yet! Starting setup ..."
    cd ~ # otherwise Minikube could not find the ISO image if `pwd` is on another Windows drive than $HOME
    "$MINIKUBE" start --memory "$VM_MEMORY" --vm-driver="virtualbox" && "$MINIKUBE" stop || die "Minikube startup failed!"

    # Modify network
    echo "Change NIC mode from NAT to Briged using adapter $WIFI_ADAPTER ..."
    "$VBOX_MANAGE" modifyvm "$VM_NAME" --nic1 bridged --bridgeadapter1 "$WIFI_ADAPTER"
fi

# Validate Network setup: NAT is not allowed
NIC_TYPES=$("$VBOX_MANAGE" showvminfo "$VM_NAME" --details --machinereadable | dos2unix | egrep '^nic[0-9]=' | grep -v 'none' | sort | paste -sd',')
[ "$NIC_TYPES" == 'nic1="bridged",nic2="hostonly"' ] || die "Invalid NIC types detected: $NIC_TYPES"

# Always start SSH port forwarding (in new window)
SELF_DIR=$(dirname "$0")
start "Minikube SSH forwarding" /bin/bash "$SELF_DIR/minikube-ssh-forward.sh"

# Is minikube already running?
if "$VBOX_MANAGE" showvminfo "$VM_NAME" --machinereadable | dos2unix | egrep '^VMState=' | grep -q 'running'; then
    echo 'Minikube is already running.'
else
    "$MINIKUBE" start || die 'Minikube could not be started!'
fi
