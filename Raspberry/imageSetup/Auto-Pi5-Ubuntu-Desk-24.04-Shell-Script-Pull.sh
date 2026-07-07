#! /bin/bash
# ============================================================================
# Shell script to pull the bash shell scripts for Desktop on Raspberry Pi 5 Ubuntu 24.04
# ============================================================================
# Usage:
# sudo wget -O Auto-Pi5-Ubuntu-Desk-24.04-Shell-Script-Pull.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Auto-Pi5-Ubuntu-Desk-24.04-Shell-Script-Pull.sh
# sudo chmod 755 Auto-Pi5-Ubuntu-Desk-24.04-Shell-Script-Pull.sh
# ./Auto-Pi5-Ubuntu-Desk-24.04-Shell-Script-Pull.sh
# ============================================================================
# Shell script to pull the bash shell scripts for Desktop on Raspberry Pi 5 Ubuntu 24.04
# Source: STEAM Clown - www.steamclown.org
# GitHub: https://github.com/jimTheSTEAMClown/
# Hacker: Jim Burnham - STEAM Clown, Engineer, Maker, Propmaster & Adrenologist
# This example code is licensed under the CC BY-NC-SA 4.0, GNU GPL and EUPL
# https://creativecommons.org/licenses/by-nc-sa/4.0/
# https://www.gnu.org/licenses/gpl-3.0.en.html
# https://eupl.eu/
#
# Program/Design Name:   Auto-Pi5-Ubuntu-Desk-24.04-Shell-Script-Pull.sh
# Description:           Shell script to pull the bash shell scripts for Desktop on Raspberry Pi 5 Ubuntu 24.04
#                        Runs with out any questions. Should output a log file: 
#
# Target Hardware:       Raspberry Pi 5 (ARM64 / aarch64)
# Target OS:             Ubuntu 24.04.x LTS (64-bit)
#
# Dependencies:          Run as a normal user with sudo privileges
#                        Must have internet access
#
# Revision:
#  Revision 0.01 - Initial Auto-Pi5-Ubuntu-Desk-24.04-Shell-Script-Pull.sh

# ============================================================================
# LOGGING SETUP
# All output goes to terminal AND to a timestamped log file in home directory.
# Uses 'tee' so you see everything live in the terminal while it is captured.
# Log file:  ~/log-Auto-Pi5-Ubuntu-Desk-24.04-Shell-Script-Pull-YYYYMMDD-HHMMSS.log
# ============================================================================
LOG_FILE="$HOME/log-Auto-Pi5-Ubuntu-Desk-24.04-Shell-Script-Pull-$(date +%Y%m%d-%H%M%S).log"

# Redirect all stdout and stderr through tee to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================================"
echo "  Shell script to pull the bash shell scripts for Desktop on Raspberry Pi 5 Ubuntu 24.04"
echo "============================================================================"
echo "  LOGGING ENABLED"
echo "  Log file: $LOG_FILE"
echo "  All terminal output is being saved to that file."
echo "============================================================"
echo "getting home with cd ~"
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
echo "Copying setup shell scripts"
echo "----------------------------------------------------"
sudo wget -O Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh
sudo chmod 755 Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh
#   sudo wget -O Pi5-Ubuntu-Desk-24.04-Run-First.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Pi5-Ubuntu-Desk-24.04-Run-First.sh 
#   sudo chmod 755 Pi5-Ubuntu-Desk-24.04-Run-First.sh
sudo wget -O Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
sudo chmod 755 Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
#   sudo wget -O Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh 
#   sudo chmod 755 Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
sudo wget -O Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome.sh
sudo chmod 755 Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome.sh
#   sudo wget -O Pi5-Ubuntu-24.04-Fix-Desktop-Portal-Gnome.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Pi5-Ubuntu-24.04-Fix-Desktop-Portal-Gnome.sh
#   sudo chmod 755 Pi5-Ubuntu-24.04-Fix-Desktop-Portal-Gnome.sh

   sudo wget -O Pi5-Ubuntu-24.04-ROS2-Jazzy-Install.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-LVR/refs/heads/main/ROS2/Pi5-Ubuntu-24.04-ROS2-Jazzy-Install.sh 
   sudo chmod 755 Pi5-Ubuntu-24.04-ROS2-Jazzy-Install.sh

    
    ls *.sh

    echo " "
echo "----------------------------------------------------"
echo "Done: Copying Setup Shell scripts"
echo "----------------------------------------------------"
echo "============================================================================"
echo "  Done - Shell script to pull the bash shell scripts for Desktop on Raspberry Pi 5 Ubuntu 24.04"
echo "============================================================================"
