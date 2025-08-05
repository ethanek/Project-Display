#!/bin/bash

function create_template() {
    Print all of the configuration
    echo "Creating template $2 ($1) tmp: $3"

    qm create $1 --name $2 --ostype l26

    qm set $1 --net0 virtio,bridge=vmbr0

    qm set $1 --memory 1024 --cores 4 --cpu host
    #Set boot device to new file
    qm set $1 --scsi0 ${storage}:0,import-from="$(pwd)/$3",discard=on

    qm set $1 --boot order=scsi0 --scsihw virtio-scsi-pci

    qm set $1 --agent enabled=1,fstrim_cloned_disks=1

    qm set $1 --ide2 ${storage}:cloudinit

    qm set $1 --ipconfig0 "ip6=auto,ip=dhcp"

    qm set $1 --sshkeys ${ssh_keyfile}

    qm set $1 --ciuser ${username}
    qm disk resize $1 scsi0 8G

    qm template $1
}
export username=admin
export storage=local-lvm


create_template 900  "Rocky8-Template" "Rocky-8-GenericCloud.latest.x86_64.qcow2" 

