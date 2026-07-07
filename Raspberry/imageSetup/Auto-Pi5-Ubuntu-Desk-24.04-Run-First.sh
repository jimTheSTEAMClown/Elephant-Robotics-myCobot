#! /bin/bash
# ============================================================================
# Shell script to run first before installing apps on a Raspberry Pi 5 Ubuntu 24.04
# ============================================================================
# Usage:
# sudo wget -O Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh
# sudo chmod 755 Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh
# ./Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh
# ============================================================================
# Shell script to run first, to make sure net-tools and other ssh stuff is ready,
# before installing apps on a Raspberry Pi 5 Ubuntu 24.04 image for STEAM robotics
# Source: STEAM Clown - www.steamclown.org
# GitHub: https://github.com/jimTheSTEAMClown/Linux
# Hacker: Jim Burnham - STEAM Clown, Engineer, Maker, Propmaster & Adrenologist
# This example code is licensed under the CC BY-NC-SA 4.0, GNU GPL and EUPL
# https://creativecommons.org/licenses/by-nc-sa/4.0/
# https://www.gnu.org/licenses/gpl-3.0.en.html
# https://eupl.eu/
#
# Program/Design Name:   Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh
# Description:           Shell script to let you do thinkgs like ifconfig, and stuff to be able to run the setup script
#
# Target Hardware:       Raspberry Pi 5 (ARM64 / aarch64)
# Target OS:             Ubuntu 24.04.x LTS (64-bit)
#
# Dependencies:          Run as a normal user with sudo privileges
#                        Must have internet access
#
# Revision:
#  Revision 0.01 - Initial Pi 5 STEAM Clown robotics setup
#  
# Steps:
#  STEP  1 - Update and Upgrade
#  STEP  2 - sudo apt install net-tools -y
#  STEP  3 - sudo apt install openssh-server -y
#  STEP  4 - make sure ssh is running
#  STEP  5 - Auto reset/restart
#
# Usage:
#   chmod +x Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh
#   ./Auto-Pi5-Ubuntu-Desk-24.04-Run-First.sh
#
# References:
#   https://ubuntu.com/tutorials/how-to-install-ubuntu-on-raspberry-pi
#   https://gpiozero.readthedocs.io/en/stable/
#   https://docs.docker.com/engine/install/ubuntu/
#   https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html
#   https://www.arduino.cc/en/software
#   https://docs.platformio.org/en/latest/core/installation/index.html
#   https://tigervnc.org/
# ============================================================================

# ============================================================================
# LOGGING SETUP
# All output goes to terminal AND to a timestamped log file in home directory.
# Uses 'tee' so you see everything live in the terminal while it is captured.
# Log file:  ~/log-Auto-Pi5-Ubuntu-Desk-24.04-Run-First-YYYYMMDD-HHMMSS.log
# ============================================================================
LOG_FILE="$HOME/log-Auto-Pi5-Ubuntu-Desk-24.04-Run-First-$(date +%Y%m%d-%H%M%S).log"

# Redirect all stdout and stderr through tee to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================"
echo "  LOGGING ENABLED"
echo "  Log file: $LOG_FILE"
echo "  All terminal output is being saved to that file."
echo "============================================================"
echo " "

# ============================================================================
# ARCHITECTURE CHECK
# Confirms we are running on ARM64 (aarch64) as required for Pi 5.
# Warns and offers a bail-out if run on an x86 machine by mistake.
# ============================================================================
echo "============================================================================"
echo "ARCHITECTURE CHECK"
echo "  Confirms we are running on ARM64 (aarch64) as required for Pi 5."
echo "  Warns and offers a bail-out if run on an x86 machine by mistake."
echo "============================================================================"
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"
if [ "$ARCH" != "aarch64" ]; then
    echo "----------------------------------------------------"
    echo "WARNING: This script is designed for ARM64 (aarch64)"
    echo "You appear to be running on: $ARCH"
    echo "Some packages (Chromium, Arduino AppImage) may not work."
    echo "----------------------------------------------------"
    echo "Do you wish to continue anyway?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No  ) echo "Exiting."; exit 1;;
        esac
    done
