#! /bin/sh

# Please set the following env before you run the script:
#PVE_TOKEN_ID=
#PVE_TOKEN_SECRET=
#PVE_ENDPOINT=
set -e

name=$1

node=proxmox2-2
vmid=$2
# APIs
path_list_node=/api2/json/nodes
path_list_vm=/api2/json/nodes/$node/qemu

authorization_data="PVEAPIToken=$PVE_TOKEN_ID=$PVE_TOKEN_SECRET"

function printErr() {
    err="\nInvalid input, Please enter the correct command.\n\nfor example: ls, rm\n"
    echo -e $err
}

function callProxmoxAPI() {
    method=$1
    path=$2
    curl -X $method -k -H "Authorization: $authorization_data" "https://$PVE_ENDPOINT$path"
}

function listVMs() {
    echo $(callProxmoxAPI GET $path_list_vm)
}

function getVMCurrentStatus() {
    vmid=$1
    echo $(callProxmoxAPI GET $path_list_vm/$vmid/status/current | jq -r '.data | .status')
}

function shutdownVM() {
    vmid=$1
    echo $(callProxmoxAPI POST $path_list_vm/$vmid/status/shutdown)
}

function stop() {
    vmid=$1
    echo $(callProxmoxAPI POST $path_list_vm/$vmid/status/stop)
    if [[ "$response" == *"error"* ]]; then
        echo "關閉虛擬機 $vmid 時發生錯誤：$response"
    else
        echo "虛擬機 $vmid 關閉請求已發送"
    fi
}

function deleteVM() {
    vmid=$1
    echo $(callProxmoxAPI DELETE $path_list_vm/$vmid)
}

function startVM() {
    vmid=$1
    echo $(callProxmoxAPI POST $path_list_vm/$vmid/status/start)
}

function deleteVMbyName() {
    name=$1
    vmid=$(listVMs | jq -r ".data[] | select(.name==\"$name\") | .vmid")
    echo " vmid ： $vmid"
    if [ "$vmid" = "" ]
    then
        echo "[error] vm not found"
        exit 1
    fi

    stop $vmid
    status=$(getVMCurrentStatus $vmid)  
    echo "Waiting for VM $vmid to stop..."
    while [ $status != "stopped" ]
    do
        echo "Current status: $status"
        status=$(getVMCurrentStatus $vmid)
        sleep 1
    done

    echo "VM $vmid has stopped. Deleting..."
    sleep 10
    echo $(deleteVM $vmid)
}


function updateVM() {
    vm_name="$1"
    days_to_extend="$2"
    echo "UpdateVM function called with parameters: vm_name=$vm_name, days_to_extend=$days_to_extend"

    local vm_info=$(callProxmoxAPI GET $path_list_vm)
    local found=false
    vm_name_list=$(echo "$vm_info" | jq -r '.data[].name')

    for vm in $vm_name_list; do
        if [ "$vm" = "$vm_name" ]; then
            found=true
            break
        fi
    done

    if [ "$found" = true ]; then
        echo "VM found"
        # 抓vm_name的expired_unix值
        expired_unix=$(echo "$vm_name" | grep -E -o "^[0-9]{10}")
        echo "expired_unix: $expired_unix"

        # 延期天數轉換為expired_unix值
        seconds_to_extend=$((days_to_extend * 24 * 60 * 60))
    
        # 計算新的expired_unix值+名稱
        new_expired_unix=$((expired_unix + seconds_to_extend))
    
        # 抓除了expired_unix值以外的資訊
        vm_info_prefix=$(echo "$vm_name" | sed "s/$expired_unix//")
        
        # 新的虛擬機expired_unix+名稱
        new_vm_name="${new_expired_unix}${vm_info_prefix}"
    
        echo "New VM Name: $new_vm_name"

        changeVMName "$vm_name" "$new_vm_name"
    else
        echo "VM not found"
    fi
    # 列印當前時間的expired_unix值
    current_time_expired_unix=$(date +%s)
    echo "當前時間的expired_unix值: $current_time_expired_unix"    
}


function changeVMName() {
    vm_name="$1"
    new_vm_name="$2"

    local vm_info=$(callProxmoxAPI GET $path_list_vm)

    # 找vmid
    vmid=$(echo "$vm_info" | jq -r ".data[] | select(.name == \"$vm_name\" ) | .vmid")
    echo "vm_name: $vm_name"
    echo "new_vm_name: $new_vm_name"
    echo "vmid: $vmid"

    if [ -n "$vmid" ]; then
        # 使用 Proxmox VE API 修改虛擬機名稱
        set -x
        response=$(curl -i -X PUT -k -H "Authorization: $authorization_data" -H "Content-Type: application/json" -d "{\"name\": \"$new_vm_name\"}" "https://$PVE_ENDPOINT$path_list_vm/$vmid/config")
        set +x
        echo "API Response: $response"
    fi

}

function deleteExpiredVMs() {
    echo "正在刪除過期的虛擬機..."

    local current_time_expired_unix=$(date +%s)
    echo "當前時間的 expired_unix 值: $current_time_expired_unix"
    local deleted_vms=()  # 存儲被刪除的虛擬機名稱的陣列

    # 獲取虛擬機信息
    local vm_info=$(callProxmoxAPI GET $path_list_vm)
    local vm_list=$(echo "$vm_info" | jq -c '.data[]')

    for vm_data in $vm_list; do
        local vm_name=$(echo "$vm_data" | jq -r '.name')

        # 檢查虛擬機名稱是否包含 expired_unix 值
        if echo "$vm_name" | grep -qE "^[0-9]{10}"; then
            local expired_unix=$(echo "$vm_name" | grep -E -o "^[0-9]{10}")

            # 如果 expired_unix 值小於當前時間的 expired_unix 值，則刪除虛擬機
            if [ "$expired_unix" -lt "$current_time_expired_unix" ]; then
                echo "正在刪除過期的虛擬機: $vm_name"

                # 調用 deleteVMbyName 函數
                deleteVMbyName "$vm_name"

                # 將被刪除的虛擬機名稱添加到陣列
                deleted_vms+=("$vm_name")
            fi
        fi
    done

    if [ ${#deleted_vms[@]} -gt 0 ]; then
        echo "過期虛擬機刪除完成。被刪除的虛擬機: ${deleted_vms[@]}"
    else
        echo "目前沒有過期的虛擬機。"
    fi
}

if [ $# -eq 0 ] ; then
    printErr
else
    cmd=$1
    shift
    if [ "$cmd" = "rm" ]; then
        deleteVMbyName $@
    elif [ "$cmd" = "ls" ]; then
        listVMs | jq -r '.data[].name'
    elif [ "$cmd" = "updateVM" ]; then
        vm_name=$1
        days_to_extend=$2
        updateVM "$vm_name" "$days_to_extend"
    elif [ "$cmd" = "deleteExpiredVMs" ]; then  
        deleteExpiredVMs
    else
        printErr
    fi
fi