#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### d710

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:epic4gtouch:*) ;;
        *:SPH-D710:*) ;;
        *:d710:*) ;;
        *:smdk4210:*) ;;
        *:SPH-D710VMUB:*) ;;
        *:SPH-D710BST:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}
