## Lanchon REPIT
### A Device-Only Data-Sparing Repartitioning Tool For Android

#### [CHANGELOG] - [DEVICES] - [DOWNLOADS] - [GALAXY S2] - [XDA THREAD]

[CHANGELOG]: https://github.com/Lanchon/REPIT/releases
[DEVICES]:   #device-specific-information
[DOWNLOADS]: https://www.androidfilehost.com/?w=files&flid=49911
[GALAXY S2]: #the-galaxy-s2-family
[XDA THREAD]: http://forum.xda-developers.com/android/software-hacking/tool-lanchon-repit-data-sparing-t3358036

Powered by [Flashize] (https://github.com/Lanchon/Flashize).

<br>

## General Information (All Devices)

#### WHAT IS THE PROBLEM ?

many older devices, especially the ones originally released before emulated storage was available, were partitioned by the OEM in ways that hinder the installation and use of newer Android versions. for example, the Galaxy S2 GT-I9100 comes with a 0.5 GiB /system partition that is unable to fit CM 13.0 and Open GApps, even if you choose the pico version. though its flash is typically a generous 16 GiB, the stock /data partition is only 2 GiB which means that with today's ART you run out of space to install applications in no time. it also comes with a 0.5 GiB /preload partition that goes unused on custom ROMs.

people have typically solved this by repartitioning. on Samsung devices this is a tricky process that involves the use of download mode, a Windows PC, Windows device drivers that support the device's download mode, a 'pirated' proprietary PC software called Odin, the right PIT and other files, and correct configuration. (a free software alternative to Odin called Heimdall works on many devices and is cross platform and supports Linux PCs, but the rest of the hurdles remain.) the procedure has potential for hard-bricking if the wrong files are flashed. after repartitioning, all affected partitions must be reflashed or formatted anew, a procedure that many get wrong. and of course, all data in the affected partitions gets wiped (typically the complete device) making this an ultra-inconvenient affair.

#### WHAT IS REPIT ?

REPIT is a simple, safe, device-only, data-sparing, and easily portable repartitioning tool for Android devices:

- device-only: just flash a zip file in recovery to repartition the device.
- simple: rename the zip file before flashing to configure your choice of partition sizes, file systems, wipes, etc.
- safe:
  - a correctly ported REPIT can never hard-brick your device.
  - before starting, REPIT checks for the existence of all the tools that will be needed for the task at hand, verifies that the current partition layout passes several sanity checks, checks and fixes all the involved file systems, and verifies that the new partition layout will meet its sanity checks too. REPIT performs a dry-run of the complete repartitioning process to detect possible problems early on.
  - if REPIT fails, it will nonetheless try to restore your device to a working in-between state. you can solve the blocking issue and REPIT again towards your goal, or otherwise REPIT back to your original configuration. (keeping the in-between state is not recommended as it usually involves 'wasted' unpartitioned space.)
  - my estimate is that between 500 to 1000 users already used REPIT for 'major' changes on the i9100 and no incidents of data loss were reported.
- easily portable: a simple configuration file is all that is needed to port REPIT to a new device.

you can look at [the log of a demo run] (https://raw.githubusercontent.com/Lanchon/REPIT/master/LOG.txt) to get a feel for what REPIT can do. in this run on a Galaxy S2 it grows the /system and /data ext4 partitions to 1 and 6 GiB respectively, it wipes and shrinks the unused /preload partition to a minimum size, and it adjusts the size of the internal /sdcard vfat partition to occupy whatever space is left. REPIT plans, orders and undertakes a safe series of partition resize and move operations to reach its goal, all the while keeping and eye on details such as alignments and retaining the data present in the /system, /data and /sdcard partitions.

#### LIMITATIONS

- REPIT **requires TWRP 2 or TWRP 3.** some recoveries unnecessarily hold device or partition locks during flashing, which prevents all repartitioning tools from working (parted, fdisk, gdisk, and of course REPIT). unfortunately the recoveries bundled with CM 11, 12.0, 12.1 and 13.0 display this issue and are incompatible. recent TWRP 2.8.7.* and 3.0.0.* recoveries comply with this requirement, but only when flashing zips from /tmp. (REPIT will automatically copy itself to /tmp if it detects locks, to help you relaunch from there.)
- REPIT **does not support encrypted phones.**
- REPIT **will cause data loss** if the repartitioning process is externally interrupted. **plug into a power source!**

#### HOW TO REPIT

1. if you think your data is invaluable then treat it as such: **make a backup!**
2. get TWRP running on your device.
3. make sure your battery is mostly charged.
4. get the zip for your device from the link below.
5. **rename it to express your desired configuration** (see below).
6. **PLUG INTO A POWER SOURCE.** this operation might take a long time and **must not be interrupted.**
7. flash the zip locally on the phone. (if you want to sideload instead, please see the note below.)

finally, go get a coffee or two. **do not, under any circumstance, interrupt this script !!!**

in case the script fails to start:
- if the script cannot unmount all partitions, it will copy itself to the /tmp directory and ask you to flash it a second time from there.
- if it still fails to unmount all partitions, or if it fails to lock the eMMC ('unable to reread the partition table'), then unplug the device from USB hosts such as PCs, reboot TWRP, and reflash the script immediately after boot up. (you may actually need to reflash twice, the second time from '/tmp'.) do not do anything after booting up and before flashing! in particular, **do not connect the device to a PC or USB host** as this might auto-mount the sdcard via MTP, **and do not mount the sdcard as USB mass storage** via TWRP's UI. in some rare cases you might need to use TWRP's UI to disable MTP before rebooting and to manually unmount all partitions before flashing the script from '/tmp'.
- if locking issues remain, your phone is probably encrypted; this script is not compatible with encrypted phones.

if you want to sideload:
- sideloading conceals the filename from the device, and thus filename-based configuration will not work.
- to sideload you need to add a file called 'flashize/repit-settings' to the zip containing the full intended filename, or otherwise just the configuration part of it. for example, a file containing `-system=1G` is enough (the `-` is required). note that your recovery might require you to resign the zip after that change.
- otherwise you can add the file directly to the device before sideloading, for example via adb push. in that case it must be named '/tmp/repit-settings'.

#### HOW TO CONFIGURE

configure the script by renaming the zip file before flashing it.

valid zip names: `<prefix>[-partition1=<conf>][-partition2=<conf>]...<suffix>`

valid partition `<conf>` values: `[<size>(G|M)|same|min|max][+[keep|wipe][+[ext4|vfat|f2fs|swap|raw]]]`

the defaults are device-dependent. please look inside your device's configuration file for more information. for configuration samples please see (the i9100 section) [#galaxy-s2-samples] below.

##### Partition Data
- `keep`: retain the data in the partition. if the partition needs to be moved or resized, this option usually makes the operation significantly slower, even if the partition is mostly empty.
- `wipe`: wipe the partition. always wipe partitions that are empty or carry data that you do not care about: it will make REPIT faster and will result in less wear on the flash memory.

##### Partition Sizes
- `same`: do not alter the size of this partition.
- `min`: make this unused partition a minimum yet formattable size (typically 8 MiB, but device-dependent).
- `max`: make this partition as big as possible (at most one partition per 'heap' can have its size set to 'max').
- `<size>(G|M)`: fractional number followed by a size unit expressing the desired partition size. the unit is either `G` for GiB or `M` for MiB. this value gets rounded to the nearest acceptable discreet value. the size granularity is device-dependent, but typically set to match the device-dependent partition alignment (which typically is 1 or 4 MiB).

##### Partition Types
- `ext4` and `vfat`: these partitions have full move, resize and wipe support.
- `f2fs`: f2fs partitions can be moved and wiped, and can only be resized while wiping them.
<br>(tools to resize f2fs file systems do not exist for now.)
- `swap`: swap partitions can be wiped, and can only be moved or resized while wiping them.
<br>(it makes no sense to retain their content.)
- `raw`: raw partitions are treated as opaque blobs and can only be moved.
<br>(neither resizing nor wiping is supported.)

##### Supported Features

|          | wipe | keep + move       | keep + resize   | keep + move + resize | crypto footer |
|:--------:|:----:|:-----------------:|:---------------:|:--------------------:|:-------------:|
| **ext4** | YES  | YES (brute force) | YES (efficient) | YES (brute force)    | YES           |
| **vfat** | YES  | YES (efficient)   | YES (efficient) | YES (efficient)      | no            |
| **f2fs** | YES  | YES (brute force) | no              | no                   | YES           |
| **swap** | YES  | no                | no              | no                   | no            |
| **raw**  | no   | YES               | no              | no                   | no            |

- **brute force:** the complete partition extent is operated upon.
- **efficient:** only the stored data within the partition is operated upon.
- **crypto footer:** support for encryption metadata at the end of the partition.

#### IN CASE OF ISSUES

if there are any problems, **read the log!** you can scroll it on TWRP. most likely it will tell you what is wrong and what to do about it. if not, make sure to somehow record the log. **REPIT logs to file '/tmp/lanchon-repit.log'.** otherwise, you can [obtain a copy of TWRP's log] (http://rootzwiki.com/topic/24120-how-to-get-a-log-from-twrp/) (which includes REPIT's log), or if not at least take a picture of it with your camera. in TWRP 2.8.7.* you can see a full screen log by hitting the back button once, then the center button at the bottom of the screen that looks like a TV screen. after recording the log, you can try reflashing the script if you understand what happened and flashing it again makes sense.

**PLEASE NOTE:** your _'did not work'_ report is useless unless you post info from your log.

<br>

## Device-Specific Information

each supported device has a unique targeted build of REPIT in the [download] (https://www.androidfilehost.com/?w=files&flid=49911) section. you can also find device-specific information in the [device tree] (https://github.com/Lanchon/REPIT/tree/master/device); try searching by device codename using Github's [find file] (https://github.com/Lanchon/REPIT/find/master/device). all configuration options for a specific device are defined in the corresponding `<device-codename>.sh` file and the `common.sh` files that might exist in the same directory and in directories above it. you might also find device-specific readme files with relevant information.

#### IF YOUR DEVICE IS NOT SUPPORTED

so your device is unsupported, tough luck... but porting REPIT to a new device is an easy job; you can either do it yourself or request that i do it for you. to request a new port, please [follow this steps] (https://github.com/Lanchon/REPIT/blob/master/device-dump/README.md); port requests are welcome. if you want to get your hands dirty, check the configuration files for i9100 ([1] (https://github.com/Lanchon/REPIT/blob/master/device/galaxy-s2/exynos-4210/i9100.sh), [2] (https://github.com/Lanchon/REPIT/blob/master/device/galaxy-s2/common.sh)), they are the most complete and commented. but usually you can get away with much less, take a look at [i9300] (https://github.com/Lanchon/REPIT/blob/master/device/i9300.sh). for an example of how to handle out-of-order partitions, check out [janice] (https://github.com/Lanchon/REPIT/blob/master/device/janice.sh).

<br>

## The Galaxy S2 Family

REPIT started its life as i9100-only tool and it inherits this doc section from the good old days.

> **IMPORTANT NOTE:** this script will not work if your phone is encrypted. you need to decrypt your phone first. this was found and reported by XDA user **jer194** [here] (http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747/post65307128). if you run the script on an encrypted phone anyway, no damage will come: it will just refuse to start, complaining that it cannot reread the partition table.

#### IF... your stock-partitioned device cannot flash gapps after updating to CM 13.0

download and flash the file as it is. it will get most space from the unused /preload partition and only 8 MiB for the internal sdcard, and then make /system 1 GiB in size. it will keep you current /data size constant, whatever it is. it will retain all data except data in /preload, which is unused in custom roms (but some multi-boot setups use it).

#### IF... your device is usable

you can nonetheless use this script to do general repartitioning, file system fixing, wiping, and/or file system type changes. download the script, rename it to express your desired configuration (see below), and then flash it.

#### Galaxy S2 HOW TO

first get [official TWRP] (https://twrp.me/devices/samsunggalaxys2i9100.html) running on your device, then follow the generic how-to.

valid zip names: `<prefix>[-system=<conf>][-data=<conf>][-sdcard=<conf>][-preload=<conf>]<suffix>`

for this device, partition alignment is 4 MiB and partition sizes get rounded to the nearest 4 MiB boundary. (it is typical for all devices to use the same value for partition alignment and granularity.)

##### Galaxy S2 Defaults
- `-system=same+keep+ext4`
- `-data=same+keep+ext4`
- `-sdcard=same+keep+vfat` <-- note `vfat` here
- `-preload=same+keep+ext4`

##### Galaxy S2 Samples
- repartition to stock, wiping preload (in case you used a very small preload before):
  <br>(**note:** in general it is not recommended to resize file systems by large factors.)
  <br>`lanchon-repit-XXXXXXXX-system=0.5G-data=2G-sdcard=max-preload=0.5G+wipe-i9100.zip`
- repartition to stock (without wiping preload):
  <br>`-system=0.5G-data=2G-sdcard=max-preload=0.5G`
- wipe data:
  <br>`-data=+wipe`
- wipe/change internal sdcard to ext4 (not recommended):
  <br>`-sdcard=+wipe+ext4`
- **repartition to 1 GiB system, 6 GiB data, no preload...**
  - ...keeping all other data:
    <br>`-system=1G-data=6G-sdcard=max-preload=min+wipe`
  - ...keeping all other data, **for phones with ext4-formatted internal sdcard:**
    <br>`-system=1G-data=6G-sdcard=max++ext4-preload=min+wipe`
  - ...keeping system and sdcard but **WIPING DATA:**
    <br>(**note:** wiping data is much faster than moving it around if system is being resized and data is large.)
    <br>`-system=1G-data=6G+wipe-sdcard=max-preload=min+wipe`

<br>

## Disclaimer

i believe this software to be very safe and i exercised it a lot before posting it. but i accept no responsibility if your data is lost or your device is bricked.

<br>

-----

<br>

> **AND WHAT IS THIS?**
>
> what follows is text originally posted by me on XDA. the strange incident that was the subject of this post was
investigated by moderators from both of the involved sites and found to be as i described it. as a result, proper
corrective measures were implemented.
>
>unfortunately this post was later surreptitiously deleted by XDA moderator [The_Merovingian]
(http://forum.xda-developers.com/member.php?u=5302753), an action that precipitated my departure from the XDA
community as a developer. i no longer consider XDA a viable medium for hosting my work.
>
> the post is now reproduced here for record keeping in the form in which it was when it was deleted from XDA by
The_Merovingian on February 23, 2016.

> **UPDATE:** as a sort of retaliation for my moving REPIT out of XDA, The_Merovingian closed down
[the REPIT thread] (http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747)
([via Wayback Machine] (https://web.archive.org/web/20160226151111/http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747)).
this was unfortunate because the thread got 30 pages of posts in its 2 weeks of existence, and probably was
the second most active thread in the S2 forum. all this traffic then went on to spam the official i9100 CM13 thread,
already drowning in off-topic noise; it was a mess.
>
> clearly XDA members needed a place to discuss REPIT but XDA did not really care about this. 
The_Merovingian told me that i needed to "remove [the rant]
(http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747/post65239832)"
in order for the thread to be reopened. i reached out to the XDA moderation committee asking for the
official position on whether "DUE TO IRRECONCILABLE DIFFERENCES" constituted an unacceptable rant on XDA.
i am still waiting for a response... :)
>
> censorship attempts typically backfire on the internet. what was to be a post on a forum is now inextricably
linked to the history of an open source project in its git repo, cloned by anyone needing the tool's tree.
>
> After all is said and done, all the trouble caused and the time lost, i have but one personal message
to The_Merovingian, and it is this: the matrix is a silly franchise.

<br>

_we interrupt your regular programming to bring you this breaking news..._

### _"CHEF-KOCH" IS A THIEF !!!_

> **UPDATE:** moderators from both [the german forum] (http://www.android-hilfe.de/) and xda collaborated to resolve this
issue. they were alerted by some forum members who are active in both communities (and again i thank you guys for
that, you know who you are). after a swift investigation, and just two days after this silliness started, they
removed all offending content from the german site and placed a link to this thread in its place. i am very grateful
to all the parties that quickly put this issue to rest.

> **2ND UPDATE:** i was told that this guy's account at the german site was terminated; the reasons for this are unknown
to me. and user [the.gangster] (http://forum.xda-developers.com/member.php?u=6560258) was put in charge of the
repartition thread there. thank you for taking over!

> **3RD UPDATE:** i privately told the.gangster a few days ago when this guy was banned from the german site that i
wanted to remove the guy's contact details from this post and let bygones be bygones. unfortunately this guy is
relentless: he can no longer post, but still he added text files on his MEGA instead accusing **me** of stealing
and other nonsense. well, so be it: this info stays online forever, and so do his contact details. i removed the
fowl language to comply with XDA requirements and the rest stays.

_it is unbelievable!!! this_ [epithet removed] _took my just-published software, removed the license, removed my
name, removed the copyright, added himself as the author, and republished it in a [german forum]
(http://www.android-hilfe.de/thema/how-to-vergroesserung-der-datenpartition-mittels-bearbeitetem-pit-file-teil-2.751812/)
as his own work. (here is the same link [via Wayback Machine]
(https://web.archive.org/web/20160213014929/http://www.android-hilfe.de/thema/how-to-vergroesserung-der-datenpartition-mittels-bearbeitetem-pit-file-teil-2.751812/),
in case the_ [epithet removed] _decides to delete his post.) when i dated one of my zips in its name, he copied
that too, except that he rewinded the date by one day. but he forgot to fake the modification time of the files
inside the zip; and of course the upload date in MEGA is the real one. he also republished the older v0.1 unfinished release i did to help people in a tight spot with CM13, even though that release **was not free software**. (it was
specifically **not** licensed as free software to avoid copies of the unfinished work spreading around; however the
current version is GPLv3.) he also stole [Flashize]
(http://forum.xda-developers.com/android/software-hacking/tool-flashize-shell-scripts-flashable-t3313605),
another tool i published these days._

_the plagiarized files are currently published [here] (https://mega.nz/#F!cMNShQLa!5lXzEuluHX9jd9Bv3B_h8Q), but might
be removed anytime. a copy of all files was [uploaded to post #3]
(http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747/post65239837)_
[now also surreptitiously deleted from XDA! rehosted [here] (https://www.androidfilehost.com/?w=files&flid=50817)]
_for record keeping._

_i did delete my old published v0.1 files from xda, but fortunately i did not delete some customized versions of
v0.1 that i produced on request that are still available [here]
(http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747/post65252583)
and [here] (http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747/post65252738).
most importantly, i [announced]
(http://forum.xda-developers.com/galaxy-s2/development-derivatives/rom-cyanogenmod-13-t3223808/post65201096)
that i was working on a partitioning tool and 6 hours later [published]
(http://forum.xda-developers.com/galaxy-s2/development-derivatives/rom-cyanogenmod-13-t3223808/post65206132)
the full complex log of a working, pre-release version of the application. that was 3 full days before the_
[epithet removed] _published "his" software... lol._

#### _WHO IS THIS "CHEF-KOCH"_ [epithet removed] _THIEF ANYWAY ???_

[rant removed.]

_it is very unlikely that this is the only time he has done this, and i can tell you this is very demotivating for a developer. so protect your developers by helping them expose this clown in case they happen to cross paths with him. also, his clients and/or employers better know what kind of "work" this guy does._

_android-hilfe.de: [CHEF-KOCH] (http://www.android-hilfe.de/members/chef-koch.97407/)
<br>xda-developers.com: [CHEF-KOCH] (http://forum.xda-developers.com/member.php?u=4415879)
<br>github.com: [CHEF-KOCH] (https://github.com/CHEF-KOCH)
<br>google.com: [Nvinside@gmail.com] (mailto:Nvinside@gmail.com)_

_he has this info on GitHub:
<br>InfoSec Institute/nVidia EU
<br>http://www.infosecinstitute.com/
<br>Lausanne_
