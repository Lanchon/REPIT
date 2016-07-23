#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### j5lte

# This port was possible thanks to the invaluable help of ajislav.

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:j5lte:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}
