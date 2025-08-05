#配置使用 Provider
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=1.0.0"
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

# 創建或 clone VM        # ！"create_vm" 請自行重新命名，否則會覆蓋掉已有 VM！
resource "proxmox_vm_qemu" "create_template" {
  count       = 1
  name        = var.vm_name              # ！請避免與其他已存在之 VM 相同名稱，否則會覆蓋掉已有 VM！
  target_node = var.proxmox_host  
  iso = "local:iso/${var.iso_file_name}" 
  # vmid = 170    # 指定 VM ID （先確認是否有 VM 占用該 ID ）

  agent   = 0
  onboot  = true
  
  # CPU
  cores   = var.cpu_cores 
  sockets = 1  
  
  # 內存
  memory  = var.memory
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
}