fi

# ============================================================================
# HEADER BANNER
# ============================================================================
echo "Robots & Rovers"
echo "============================================================"
echo "  Raspberry Pi 5 Ubuntu 24.04 - STEAM Clown Run First Script"
echo "  Revision 0.01"
echo "  Target: Pi 5 / ARM64 / Ubuntu 24.04 LTS"
echo "  For: Fire Breathing Robots / Mechatronics Curriculum"
echo "  Log: $LOG_FILE"
echo "============================================================"
echo " "
pwd
ls
echo " "

# ============================================================================
# PRE-FLIGHT BOOTSTRAP
# Install the bare minimum tools needed by this script itself BEFORE any
# prompted steps run. These are not guaranteed on a brand new Ubuntu 24.04
# Desktop image and are required for later steps to succeed.
# ============================================================================
echo " "
echo "============================================================"
echo "PRE-FLIGHT BOOTSTRAP"
echo "============================================================"
# ============================================================================
# STEP 1 - UPDATE AND UPGRADE
# Always run this first on a fresh install to pull the latest package lists
# and apply all security patches before installing anything else.
# ============================================================================
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

# ============================================================================
# STEP 2 - NETWORKING TOOLS & SSh
# Foundational tools used by virtually every other install step SSH, file transfer, 
# network diagnostics, and navigation.
#
#   net-tools      - Provides 'ifconfig' for checking IP addresses
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 2 - CORE SYSTEM AND NETWORKING TOOLS"
echo "  Installing:"
echo "    - openssh-server (with ufw allow ssh)"
echo "    - net-tools (ifconfig)"
echo "============================================================"
  
    echo " "
    echo "----------------------------------------------------"
    echo "Installing openssh-server - enables SSH into this Pi"
    echo "Running: sudo apt install openssh-server -y"
    echo "----------------------------------------------------"
    sudo apt install openssh-server -y
    sudo ufw --force enable
    sudo ufw allow ssh
    echo "  ufw enabled and SSH firewall rule added"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing net-tools - provides ifconfig command"
    echo "Running: sudo apt install net-tools -y"
    echo "----------------------------------------------------"
    sudo apt install net-tools -y

    echo " "
    echo "----------------------------------------------------"
    echo "Done: SSH AND NETWORKING TOOLS"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 3 - VERIFY ALL INSTALLS
# Quick version check on all installed tools.
# Flags anything that is NOT FOUND so you know what to investigate.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 3 - VERIFY ALL INSTALLS"
echo "============================================================"
echo " "

check_tool() {
    local tool=$1
    local version_flag=${2:---version}
    printf "  %-22s " "$tool:"
    if command -v "$tool" &>/dev/null; then
        echo "$($tool $version_flag 2>&1 | head -1)"
    else
        echo "NOT FOUND"
    fi
}

echo "--- Core Tools ---"
check_tool ssh -V
check_tool wget
check_tool ifconfig



echo " "
echo "--- Groups for $USER ---"
groups "$USER"

# ============================================================================
# DONE BANNER
# ============================================================================
echo " "
echo "  ____    __  _  _  ____  "
echo " (  _ \  /  \( \( )( ___) "
echo "  )(_) )( () ))  (  )__)  "
echo " (____/  \__/(_)\_)(____)  "
echo " "
echo "============================================================"
echo "  Done: Pi 5 Ubuntu 24.04 STEAM Clown Run First - Rev 0.02"
echo " "
echo "  Log file saved to:"
echo "  $LOG_FILE"
echo " "

# ============================================================================
# STEP 5 - Auto reboot/restart
# ============================================================================
echo "============================================================"
echo "  About to restart"
echo "============================================================"
    echo "Rebooting in 15 seconds to reset xdg-desktop-portal..."
    echo "Press Ctrl+C to cancel"
    sleep 15
    sudo reboot

