#!/bin/bash

exit 0
# Execute command one by one

# WARNING: This is dangerious script and could wipe out your entire Hard Disc.
# Please, check that device file of SDCARD is for sure one specified below.

# How to figure that out. Run this command:
ls /dev/sd*
# What write out is hard disk.

# Put SD card with ROS2 to the SD card reader.

# Again run this:
ls /dev/sd*
# New thing that is listed is SD card.

IMG=RPi2_Ubuntu_22_ROS2.img

#SDCARD_DEV=sda # If have SSD in PC.
SDCARD_DEV=sdb # If have only 1 HDD in PC.
#SDCARD_DEV=sdc # If have 2 HDD.


# Read image from SD card.
umount /dev/$SDCARD_DEV*; time sudo dd if=/dev/$SDCARD_DEV of=$IMG bs=1M conv=noerror,sync status=progress

# Put empty/Rasbian SD card to the SD card reader

# Flash image to SD card. 15 min
umount /dev/$SDCARD_DEV*; time sudo dd if=$IMG of=/dev/$SDCARD_DEV bs=1M conv=noerror,sync status=progress

