# xiosk-images
Transfer images from a Sharepoint folder and let xiosk rotate display of them from the local device.
This was done on a Raspberry Pi 3B.

Requires the installation of:
- xiosk
- rclone

The way I have used this, is to:
- create an /opt/xiosk/images folder that is readable and writeable by the running user
- set up an rclone location that will contain the images to use on the kiosk
- put the two scripts in ~/bin
- create a crontab entry to run the onedrive2xiosk.sh script once per day.

You will need to modify the onedrive2xiosk script for your own use, as it names specific users and rclone locations.  Substitute these with your own details.
