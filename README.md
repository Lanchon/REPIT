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

<br>

-----

<br>

> **AND WHAT IS THIS?**
>
> what follows is text originally posted by me on XDA. the strange incident that was the subject of this post was
investigated by moderators from both of the involves sites and found to be as i described it. as a result, proper
corrective measures were implemented.
>
>unfortunately this post was later surreptitiously deleted by XDA moderator [The_Merovingian]
(http://forum.xda-developers.com/member.php?u=5302753), an action that precipitated my departure from the XDA
community.
>
> the post is now reproduced here for record keeping in the form in which it was when it was deleted from XDA by
The_Merovingian on February 23, 2016.

<br>

_we interrupt your regular programming to bring you this breaking news..._

### _"CHEF-KOCH" IS A THIEF !!!_

> **UPDATE:** moderators from both [the german forum](http://www.android-hilfe.de/) and xda collaborated to resolve this
issue. they were alerted by some forum members who are active in both communities (and again i thank you guys for
that, you know who you are). after a swift investigation, and just two days after this silliness started, they
removed all offending content from the german site and placed a link to this thread in its place. i am very grateful
to all the parties that quickly put this issue to rest.

> **2ND UPDATE:** i was told that this guy's account at the german site was terminated; the reasons for this are unknown
to me. and user [the.gangster](http://forum.xda-developers.com/member.php?u=6560258) was put in charge of the
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

_the plagiarized files are currently published [here](https://mega.nz/#F!cMNShQLa!5lXzEuluHX9jd9Bv3B_h8Q), but might
be removed anytime. a copy of all files was [uploaded to post #3]
(http://forum.xda-developers.com/galaxy-s2/orig-development/tool-lanchon-repit-data-sparing-t3311747/post65239837)_
[now also surreptitiously deleted from XDA! rehosted [here](https://www.androidfilehost.com/?w=files&flid=50817)]
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

_android-hilfe.de: [CHEF-KOCH](http://www.android-hilfe.de/members/chef-koch.97407/)
<br>xda-developers.com: [CHEF-KOCH](http://forum.xda-developers.com/member.php?u=4415879)
<br>github.com: [CHEF-KOCH](https://github.com/CHEF-KOCH)
<br>google.com: [Nvinside@gmail.com](mailto:Nvinside@gmail.com)_

_he has this info on GitHub:
<br>InfoSec Institute/nVidia EU
<br>http://www.infosecinstitute.com/
<br>Lausanne_
