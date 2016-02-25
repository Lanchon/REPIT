## Lanchon REPIT
### A Data-Sparing Repartitioning Tool for the Galaxy S2 i9100

Powered by [Flashize]
(http://forum.xda-developers.com/android/software-hacking/tool-flashize-shell-scripts-flashable-t3313605).

> **IMPORTANT NOTE:** this script will not work if your phone is encrypted. you need to decrypt your phone first.
this was found and reported by XDA user **jer194** [here]
(http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747/post65307128).
if you run the script on an encrypted phone anyway, no damage will come: it will just refuse to start,
complaining that it cannot reread the partition table.

#### IF... your stock-partitioned device cannot flash gapps after updating to CM 13.0

download and flash the file as it is. it will get most space from the unused /preload partition and only 8MB for
the internal sdcard, and then make /system 1GB in size. it will keep you current /data size constant, whatever it is.
it will retain all data except data in /preload, which is unused in custom roms (but some multi-boot setups use it).

#### IF... your device is usable

you can nonetheless use this script to do general repartitioning, file system fixing, wiping, and/or file system
type changes. download the script, rename it to express your desired configuration (see below), and then flash it.

#### HOW TO

1. get [my latest IsoRec TWRP]
(http://forum.xda-developers.com/galaxy-s2/orig-development/isorec-isolated-recovery-galaxy-s2-t3291176)
(by arnab) running.
2. make sure your battery is mostly charged.
3. get the zip from the link below.
4. if needed, **rename it to express your desired configuration** (see below).
5. **PLUG INTO A POWER SOURCE.** this operation might take a long time and **must not be interrupted.**
6. flash the script. in case it fails to start:
   - if the script cannot unmount all partitions, it will copy itself to the /tmp directory and ask you to flash it
     a second time from there.
   - if it still fails to unmount all partitions, or if it fails to lock the eMMC with error 'unable to reread the
     partition table', then you need to reboot TWRP and reflash immediately after boot up. (you may actually need to
     flash twice, the second time from '/tmp'.) do not do anything after boot up and before flashing! in particular,
     **do not mount the sdcard as USB mass storage.**
   - if locking issues remain, your phone is probably encrypted; this script is not compatible with encrypted phones.

finally, go get a coffee or two. **do not, under any circumstance, interrupt this script !!!**

#### HOW TO CONFIGURE

configure the script by renaming the zip file before flashing it.

valid zip names: `<prefix>[-system=<conf>][-data=<conf>][-sdcard=<conf>][-preload=<conf>]<suffix>`

valid partition `<conf>` values: `[<size-in-GiB>|same|min|max][+[keep|wipe][+[ext4|vfat]]]`

##### Sizes
- `same`: do not alter the size of this partition
- `min`: make this partition 8 MiB in size (useful for 'preload', which is unused in custom roms)
- `max`: make this partition as big as possible (at most one partition can have its size set to 'max')
- `<size-in-GiB>`: fractional number expressing the new partition size in GiB (gets rounded to the nearest MiB)

##### Defaults
- `-system=same+keep+ext4`
- `-data=same+keep+ext4`
- `-sdcard=same+keep+vfat` <-- note `vfat` here
- `-preload=same+keep+ext4`

##### Samples
- repartition to stock, wiping preload (in case you used a very small preload before):
  <br>(**note:** in general it is not recommended to resize file systems by large factors.)
  <br>`lanchon-repit-XXXXXXXX-system=0.5-data=2-sdcard=max-preload=0.5+wipe-i9100.zip`
- repartition to stock (without wiping preload):
  <br>`-system=0.5-data=2-sdcard=max-preload=0.5`
- wipe data:
  <br>`-data=+wipe`
- wipe/change internal sdcard to ext4 (not recommended):
  <br>`-sdcard=+wipe+ext4`
- **repartition to 1GB system, 6GB data, no preload...**
  - ...keeping all other data:
    <br>`-system=1-data=6-sdcard=max-preload=min+wipe`
  - ...keeping all other data, **for phones with ext4-formatted internal sdcard:**
    <br>`-system=1-data=6-sdcard=max++ext4-preload=min+wipe`
  - ...keeping system and sdcard but **WIPING DATA:**
    <br>(**note:** wiping data is much faster than moving it around if system is being resized and data is large.)
    <br>`-system=1-data=6+wipe-sdcard=max-preload=min+wipe`

#### IN CASE OF ISSUES

if there are any problems, **read the log!** you can scroll it. most likely it will tell you want is wrong and what
to do about it. otherwise, make sure to somehow record the log. take a picture of it at least; you can see a
full screen log by hitting the back button once, then the center button at the bottom of the screen that looks
like a TV screen. afterwards, you can try reflashing the script if you understand what happened and flashing it
again makes sense.

> **PLEASE NOTE:** i am not interested in your _'did not work'_ report unless you post info from your log.
if you cannot post any info from the log, then please just do not post at all. thank you.

#### DOWNLOADS

https://www.androidfilehost.com/?w=files&flid=49911

#### CHANGELOG

https://github.com/Lanchon/REPIT/releases

#### DISCLAIMER

i believe this software to be very safe and i exercised it a lot before posting it. but i accept no responsibility
if your data is lost or your device is bricked.
