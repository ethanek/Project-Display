output "staticIp" {
  value = element(split("/", split("=", split(",", proxmox_vm_qemu.clone_template.0.ipconfig0)[0])[1]), 0)
}
