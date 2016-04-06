#### How To Dump Your Device To Request A New Port

- get a recent TWRP running on your device.
- copy '[repit-dump.zip] (https://github.com/Lanchon/REPIT/raw/master/device-dump/repit-dump.zip)' to your device and flash it.
- pull to your PC a file called 'repit-dump.log' that was generated in the same folder that holds 'repit-dump.zip'.
- go [here] (https://github.com/Lanchon/REPIT/issues/new) and create a new issue:
  - attach the pulled 'repit-dump.log' file.
  - add the following information:
    - your exact device and device codename.
    - your recovery (version? official? if not where did you get it?).
    - your kernel.
    - your rom.
    - is your device running the stock partition layout or is it already modified?

#### How To Dump Via Sideload

- adb sideload repit-dump.zip
- adb pull /tmp/repit-dump.log

**thank you!**
