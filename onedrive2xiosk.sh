#!/usr/bin/env bash
#
#  Download files from a sharepoint folder, and display on the pi with Xiosk
#
#  It assumes xiosk is installed in /opt/xiosk as the current user
#  (in particular that the current user has write access to that folder)
#  and that the desired sharepoint folder has been set up using rclone
#  to the share ctcsp:
#
#  It currently converts files designed for 2560x1080 resolution to
#  a squashed 1920x1080 resolution, which will be stretched when displayed
#
curruser=`whoami`
sharelocation=ctcsp:

if [ ! -d /opt/xiosk/images ]
then
	mkdir -p /opt/xiosk/images
fi

echo "Updating from Sharepoint: $(date)"
rclone sync $sharelocation /home/$curruser/Sharepoint

echo "Removing old images"
rm -rf /opt/xiosk/images/*

echo "Copying new images"
cp /home/$curruser/Sharepoint/Kiosk/*.jpg /home/$curruser/Sharepoint/Kiosk/*.png /opt/xiosk/images

echo "Converting to correct screen format"
for file in /opt/xiosk/images/*; do echo "$file"; convert "$file" -resize 1920x1080\! "$file"; done

echo "Updating kiosk configuration"
/home/cboek/bin/updatexiosk.sh -v

echo "Restarting services"
sudo systemctl restart xiosk-runner.service xiosk-switcher.service
