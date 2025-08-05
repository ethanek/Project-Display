# 配置使用 Provider
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.8.0"
    }
  }
}

# proxmox 權限
provider "proxmox" {
  pm_tls_insecure     = true
  pm_api_url          = "https://${var.provider_ip}:8006/api2/json"
  pm_api_token_id     = var.token_id
  pm_api_token_secret = var.token_secret
}

# 創建或 clone VM
resource "proxmox_vm_qemu" "create_template" {
  count       = 1
  name        = var.vm_name
  target_node = var.proxmox_host
  clone       = var.template_name
  full_clone  = true
  agent       = 1
  os_type     = "cloud_init"
  onboot      = true

  # CPU
  cores   = var.cpu_cores
  sockets = 1

  # 內存
  memory   = var.memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  # 硬碟設置
  disk {
    size    = "32G"
    type    = "scsi"
    storage = "local-lvm"
  }

  # 網路
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=dhcp"

  provisioner "local-exec" {
    when    = create
    command = "echo ${self.default_ipv4_address} >> ip.txt"
  }
}
