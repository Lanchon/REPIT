#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### sc02c

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
