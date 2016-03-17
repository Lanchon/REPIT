#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### i9100

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:galaxys2:*) ;;
        *:i9100:*) ;;
        *:GT-I9100:*) ;;
        *:GT-I9100M:*) ;;
        *:GT-I9100P:*) ;;
        *:GT-I9100T:*) ;;
        *:SC-02C:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

### code after this comment is old and no longer used. it is here for documentation purposes only.

device_detectBlockDeviceSize_i9100() {

    # this is unused code from when detectBlockDeviceHeapRange had not yet been implemented.
    # it is here for documentation purposes only, ports to other devices should delete this function.

    info "detecting eMMC size"

    local deviceSize=$(cat $sdev/size)
    local heapEnd8GB=15261696
    local heapEnd16GB=30769152
    local heapEnd32GB=62513152
    if [ $(( deviceSize < heapEnd8GB )) -ne 0 ]; then
        fatal "eMMC size too small"
    elif [ $(( deviceSize < heapEnd16GB )) -ne 0 ]; then
        heapEnd=$heapEnd8GB
        info "eMMC size is 8 GB"
    elif [ $(( deviceSize < heapEnd32GB )) -ne 0 ]; then
        heapEnd=$heapEnd16GB
        info "eMMC size is 16 GB"
    else
        heapEnd=$heapEnd32GB
        info "eMMC size is 32 GB"
    fi

}

device_configureStockLayout_i9100() {

    # this is unused code from when the configuration parser had not yet been implemented.
    # it is here for documentation purposes only, ports to other devices should delete this function.

    # stock partition layout for i9100:

    system_size=0.5
    data_size=2
    #sdcard_size=11.5078
    sdcard_size=max
    preload_size=0.5

    system_fs=ext4
    data_fs=ext4
    sdcard_fs=vfat
    preload_fs=ext4

}
