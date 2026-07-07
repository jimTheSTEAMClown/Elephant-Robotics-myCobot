#!/bin/bash
# rover_example_wget.sh
echo "getting rover tools, apps & librbaries
sleep 2

# checking and installing tools
echo ""
echo "apt update..."
sudo apt update
sudo apt upgrade -y
sudo apt update

echo "checking Video Stuff"
ls /dev/video*
v4l2-ctl --list-devices
sudo apt install python3-opencv


echo ""
echo "Done."
ls -l
