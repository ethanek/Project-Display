output "master" {
  value = "${proxmox_vm_qemu.master[0].default_ipv4_address}"
}

output "worker1" {
  value = "${proxmox_vm_qemu.worker1[0].default_ipv4_address}"
}
output "worker2" {
  value = "${proxmox_vm_qemu.worker2[0].default_ipv4_address}"
}
