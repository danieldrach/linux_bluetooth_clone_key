#!/bin/bash

# Global constants / definitions
IFS='\n' # internal field separator, serves to define how bash will parse the commands
MOUNTING_POINT='/media/windows' # defining where to mount the windows partition
WIN_PARTITION_DEV=$(sudo fdisk -l | grep "Microsoft basic data" | grep -o "/dev/\w*") # Identifying the partition/device where windows data is
WIN_MOUNTING_POINT="/mnt/windows_os_data" # where the windows partition will be mounted

echo "Detected windows partition in device: $WIN_PARTITION_DEV"

declare -a DEVICES_NAMES=()
declare -a DEVICES_MAC_ADDR=()
declare chosen_index

# getting mac addresses and number of devices
MAC_ADDR_BLUE_CARD_UP=`bluetoothctl list | grep -o "..:..:..:..:..:.."`
MAC_ADDR_BLUE_CARD_LW=${MAC_ADDR_BLUE_CARD_UP,,}
PTH_WIN_REG="\ControlSet001\Services\BTHPORT\Parameters\Keys\\${MAC_ADDR_BLUE_CARD_LW//:}"

cnt=0
while read -r line; do cnt=$((cnt+1)) DEVICES_NAMES[$cnt]=$line; done < <(bluetoothctl devices | grep -Po "(?<=..:..:..:..:..:..\s).*")
cnt=0
while read -r line; do cnt=$((cnt+1)) DEVICES_MAC_ADDR[$cnt]=$line; done < <(bluetoothctl devices | grep -Po "..:..:..:..:..:..")

for ((i=1; i <= ${#DEVICES_NAMES[@]}; i++ )); do echo "$i: ${DEVICES_NAMES[$i]}"; done
read -p "Select the bluetooth device to have its key cloned from Windows: "

CHOSEN_DEVICE_NAME=${DEVICES_NAMES[$REPLY]}
CHOSEN_DEVICE_MAC_UP_DOTS=${DEVICES_MAC_ADDR[$REPLY]} # this naming convention is used in the linux filesistem to find the config file
CHOSEN_DEVICE_MAC_UP=${DEVICES_MAC_ADDR[$REPLY]//:}
CHOSEN_DEVICE_MAC_LW=${CHOSEN_DEVICE_MAC_UP,,} # this naming convention is used inside the windows registry
LINUX_INFO_FILE_PTH="/var/lib/bluetooth/$MAC_ADDR_BLUE_CARD_UP/$CHOSEN_DEVICE_MAC_UP_DOTS/info"

# Mounting windows drive into the filesystem 
if mountpoint -q "$WIN_MOUNTING_POINT"; then eval "sudo umount $WIN_MOUNTING_POINT"; fi
eval "sudo [ -e $WIN_MOUNTING_POINT ] && sudo rmdir $WIN_MOUNTING_POINT"
eval "sudo mkdir -p $WIN_MOUNTING_POINT"
eval "sudo mount -o ro $WIN_PARTITION_DEV $WIN_MOUNTING_POINT"
PTH_WIN_CFG="$WIN_MOUNTING_POINT/Windows/System32/config/SYSTEM"

# Retrieving bluetooth key negotiated by windows from the windows registry
TARGET_KEY_LW=$(eval "reged -x $PTH_WIN_CFG 'HKEY_LOCAL_MACHINE\SYSTEM' '$PTH_WIN_REG' /dev/stdout | grep $CHOSEN_DEVICE_MAC_LW" | grep -o "..,..,..,..,..,..,..,..,..,..,..,..,..,..,..,..")
TARGET_KEY_LW="${TARGET_KEY_LW//,}"
TARGET_KEY_UP="${TARGET_KEY_LW^^}"
echo "You chose: $CHOSEN_DEVICE_NAME, this device has the MAC address: $CHOSEN_DEVICE_MAC_UP, and the Key: $TARGET_KEY_UP is registered in Windows."

# Unmounting windows drive and removing associated mounting directory 
if mountpoint -q "$WIN_MOUNTING_POINT"; then eval "sudo umount $WIN_MOUNTING_POINT"; fi
eval "sudo [ -e $WIN_MOUNTING_POINT ] && sudo rmdir $WIN_MOUNTING_POINT"

# retrieving the key currently configured in the linux system for the chosen bluetooth device
BLT_CURRENT_KEY=$(eval "sudo cat $LINUX_INFO_FILE_PTH" | grep -Po "(?<=Key=)\w+")
echo "The key configured in linux for this device is: $BLT_CURRENT_KEY"

#replacing linux key for the key configured in windows for that device 
while true; do
    read -p "Do you wish to replace the configured bluetooth key for $CHOSEN_DEVICE_NAME? [Y or N]: " yn
    case $yn in
        [Yy]* ) eval "sudo sed -i "s/$BLT_CURRENT_KEY/$TARGET_KEY_UP/" $LINUX_INFO_FILE_PTH";break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done