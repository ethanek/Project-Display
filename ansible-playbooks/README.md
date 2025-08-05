# Ansible Playbooks 個別說明

- create-proxmox-template: 用於 Proxmox 製作 Template VM 標準化流程。
  - 須先將特定的作業系統 qcow2 檔，存放至 Proxmox VE
  - 透過 Shell Script 指定虛擬機 ID、Proxmox 機器識別名稱、選擇的 qcow2 名稱
  - 檢查檔案存在，開始進行自動化建置，指定機器配置、啟用 cloudinit 功能、配置金鑰與使用者名稱
  - 執行完畢後，現成機器會於 Proxmox 上成功運行，省去手動初始化配置的作業流程時間
  
- proxmox-task-status-check: 用於確認使用 Terraform 建置的虛擬機進度階段，並獲取完成建置的機器 IP Address 資訊。

- resource-application: 用於 Ansible Automation Platform (AAP) 整合，透過表單申請填寫 Proxmox 機器規格，發送後觸發虛擬機在 Proxmox 的"建置／延期／移除"功能

- send-mail: 用於 Ansible Automation Platform (AAP) 整合，透過表單觸發任務，會於虛擬機作業執行完畢時，獲取 Terraform 打印出的特定資訊（如：連接方式）額外彙整寄發 mail 給申請人。

- sno-deploy: 配置標準三臺 Openshift 平臺節點，從虛擬機準備、Bastion 建置到使用 Agent-based Installer 安裝流程進行平臺部署工作。

- terraform: 存放克隆與創建虛擬機的標準配置設定。