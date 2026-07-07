#! /bin/bash
# ============================================================================
# Shell script to pull the bash shell scripts for Desktop on Raspberry Pi 5 Ubuntu 24.04
# ============================================================================
cd 
pwd

echo "============================================================"
echo "want to run update & upgrade?"
echo "============================================================"
echo "Do you wish to update and upgrade? Enter y/Y or n/N"
read -p "Set locale?: " yesInstall

if [ "$yesInstall" == "y" ] || [ "$yesInstall" == "Y" ]; then
    echo "----------------------------------------------------"
    echo "getting home with cd ~"
    echo "----------------------------------------------------"
    echo " "
    cd ~
    pwd
    echo "----------------------------------------------------"
    echo "Running: sudo apt-get update, upgrade, autoremove, autoclean, and finally another update"
    echo "----------------------------------------------------"
    sudo apt-get update         # sync package lists from repos
    sudo apt-get upgrade -y     # apply all available upgrades
    sudo apt-get autoremove -y  # drop orphaned dependencies left by upgrades
    sudo apt-get autoclean      # purge stale .deb cache files
    sudo apt-get update         # re-sync so next install has clean fresh index
    echo "----------------------------------------------------"
    echo "Done running update, upgrade, autoremove, autoclean, and finally another update"
    echo "----------------------------------------------------"
else
    echo "Skipping locale setup"
fi

echo "============================================================"
echo "Ready to copy setup shell scripts?"
echo "============================================================"
echo "Do you wish to copy setup shell scripts? Enter y/Y or n/N"
read -p "Set locale?: " yesInstall

if [ "$yesInstall" == "y" ] || [ "$yesInstall" == "Y" ]; then

    sudo wget -O Pi5-Ubuntu-Desk-24.04-Run-First.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Pi5-Ubuntu-Desk-24.04-Run-First.sh 
    sudo chmod 755 Pi5-Ubuntu-Desk-24.04-Run-First.sh
    sudo wget -O Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh 
    sudo chmod 755 Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
    sudo wget -O Pi5-Ubuntu-24.04-ROS2-Jazzy-Install.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-LVR/refs/heads/main/ROS2/Pi5-Ubuntu-24.04-ROS2-Jazzy-Install.sh 
    sudo chmod 755 Pi5-Ubuntu-24.04-ROS2-Jazzy-Install.sh
    sudo wget -O Pi5-Ubuntu-24.04-Fix-Desktop-Portal-Gnome.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Pi5-Ubuntu-24.04-Fix-Desktop-Portal-Gnome.sh
    sudo chmod 755 Pi5-Ubuntu-24.04-Fix-Desktop-Portal-Gnome.sh
    
    ls *.sh

    echo " "
    echo "----------------------------------------------------"
    echo "Done: Copying Setup Shell scripts"
    echo "----------------------------------------------------"
else
    echo "Skipping locale setup"
fi

