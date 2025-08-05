# 配置使用 Provider
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
resource "proxmox_vm_qemu" "clone_template" {
  count       = 1
  name        = "${var.vm_name}${count.index}"          # ！請避免與其他已存在之 VM 相同名稱，否則會覆蓋掉已有 VM！
  target_node = var.proxmox_host  
  clone      = var.template_name
  # vmid = 170    # 指定 VM ID （先確認是否有 VM 占用該 ID ）
  full_clone = true

  agent   = 0
  onboot  = true

  # CPU
  cores   = var.cpu_cores 
  sockets = 1  
  
  # 內存
  memory  = var.memory
  scsihw   = "virtio-scsi-pci"
  
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

  # Cloud-Init
  os_type   = "cloud-init"
  # ipconfig0 = "ip=dhcp"
  ipconfig0 = "ip=${var.static_ip}/24,gw=${var.gateway}"
  ssh_user = var.user           # VM 帳號
  # cipassword = var.password     # VM 密碼
  # nameserver   = var.dns_server
  # searchdomain = var.domain_name

  # 遠端 VM 公鑰，無密碼登入
  sshkeys = file(var.ssh_public_key)
}
