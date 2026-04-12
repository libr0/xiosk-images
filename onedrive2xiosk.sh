#!/usr/bin/env bash

echo "Updating from Sharepoint: $(date)"
rclone sync ctcsp: /home/cboek/Sharepoint
rm -rf /opt/xiosk/images/*
cp /home/cboek/Sharepoint/Kiosk/*.jpg /home/cboek/Sharepoint/Kiosk/*.png /opt/xiosk/images
/home/cboek/bin/updatexiosk.sh -v
# wait, to ensure the filesystem update is complete
sleep 10
sudo systemctl restart xiosk-runner.service xiosk-switcher.service
