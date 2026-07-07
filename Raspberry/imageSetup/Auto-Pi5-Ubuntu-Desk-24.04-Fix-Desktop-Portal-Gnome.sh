#! /bin/bash
# ============================================================================
# Shell script to fix Desktop-Portal-Gnome on Raspberry Pi 5 Ubuntu 24.04
# ============================================================================
# Usage:
# sudo wget -O Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome.sh
# sudo chmod 755 Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome.sh
# ./Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome.sh
# ============================================================================
# Shell script to fix Desktop-Portal-Gnome on Raspberry Pi 5 Ubuntu 24.04
# ============================================================================

# ============================================================================
# LOGGING SETUP
# All output goes to terminal AND to a timestamped log file in home directory.
# Uses 'tee' so you see everything live in the terminal while it is captured.
# Log file:  ~/log-Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome-YYYYMMDD-HHMMSS.log
# ============================================================================
LOG_FILE="$HOME/log-Auto-Pi5-Ubuntu-Desk-24.04-Fix-Desktop-Portal-Gnome-$(date +%Y%m%d-%H%M%S).log"

# Redirect all stdout and stderr through tee to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================================"
echo "  Shell script to fix Desktop-Portal-Gnome on Raspberry Pi 5 Ubuntu 24.04"
echo "============================================================================"
echo "  LOGGING ENABLED"
echo "  Log file: $LOG_FILE"
echo "  All terminal output is being saved to that file."
echo "============================================================"
cd 
pwd

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
echo "Running purge of xdg-desktop-portal-gnome"
echo "----------------------------------------------------"
    sudo apt purge xdg-desktop-portal-gnome
echo "----------------------------------------------------"
echo "Installing xdg-desktop-portal-gtk"
echo "----------------------------------------------------"    
    sudo apt install xdg-desktop-portal-gtk
echo "----------------------------------------------------"
echo "Restarting daemon-reexec and restart xdg-desktop-portal"
echo "----------------------------------------------------"        
    systemctl --user daemon-reexec
    systemctl --user restart xdg-desktop-portal

    ls *.sh

    echo " "
    echo "----------------------------------------------------"
    echo "Done: Copying Setup Shell scripts"
    echo "----------------------------------------------------"

echo "============================================================"
echo "  About to restart"
echo "============================================================"

    echo "Rebooting in 15 seconds to reset xdg-desktop-portal..."
    echo "Press Ctrl+C to cancel"
    sleep 15
    sudo reboot
