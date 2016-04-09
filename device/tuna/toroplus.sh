#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### toroplus

# This port was possible thanks to the invaluable help of thagringo and musical_chairs.

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:toroplus:*) ;;
        *:tuna:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}
