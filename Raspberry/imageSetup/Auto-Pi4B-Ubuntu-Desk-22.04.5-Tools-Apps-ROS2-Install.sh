#! /bin/bash
# ============================================================================
# Shell script to set up tools, apps, pymycobot, and ROS 2 Humble on a
# Raspberry Pi 4B running Ubuntu 22.04.5 LTS Desktop for STEAM robotics.
# ============================================================================
# Usage:
#   wget -O Auto-Pi4-Ubuntu-Desk-22.04-Tools-Apps-Install.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Auto-Pi4-Ubuntu-Desk-22.04-Tools-Apps-Install.sh
#   chmod 755 Auto-Pi4-Ubuntu-Desk-22.04-Tools-Apps-Install.sh
#   ./Auto-Pi4-Ubuntu-Desk-22.04-Tools-Apps-Install.sh
# ============================================================================
# Source: STEAM Clown - www.steamclown.org
# GitHub: https://github.com/jimTheSTEAMClown/Robots-Rovers-Project-Template
# Hacker: Jim Burnham - STEAM Clown, Engineer, Maker, Propmaster & Adrenologist
# This example code is licensed under the CC BY-NC-SA 4.0, GNU GPL and EUPL
# https://creativecommons.org/licenses/by-nc-sa/4.0/
# https://www.gnu.org/licenses/gpl-3.0.en.html
# https://eupl.eu/
#
# Program/Design Name:   Auto-Pi4-Ubuntu-Desk-22.04-Tools-Apps-Install.sh
# Description:           Full setup script for Ubuntu 22.04.5 Desktop on Pi 4B.
#                        Configures the system for both pure-Python (no-ROS)
#                        myCobot 280 Pi projects AND ROS 2 Humble projects.
#                        Installs dev tools, Python libraries, hardware/GPIO/
#                        serial tools, VS Code, Thonny, Docker, VNC, Arduino,
#                        pymycobot (robot API), and ROS 2 Humble + MoveIt 2.
#
# Target Hardware:       Raspberry Pi 4B (ARM64 / aarch64)
# Target OS:             Ubuntu 22.04.5 LTS Desktop (64-bit, Jammy Jellyfish)
#
# Dependencies:          Run Auto-Pi4-Ubuntu-Desk-22.04-Run-First.sh first.
#                        Run as a normal user with sudo privileges.
#                        Must have internet access.
#
# Revision:
#  Revision 0.01 - Adapted from Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
#                  Key differences from Pi 5 / Ubuntu 24.04 version:
#                    * Target: Pi 4B (not Pi 5); Ubuntu 22.04 (not 24.04)
#                    * pigpio IS available in Ubuntu 22.04 apt repos (unlike 24.04)
#                    * python3-gpiozero uses pigpio OR lgpio backend on 22.04
#                    * PEP 668 externally-managed-env NOT enforced on Ubuntu 22.04
#                      pip installs work system-wide without --break-system-packages
#                    * UART configuration required for myCobot 280 Pi serial link
#                      (/dev/ttyAMA0 at 1,000,000 baud via dtoverlay=disable-bt)
#                    * Python robot-env venv created for pymycobot isolation
#                    * ROS 2 Humble installed (Humble is paired with 22.04 LTS)
#                      ROS 2 Jazzy targets Ubuntu 24.04 — do not mix versions
#                    * MoveIt 2 for Humble installed (motion planning)
#                    * mycobot_ros2 humble branch cloned and built
#                    * GNOME portal fix NOT needed (22.04 does not have the
#                      xdg-desktop-portal-gnome deadlock seen on 24.04 ARM64)
#
# Steps:
#  STEP  1 - Update, Upgrade, and Autoremove
#  STEP  2 - Core System and Networking Tools
#  STEP  3 - Python Tools
#  STEP  4 - Hardware, GPIO, I2C, Serial, and ESP Tools
#  STEP  5 - UART Configuration for myCobot 280 Pi (ttyAMA0)
#  STEP  6 - Robot Python Environment and pymycobot
#  STEP  7 - Text Editors and IDEs (VS Code ARM64 + Thonny)
#  STEP  8 - Web Browser (Chromium ARM64)
#  STEP  9 - Docker and Docker Compose
#  STEP 10 - GNOME Desktop Tweaks and neofetch
#  STEP 11 - VNC Remote Desktop (gnome-remote-desktop)
#  STEP 12 - Arduino (Legacy 1.8.x ARM64 via apt)
#  STEP 13 - Git Global Config (interactive)
#  STEP 14 - ROS 2 Humble + MoveIt 2 + myCobot ROS Package
#  STEP 15 - Verify All Installs
#
# References:
#   https://ubuntu.com/tutorials/how-to-install-ubuntu-on-raspberry-pi
#   https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html
#   https://github.com/elephantrobotics/pymycobot
#   https://github.com/elephantrobotics/mycobot_ros2
#   https://gpiozero.readthedocs.io/en/stable/
#   https://docs.docker.com/engine/install/ubuntu/
#   https://code.visualstudio.com/docs/setup/linux
#   https://docs.platformio.org/en/latest/core/installation/index.html
# ============================================================================

# ============================================================================
# LOGGING SETUP
# ============================================================================
LOG_FILE="$HOME/log-Auto-Pi4-Ubuntu-Desk-22.04-Tools-Apps-Install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================"
echo "  LOGGING ENABLED"
echo "  Log file: $LOG_FILE"
echo "  All terminal output is being saved to that file."
echo "============================================================"
echo " "

# ============================================================================
# ARCHITECTURE AND VERSION CHECK
# ============================================================================
ARCH=$(uname -m)
UBUNTU_VER=$(lsb_release -rs 2>/dev/null || echo "unknown")

echo "Detected architecture: $ARCH"
echo "Detected Ubuntu version: $UBUNTU_VER"

if [ "$ARCH" != "aarch64" ]; then
    echo "WARNING: This script targets ARM64 (aarch64). Detected: $ARCH"
    echo "Do you wish to continue anyway?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No  ) echo "Exiting."; exit 1;;
        esac
    done
fi

if [[ "$UBUNTU_VER" != 22.* ]]; then
    echo "WARNING: This script targets Ubuntu 22.04.x. Detected: $UBUNTU_VER"
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
echo " "
echo "Robots & Rovers — Fire Breathing Robots"
echo "============================================================"
echo "  Raspberry Pi 4B Ubuntu 22.04 Desktop - Tools & Apps Install"
echo "  Revision 0.01"
echo "  Target: Pi 4B / ARM64 / Ubuntu 22.04.5 LTS Desktop"
echo "  For: Fire Breathing Robots / Mechatronics Curriculum"
echo "  Log: $LOG_FILE"
echo "============================================================"
echo " "
pwd
echo " "

# ============================================================================
# STEP 1 - UPDATE, UPGRADE, AND AUTOREMOVE
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 1 - UPDATE, UPGRADE, AND AUTOREMOVE"
echo "============================================================"

    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    sudo apt-get update

    echo "----------------------------------------------------"
    echo "Done: UPDATE AND UPGRADE"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 2 - CORE SYSTEM AND NETWORKING TOOLS
#
#   curl           - Downloads keys, installers, and scripts
#   git            - Version control; clones curriculum and robot repos
#   openssh-server - SSH remote access to the Pi
#   net-tools      - ifconfig for IP address display
#   htop           - Interactive process/resource monitor
#   tree           - Visual directory tree display
#   wget           - Command-line file downloader
#   nmap           - Network scanner; finds Pi/Arduino IPs on lab network
#   minicom        - Serial terminal for Arduino/ESP debugging
#   neofetch       - System info banner (distro, CPU, RAM, etc.)
#   apt-transport-https - Required for HTTPS apt repos (VS Code, Docker)
#   ca-certificates     - HTTPS certificate validation
#   gnupg               - GPG key management for apt repos
#   lsb-release         - Ubuntu codename for repo setup strings
#   software-properties-common - add-apt-repository command
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 2 - CORE SYSTEM AND NETWORKING TOOLS"
echo "  Installing:"
echo "    - curl, git, openssh-server, net-tools"
echo "    - htop, tree, wget, nmap, minicom, neofetch"
echo "    - apt-transport-https, ca-certificates, gnupg"
echo "    - lsb-release, software-properties-common"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing core system and networking tools"
    echo "----------------------------------------------------"
    sudo apt-get install -y \
        curl \
        git \
        openssh-server \
        net-tools \
        htop \
        tree \
        wget \
        nmap \
        minicom \
        neofetch \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common

    sudo ufw --force enable
    sudo ufw allow ssh
    echo "  ufw enabled and SSH rule added"

    echo " "
    echo "----------------------------------------------------"
    echo "Done: CORE SYSTEM AND NETWORKING TOOLS"
    echo "  Pi IP: $(hostname -I | awk '{print $1}')"
    echo "  SSH:   ssh $USER@$(hostname -I | awk '{print $1}')"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 3 - PYTHON TOOLS
#
# Ubuntu 22.04 ships with Python 3.10.
# NOTE: Ubuntu 22.04 does NOT enforce PEP 668 externally-managed-environment
#       (that restriction was added in Ubuntu 24.04 / Bookworm). pip installs
#       work system-wide. However, we still create a robot venv in Step 6
#       as best practice for isolating robot packages from system Python.
#
#   python3-pip    - pip package manager
#   python3-venv   - Virtual environment support
#   python3-dev    - Python C headers for native pip packages
#   python3-full   - Full Python 3 install (ensures venv module present)
#   build-essential - gcc/g++/make toolchain for compiling native modules
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 3 - PYTHON TOOLS"
echo "  Installing:"
echo "    - python3-pip, python3-venv, python3-dev, python3-full"
echo "    - build-essential (gcc/make toolchain)"
echo "  Note: Ubuntu 22.04 does NOT enforce PEP 668."
echo "        pip installs work without --break-system-packages."
echo "        Robot packages will be installed into a venv in Step 6."
echo "============================================================"

    sudo apt-get install -y \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-full \
        build-essential

    echo "----------------------------------------------------"
    echo "Done: PYTHON TOOLS"
    echo "----------------------------------------------------"
    python3 --version
    pip3 --version

# ============================================================================
# STEP 4 - HARDWARE, GPIO, I2C, SERIAL, AND ESP TOOLS
#
# IMPORTANT NOTE ON GPIO LIBRARIES FOR UBUNTU 22.04 / PI 4B:
#   pigpio IS available in Ubuntu 22.04 apt repos (unlike Ubuntu 24.04).
#   gpiozero works with either pigpio or lgpio on Ubuntu 22.04.
#   For myCobot 280 Pi robot arm projects, GPIO is rarely used directly —
#   the arm communicates via UART (/dev/ttyAMA0), not GPIO pins.
#   GPIO libraries are included for rover and electronics curriculum.
#
#   python3-gpiozero  - High-level GPIO library; student-friendly API
#   python3-lgpio     - Low-level lgpio (preferred backend for Ubuntu 22.04 Pi)
#   pigpio            - Legacy GPIO daemon (available in 22.04, unlike 24.04)
#   python3-serial    - PySerial; UART comms with Arduino, robot arm, GPS
#   python3-smbus     - I2C bus access for sensors
#   i2c-tools         - CLI: i2cdetect -y 1 to scan I2C bus
#   esptool           - Flash ESP32/ESP8266 from Pi
#   cheese            - Webcam viewer for rover camera testing
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 4 - HARDWARE, GPIO, I2C, SERIAL, AND ESP TOOLS"
echo "  Installing:"
echo "    - python3-gpiozero (high-level GPIO)"
echo "    - python3-lgpio, pigpio (GPIO backends; both available on 22.04)"
echo "    - python3-serial (PySerial; UART/serial comms)"
echo "    - python3-smbus  (I2C sensor access)"
echo "    - i2c-tools      (i2cdetect and I2C CLI utilities)"
echo "    - esptool        (ESP32/ESP8266 flash tool)"
echo "    - cheese         (webcam viewer)"
echo "  Also: adds $USER to dialout, i2c, plugdev groups"
echo "============================================================"

    sudo apt-get install -y \
        python3-gpiozero \
        python3-lgpio \
        pigpio \
        python3-pigpio \
        python3-serial \
        python3-smbus \
        i2c-tools \
        esptool \
        cheese

    echo " "
    echo "----------------------------------------------------"
    echo "Enabling pigpio daemon service"
    echo "  Required for pigpio GPIO backend"
    echo "----------------------------------------------------"
    sudo systemctl enable pigpiod
    sudo systemctl start pigpiod

    echo " "
    echo "----------------------------------------------------"
    echo "Adding $USER to hardware access groups"
    echo "  dialout - serial/USB port access (myCobot UART + Arduino)"
    echo "  i2c     - I2C bus access"
    echo "  plugdev - USB device access"
    echo "  NOTE: Log out and back in for group changes to take effect"
    echo "----------------------------------------------------"
    sudo usermod -aG dialout "$USER"
    sudo usermod -aG i2c     "$USER"
    sudo usermod -aG plugdev "$USER"

    # gpio group may or may not exist on Ubuntu 22.04
    if getent group gpio > /dev/null 2>&1; then
        sudo usermod -aG gpio "$USER"
        echo "  Added $USER to gpio group"
    else
        echo "  gpio group not present on this system (normal on Ubuntu 22.04)"
        echo "  GPIO access managed via udev rules"
    fi

    echo "  User $USER added to dialout, i2c, plugdev groups"

    echo " "
    echo "----------------------------------------------------"
    echo "Done: HARDWARE, GPIO, I2C, SERIAL, AND ESP TOOLS"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 5 - UART CONFIGURATION FOR myCobot 280 Pi
#
# The Pi 4B has two internal UARTs:
#
#   PL011  (/dev/ttyAMA0) - Full hardware UART. Precise baud rates,
#                           hardware flow control. HIGH QUALITY.
#                           Default owner: Bluetooth
#
#   mini UART (/dev/ttyS0) - Software-emulated. Clock tied to CPU
#                            frequency — baud rate drifts under load.
#                            LOW QUALITY. Default owner: serial console
#
# The myCobot 280 Pi arm REQUIRES the PL011 at exactly 1,000,000 baud.
# The mini UART cannot reliably sustain that rate, so the robot arm will
# not respond if connected to the wrong UART.
#
# What dtoverlay=disable-bt does:
#   It SWAPS the UARTs — moves Bluetooth from PL011 to mini UART and
#   frees PL011 as /dev/ttyAMA0 for the robot arm. The name "disable-bt"
#   is misleading: it does NOT destroy the Bluetooth hardware, it just
#   reassigns which UART Bluetooth uses.
#
# What core_freq=250 does:
#   Pins the VPU core clock at 250 MHz so the mini UART's baud rate
#   is stable. Without this, the mini UART clock drifts with CPU load,
#   making Bluetooth on the mini UART unreliable. Setting core_freq=250
#   makes the mini UART usable again, leaving the door open for Bluetooth
#   to be re-enabled later if needed.
#
# Bluetooth service handling:
#   hciuart is disabled because it tries to use the PL011 (now robot arm).
#   bluetooth is disabled but NOT masked — this preserves the ability to
#   re-enable it later via: sudo systemctl enable bluetooth && sudo reboot
#   To fully re-enable BT: also uncomment 'enable_uart=0' in config.txt
#   and run: sudo rfkill unblock bluetooth
#
# Changes made to /boot/firmware/config.txt:
#   dtoverlay=disable-bt   - Swap PL011 to robot, mini UART to Bluetooth
#   enable_uart=1          - Enable PL011 as /dev/ttyAMA0
#   core_freq=250          - Pin mini UART clock for stable baud rate
#
# Changes made to /boot/firmware/cmdline.txt:
#   Remove console=serial0,115200 if present (frees PL011 from console)
#
# These changes take effect after the reboot at the end of this script.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 5 - UART CONFIGURATION FOR myCobot 280 Pi"
echo "  Pi 4B has two UARTs:"
echo "    PL011     (/dev/ttyAMA0) - full hardware UART, high quality"
echo "    mini UART (/dev/ttyS0)   - software-emulated, clock-dependent"
echo " "
echo "  dtoverlay=disable-bt SWAPS them:"
echo "    PL011     -> freed for robot arm (/dev/ttyAMA0 @ 1,000,000 baud)"
echo "    mini UART -> Bluetooth moves here"
echo "    core_freq=250 -> pins mini UART clock so baud rate is stable"
echo " "
echo "  Bluetooth hardware is NOT destroyed — it moves to mini UART."
echo "  bluetooth service disabled (not masked) — can be re-enabled later."
echo "  hciuart disabled — it targeted the PL011 (now robot arm)."
echo " "
echo "  TAKES EFFECT AFTER REBOOT at end of this script."
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Step 5a: Adding UART overlay to /boot/firmware/config.txt"
    echo "----------------------------------------------------"

    # Only add if not already present
    if grep -q "disable-bt" /boot/firmware/config.txt; then
        echo "  dtoverlay=disable-bt already present in config.txt — skipping"
    else
        sudo tee -a /boot/firmware/config.txt > /dev/null << 'CONFIGEOF'

# ── myCobot 280 Pi UART configuration ────────────────────────────────────────
# The Pi 4B has two UARTs:
#   PL011     (/dev/ttyAMA0) full hardware UART  — default owner: Bluetooth
#   mini UART (/dev/ttyS0)   software-emulated   — default owner: serial console
#
# dtoverlay=disable-bt  SWAPS ownership (misleading name — does NOT kill BT):
#   PL011     -> freed for myCobot arm serial link @ 1,000,000 baud
#   mini UART -> Bluetooth moves here
#
# enable_uart=1    activates PL011 as /dev/ttyAMA0 for the robot arm
#
# core_freq=250    pins the VPU core clock at 250 MHz so the mini UART
#                  baud rate is stable (mini UART clock = VPU core / 2).
#                  Without this, mini UART baud drifts with CPU load.
#                  This keeps the door open for Bluetooth re-use on mini UART.
#
# To re-enable Bluetooth later (if needed):
#   sudo systemctl enable bluetooth && sudo rfkill unblock bluetooth
#   Then reboot. BT will run on mini UART at stable clock.
dtoverlay=disable-bt
enable_uart=1
core_freq=250
# ─────────────────────────────────────────────────────────────────────────────
CONFIGEOF
        echo "  Added dtoverlay=disable-bt, enable_uart=1, core_freq=250 to config.txt"
    fi

    echo " "
    echo "----------------------------------------------------"
    echo "Step 5b: Removing serial console from cmdline.txt (if present)"
    echo "----------------------------------------------------"
    if grep -q "console=serial0\|console=ttyAMA0" /boot/firmware/cmdline.txt; then
        sudo sed -i 's/console=serial0,[0-9]* //g' /boot/firmware/cmdline.txt
        sudo sed -i 's/console=ttyAMA0,[0-9]* //g' /boot/firmware/cmdline.txt
        echo "  Removed serial console from cmdline.txt"
    else
        echo "  No serial console entry found in cmdline.txt — nothing to remove"
    fi

    echo " "
    echo "----------------------------------------------------"
    echo "Step 5c: Adjusting Bluetooth services"
    echo "  hciuart  - DISABLED: it tries to use PL011 (now robot arm)"
    echo "  bluetooth - DISABLED: not needed at boot; NOT masked so it"
    echo "              can be re-enabled later if BT hardware is needed"
    echo "  To re-enable Bluetooth later:"
    echo "    sudo systemctl enable bluetooth"
    echo "    sudo rfkill unblock bluetooth"
    echo "    sudo reboot"
    echo "----------------------------------------------------"
    sudo systemctl disable hciuart 2>/dev/null || true
    sudo systemctl disable bluetooth
    # NOT masking bluetooth — leaves the door open for future re-enable
    echo "  hciuart:   disabled (was targeting PL011 — now robot arm)"
    echo "  bluetooth: disabled (NOT masked — re-enable anytime if needed)"

    echo " "
    echo "----------------------------------------------------"
    echo "Step 5d: Verifying config.txt changes"
    echo "----------------------------------------------------"
    echo "  config.txt UART/BT lines:"
    grep -E "disable-bt|enable_uart|core_freq" /boot/firmware/config.txt \
        && echo "  [PASS] UART config lines present" \
        || echo "  [FAIL] UART config lines missing — check /boot/firmware/config.txt"

    echo " "
    echo "  Expected config.txt entries:"
    echo "    dtoverlay=disable-bt  (swap PL011 to robot, mini UART to BT)"
    echo "    enable_uart=1         (activate PL011 as /dev/ttyAMA0)"
    echo "    core_freq=250         (pin mini UART clock for stable baud rate)"

    echo " "
    echo "  cmdline.txt (serial console tokens should be absent):"
    cat /boot/firmware/cmdline.txt

    echo " "
    echo "  bluetooth service status:"
    systemctl is-enabled bluetooth 2>/dev/null || echo "  unknown"
    echo "  hciuart service status:"
    systemctl is-enabled hciuart 2>/dev/null || echo "  disabled/not-found (expected)"

    echo " "
    echo "----------------------------------------------------"
    echo "Done: UART CONFIGURATION"
    echo "  Changes take effect after reboot."
    echo "  After reboot verify with:"
    echo "    ls -l /dev/ttyAMA0"
    echo "    Expected: crw-rw---- 1 root dialout ..."
    echo " "
    echo "  Bluetooth hardware remains intact on mini UART."
    echo "  To re-enable BT: sudo systemctl enable bluetooth && sudo reboot"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 6 - ROBOT PYTHON ENVIRONMENT AND pymycobot
#
# Creates a dedicated Python virtual environment for robot projects and
# installs pymycobot (the Elephant Robotics Python API for myCobot 280 Pi).
#
# Virtual environment location: ~/robot-env
# Auto-activated on login via ~/.bashrc
#
# pymycobot usage on Pi:
#   from pymycobot import MyCobot280, PI_PORT, PI_BAUD
#   mc = MyCobot280(PI_PORT, PI_BAUD)   # PI_PORT=/dev/ttyAMA0, PI_BAUD=1000000
#
# NOTE: MyCobot280 is the current class (pymycobot v3.6.0+).
#       The older MyCobot class is deprecated — do not use it.
#
# Also installs:
#   pyserial - Serial communication library
#   numpy    - Numerical computing; used in motion planning examples
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 6 - ROBOT PYTHON ENVIRONMENT AND pymycobot"
echo "  Creating Python venv at ~/robot-env"
echo "  Installing: pymycobot, pyserial, numpy"
echo "  Auto-activating venv in ~/.bashrc"
echo "  pymycobot API: MyCobot280(PI_PORT, PI_BAUD)"
echo "  PI_PORT=/dev/ttyAMA0  PI_BAUD=1000000"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Creating robot Python virtual environment at ~/robot-env"
    echo "----------------------------------------------------"
    python3 -m venv "$HOME/robot-env"
    source "$HOME/robot-env/bin/activate"
    pip install --upgrade pip

    echo " "
    echo "----------------------------------------------------"
    echo "Installing pymycobot, pyserial, numpy into robot-env"
    echo "----------------------------------------------------"
    pip install pymycobot pyserial numpy
    echo "  Installed packages:"
    pip show pymycobot | grep -E "Name|Version"
    pip show pyserial  | grep -E "Name|Version"
    pip show numpy     | grep -E "Name|Version"

    echo " "
    echo "----------------------------------------------------"
    echo "Adding robot-env auto-activation to ~/.bashrc"
    echo "  venv will activate automatically on every new terminal"
    echo "----------------------------------------------------"
    if ! grep -q 'robot-env' "$HOME/.bashrc"; then
        echo ""                                            >> "$HOME/.bashrc"
        echo "# myCobot robot Python environment"         >> "$HOME/.bashrc"
        echo "source \$HOME/robot-env/bin/activate"      >> "$HOME/.bashrc"
        echo "  Added robot-env activation to ~/.bashrc"
    else
        echo "  robot-env already in ~/.bashrc — skipping"
    fi

    echo " "
    echo "----------------------------------------------------"
    echo "Creating robot project directories"
    echo "----------------------------------------------------"
    mkdir -p "$HOME/robot-labs/python-only"
    mkdir -p "$HOME/robot-labs/ros2"
    echo "  Created: ~/robot-labs/python-only"
    echo "  Created: ~/robot-labs/ros2"

    echo " "
    echo "----------------------------------------------------"
    echo "Writing connection test script to ~/robot-labs/python-only/"
    echo "----------------------------------------------------"
    cat > "$HOME/robot-labs/python-only/test_connection.py" << 'PYEOF'
#!/usr/bin/env python3
# test_connection.py — myCobot 280 Pi connection verification
# Run this after every fresh SD card build to confirm everything works.
# Usage: python test_connection.py

import sys
import time
from pymycobot import MyCobot280, PI_PORT, PI_BAUD

print("=" * 52)
print("  myCobot 280 Pi — Python Connection Test")
print("=" * 52)
print(f"  Port : {PI_PORT}")
print(f"  Baud : {PI_BAUD}")
print()

try:
    mc = MyCobot280(PI_PORT, PI_BAUD)
    time.sleep(1)
    print("[PASS] MyCobot280 object created")
except Exception as e:
    print(f"[FAIL] Could not create MyCobot280: {e}")
    sys.exit(1)

connected = mc.is_controller_connected()
if connected:
    print("[PASS] Atom controller connected")
else:
    print("[FAIL] Atom controller not responding")
    print("       Check: arm powered on? Atom LED lit?")
    sys.exit(1)

angles = mc.get_angles()
if angles and len(angles) == 6:
    print(f"[PASS] Joint angles: {angles}")
else:
    print(f"[FAIL] get_angles() returned: {angles}")
    sys.exit(1)

coords = mc.get_coords()
if coords and len(coords) == 6:
    print(f"[PASS] Cartesian coords: {coords}")
else:
    print(f"[FAIL] get_coords() returned: {coords}")
    sys.exit(1)

errors = mc.get_error_information()
print(f"[INFO] Error flags: {errors}")

print()
print("Flashing LED green x3 — watch the wrist tip...")
for _ in range(3):
    mc.set_color(0, 255, 0)
    time.sleep(0.4)
    mc.set_color(0, 0, 0)
    time.sleep(0.3)

print()
print("=" * 52)
print("  ALL TESTS PASSED — arm ready for lab use")
print("=" * 52)
PYEOF
    chmod +x "$HOME/robot-labs/python-only/test_connection.py"
    echo "  test_connection.py written"

    echo " "
    echo "----------------------------------------------------"
    echo "Adding robot convenience aliases to ~/.bashrc"
    echo "----------------------------------------------------"
    if ! grep -q 'robot-test' "$HOME/.bashrc"; then
        echo ""                                                        >> "$HOME/.bashrc"
        echo "# myCobot shortcuts"                                     >> "$HOME/.bashrc"
        echo "alias robot-test='python \$HOME/robot-labs/python-only/test_connection.py'" \
                                                                       >> "$HOME/.bashrc"
        echo "alias robot-labs='cd \$HOME/robot-labs && ls'"          >> "$HOME/.bashrc"
        echo "  Aliases robot-test and robot-labs added to ~/.bashrc"
    else
        echo "  Aliases already in ~/.bashrc — skipping"
    fi

    echo " "
    echo "----------------------------------------------------"
    echo "Done: ROBOT PYTHON ENVIRONMENT AND pymycobot"
    echo "  Run test after reboot: robot-test"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 7 - TEXT EDITORS AND IDEs
#
#   vim      - Classic terminal editor; essential for SSH config editing
#   nano     - Simple terminal editor; better default for students
#   thonny   - Beginner Python IDE; configure to use ~/robot-env
#   code     - VS Code via Microsoft ARM64 .deb repo
#              NOTE: VS Code snap is amd64 ONLY — does not work on Pi ARM64
#              Use Microsoft's official ARM64 .deb repository instead
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 7 - TEXT EDITORS AND IDEs"
echo "  Installing:"
echo "    - vim, nano  (terminal editors)"
echo "    - thonny     (beginner Python IDE; good for students)"
echo "    - VS Code    (via Microsoft official ARM64 .deb repo)"
echo "  NOTE: VS Code snap is amd64 ONLY and fails on Pi ARM64."
echo "        Using Microsoft's official .deb ARM64 repo."
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing vim and nano"
    echo "----------------------------------------------------"
    sudo apt-get install -y vim nano

    echo " "
    echo "----------------------------------------------------"
    echo "Installing Thonny Python IDE"
    echo "  After install, point Thonny at the robot venv:"
    echo "  Tools > Options > Interpreter > Alternative Python 3"
    echo "  Browse to: /home/$USER/robot-env/bin/python"
    echo "----------------------------------------------------"
    sudo apt-get install -y thonny

    echo " "
    echo "----------------------------------------------------"
    echo "Installing VS Code via Microsoft ARM64 .deb repository"
    echo "  Step 7a: Add Microsoft GPG key"
    echo "----------------------------------------------------"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
        sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
    sudo chmod a+r /etc/apt/keyrings/microsoft.gpg
    echo "  Microsoft GPG key added"

    echo "  Step 7b: Add VS Code ARM64 apt repository"
    echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    echo "  VS Code repository added"

    echo "  Step 7c: Update apt and install VS Code"
    sudo apt-get update
    sudo apt-get install -y code

    echo " "
    echo "----------------------------------------------------"
    echo "Configuring nano with sane defaults for students"
    echo "  Line numbers, 4-space tabs, auto-indent"
    echo "----------------------------------------------------"
    if ! grep -q 'set linenumbers' "$HOME/.nanorc" 2>/dev/null; then
        cat >> "$HOME/.nanorc" << 'NANOEOF'
set linenumbers
set tabsize 4
set tabstospaces
set autoindent
NANOEOF
        echo "  nano defaults written to ~/.nanorc"
    else
        echo "  ~/.nanorc already configured — skipping"
    fi

    echo " "
    echo "----------------------------------------------------"
    echo "Done: TEXT EDITORS AND IDEs"
    echo "----------------------------------------------------"
    code --version 2>/dev/null | head -1 && echo "  VS Code: OK" || \
        echo "  VS Code: verify with 'code --version' in a new terminal"

# ============================================================================
# STEP 8 - WEB BROWSER (CHROMIUM ARM64)
# Google Chrome has no ARM64 Linux build.
# Chromium is the correct ARM64 browser for Ubuntu on Pi 4B.
# On Ubuntu 22.04, chromium-browser installs via apt (not snap — snap is
# used on newer Ubuntu but the apt package works cleanly on 22.04).
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 8 - WEB BROWSER (CHROMIUM ARM64)"
echo "  Installing chromium-browser (ARM64 native)"
echo "  NOTE: Google Chrome amd64 .deb will NOT install on Pi ARM64"
echo "============================================================"

    sudo apt-get install -y chromium-browser

    echo "----------------------------------------------------"
    echo "Done: WEB BROWSER"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 9 - DOCKER AND DOCKER COMPOSE
# Installs Docker CE from the official Docker apt repository.
# The Ubuntu apt package 'docker.io' is outdated.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 9 - DOCKER AND DOCKER COMPOSE"
echo "  Installing Docker CE from official Docker apt repository"
echo "  (NOT docker.io from Ubuntu repos — that version is outdated)"
echo "  Docs: https://docs.docker.com/engine/install/ubuntu/"
echo "============================================================"

    echo "----------------------------------------------------"
    echo "Removing any old conflicting Docker packages"
    echo "----------------------------------------------------"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 \
                podman-docker containerd runc; do
        sudo apt-get remove -y "$pkg" 2>/dev/null || true
    done

    echo "----------------------------------------------------"
    echo "Adding Docker GPG key and repository"
    echo "----------------------------------------------------"
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    sudo usermod -aG docker "$USER"
    sudo systemctl enable docker
    sudo systemctl start docker

    docker --version
    docker compose version

    echo "----------------------------------------------------"
    echo "Done: DOCKER AND DOCKER COMPOSE"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 10 - GNOME DESKTOP TWEAKS AND NEOFETCH
# Prevents screen locking during student demos or long compiles.
# NOTE: The xdg-desktop-portal-gnome deadlock seen on Ubuntu 24.04 + Pi 5
#       is NOT present on Ubuntu 22.04 + Pi 4B. No portal fix needed here.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 10 - GNOME DESKTOP TWEAKS AND NEOFETCH"
echo "  - Extend idle/screensaver delay (classroom demo friendly)"
echo "  - Add neofetch to ~/.bashrc"
echo "  NOTE: No xdg-desktop-portal fix needed on Ubuntu 22.04"
echo "============================================================"

    gsettings set org.gnome.desktop.session     idle-delay   800
    gsettings set org.gnome.desktop.screensaver lock-delay   900

    if ! grep -q 'neofetch' "$HOME/.bashrc"; then
        echo ""                                            >> "$HOME/.bashrc"
        echo "# Show system info on terminal open"        >> "$HOME/.bashrc"
        echo "neofetch"                                   >> "$HOME/.bashrc"
        echo "  neofetch added to ~/.bashrc"
    else
        echo "  neofetch already in ~/.bashrc — skipping"
    fi

    echo "----------------------------------------------------"
    echo "Done: GNOME DESKTOP TWEAKS"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 11 - VNC REMOTE DESKTOP
# gnome-remote-desktop is the built-in Ubuntu VNC/RDP server.
# After install: Settings > Sharing > Remote Desktop > Enable
# Connect from a laptop with TigerVNC or RealVNC Viewer on port 5900.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 11 - VNC REMOTE DESKTOP"
echo "  Installing gnome-remote-desktop (built-in Ubuntu VNC server)"
echo "  After install: Settings > Sharing > Remote Desktop > Enable"
echo "  Client: TigerVNC (https://tigervnc.org/) or RealVNC"
echo "  Connect: vnc://<pi-ip>:5900"
echo "============================================================"

    sudo apt-get install -y gnome-remote-desktop

    echo "----------------------------------------------------"
    echo "Done: VNC REMOTE DESKTOP"
    echo "  Manual steps required after reboot:"
    echo "  1. Settings > Sharing > Remote Desktop > ON"
    echo "  2. Toggle Remote Control ON"
    echo "  3. Set VNC password"
    echo "  4. Connect: vnc://$(hostname -I | awk '{print $1}'):5900"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 12 - ARDUINO (LEGACY 1.8.x ARM64 VIA APT)
#
# Arduino IDE 2.x has NO official ARM64 Linux build.
# Arduino Legacy 1.8.x via apt is ARM64 native and fully functional.
# For students using PlatformIO in VS Code, this step is supplementary.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 12 - ARDUINO (Legacy 1.8.x ARM64 via apt)"
echo "  NOTE: Arduino IDE 2.x has no official ARM64 Linux build."
echo "  Installing Arduino Legacy 1.8.x (ARM64 native, from Ubuntu repos)"
echo "  Launch: arduino   or   Applications > Programming > Arduino IDE"
echo "============================================================"

    sudo apt-get install -y arduino
    sudo usermod -aG dialout "$USER"   # ensure dialout group for USB upload

    echo "----------------------------------------------------"
    echo "Done: ARDUINO LEGACY 1.8.x"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 13 - GIT GLOBAL CONFIG (interactive)
# Sets git global user.name and user.email for all commits on this Pi.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 13 - GIT GLOBAL CONFIG"
echo "  Setting git global user name, email, and default editor"
echo "============================================================"

    echo " "
    read -p "  Git user name  (e.g. Jim Burnham): " GIT_NAME
    read -p "  Git email      (e.g. jburnham@metroed.net): " GIT_EMAIL

    git config --global user.name  "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global core.editor "code --wait"
    git config --global init.defaultBranch main

    echo " "
    echo "  Git config set:"
    echo "    user.name          = $GIT_NAME"
    echo "    user.email         = $GIT_EMAIL"
    echo "    core.editor        = code --wait"
    echo "    init.defaultBranch = main"
    echo "  View anytime: git config --list --global"

    echo "----------------------------------------------------"
    echo "Done: GIT GLOBAL CONFIG"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 14 - ROS 2 HUMBLE + MOVEIT 2 + myCobot ROS 2 PACKAGE
#
# ROS 2 Humble Hawksbill is the correct ROS 2 version for Ubuntu 22.04 LTS.
# Do NOT install ROS 2 Jazzy here — Jazzy targets Ubuntu 24.04.
# There is a strict one-to-one pairing between ROS 2 and Ubuntu versions.
#
# Installs:
#   ros-humble-desktop         - RViz 2, rqt, core libraries, demo nodes
#   ros-humble-moveit          - Motion planning framework
#   ros-dev-tools              - colcon, rosdep, vcstool, argcomplete
#   python3-colcon-common-extensions - colcon build tool
#   python3-rosdep             - Dependency management
#
# Workspace: ~/colcon_ws
# myCobot ROS 2 package: elephantrobotics/mycobot_ros2 (humble branch)
#
# NOTE: ROS 2 is sourced AFTER robot-env in ~/.bashrc.
#       Load order: robot-env → ROS 2 → colcon_ws
#       This ensures pymycobot is available to ROS 2 nodes.
#
# WARNING: This step downloads ~1.5 GB and takes 25-40 minutes on Pi 4B.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 14 - ROS 2 HUMBLE + MOVEIT 2 + myCobot ROS 2 PACKAGE"
echo "  ROS 2 Humble is paired with Ubuntu 22.04 LTS (do not mix versions)"
echo "  WARNING: Downloads ~1.5 GB. Takes 25-40 min on Pi 4B."
echo "  Installing:"
echo "    - ros-humble-desktop (RViz2, rqt, core libraries)"
echo "    - ros-humble-moveit  (motion planning)"
echo "    - ros-dev-tools      (colcon, rosdep, vcstool)"
echo "    - mycobot_ros2 package (humble branch)"
echo "  Workspace: ~/colcon_ws"
echo "============================================================"

    # ---- 14a: Locale check ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14a: Verify UTF-8 locale (required by ROS 2)"
    echo "----------------------------------------------------"
    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    locale | grep LANG

    # ---- 14b: Enable Universe repo ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14b: Enable Ubuntu universe repository"
    echo "----------------------------------------------------"
    sudo add-apt-repository universe -y
    sudo apt-get update

    # ---- 14c: Add ROS 2 repository ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14c: Add ROS 2 Humble apt repository"
    echo "----------------------------------------------------"
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu \
$(. /etc/os-release && echo $UBUNTU_CODENAME) main" | \
        sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

    sudo apt-get update
    echo "  ROS 2 Humble repository added"

    # Verify repo is visible
    echo "  Verifying ros-humble-desktop is reachable:"
    apt-cache policy ros-humble-desktop 2>/dev/null | head -3

    # ---- 14d: Install ROS 2 Humble Desktop ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14d: Install ros-humble-desktop"
    echo "  This takes 20-30 minutes on Pi 4B. Be patient."
    echo "----------------------------------------------------"
    sudo apt-get install -y ros-humble-desktop

    # ---- 14e: Install ROS 2 dev tools ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14e: Install ROS 2 development tools"
    echo "----------------------------------------------------"
    sudo apt-get install -y \
        python3-colcon-common-extensions \
        python3-rosdep \
        python3-vcstool \
        python3-argcomplete \
        ros-dev-tools

    # ---- 14f: Install MoveIt 2 ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14f: Install MoveIt 2 for motion planning"
    echo "  This takes 10-15 additional minutes."
    echo "----------------------------------------------------"
    sudo apt-get install -y ros-humble-moveit

    # ---- 14g: Initialize rosdep ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14g: Initialize and update rosdep"
    echo "----------------------------------------------------"
    sudo rosdep init 2>/dev/null || echo "  rosdep already initialized"
    rosdep update

    # ---- 14h: Source ROS 2 in .bashrc ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14h: Source ROS 2 Humble in ~/.bashrc"
    echo "  Load order: robot-env -> ROS 2 -> colcon_ws"
    echo "----------------------------------------------------"
    if ! grep -q 'ros/humble' "$HOME/.bashrc"; then
        echo ""                                                     >> "$HOME/.bashrc"
        echo "# ROS 2 Humble"                                      >> "$HOME/.bashrc"
        echo "source /opt/ros/humble/setup.bash"                   >> "$HOME/.bashrc"
        echo "  Added ROS 2 source to ~/.bashrc"
    else
        echo "  ROS 2 already in ~/.bashrc — skipping"
    fi

    # Activate ROS 2 for the remainder of this script
    source /opt/ros/humble/setup.bash

    # ---- 14i: colcon tab completion ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14i: Add colcon tab completion to ~/.bashrc"
    echo "----------------------------------------------------"
    if ! grep -q 'colcon_argcomplete' "$HOME/.bashrc"; then
        echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" \
            >> "$HOME/.bashrc"
        echo "  colcon completion added"
    else
        echo "  colcon completion already in ~/.bashrc"
    fi

    # ---- 14j: Create colcon workspace ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14j: Create colcon workspace at ~/colcon_ws"
    echo "----------------------------------------------------"
    mkdir -p "$HOME/colcon_ws/src"
    cd "$HOME/colcon_ws"
    colcon build
    echo ""                                                        >> "$HOME/.bashrc"
    echo "# colcon workspace"                                      >> "$HOME/.bashrc"
    echo "source \$HOME/colcon_ws/install/setup.bash"             >> "$HOME/.bashrc"
    source "$HOME/colcon_ws/install/setup.bash"
    echo "  colcon workspace created and sourced"

    # ---- 14k: Clone mycobot_ros2 package ----
    echo " "
    echo "----------------------------------------------------"
    echo "Step 14k: Clone mycobot_ros2 (humble branch)"
    echo "  Source: elephantrobotics/mycobot_ros2"
    echo "  This build takes 10-15 minutes on Pi 4B."
    echo "----------------------------------------------------"
    cd "$HOME/colcon_ws/src"

    if [ -d "mycobot_ros2" ]; then
        echo "  mycobot_ros2 already present — pulling latest"
        cd mycobot_ros2 && git pull && cd ..
    else
        git clone -b humble --depth 1 \
            https://github.com/elephantrobotics/mycobot_ros2.git
    fi

    cd "$HOME/colcon_ws"
    rosdep install --from-paths src --ignore-src -y
    colcon build --symlink-install
    source install/setup.bash

    echo " "
    echo "----------------------------------------------------"
    echo "Step 14k: Verifying myCobot ROS 2 package installed"
    echo "----------------------------------------------------"
    ros2 pkg list | grep mycobot && echo "  [PASS] mycobot package found" \
        || echo "  [WARN] mycobot not in ros2 pkg list — source ~/.bashrc and check"

    echo " "
    echo "----------------------------------------------------"
    echo "Done: ROS 2 HUMBLE + MOVEIT 2 + myCobot ROS 2 PACKAGE"
    echo " "
    echo "  Quick start commands (after reboot):"
    echo "    Slider control:"
    echo "      ros2 launch mycobot_280pi slider_control.launch.py \\"
    echo "        port:=/dev/ttyAMA0 baud:=1000000"
    echo "    MoveIt 2:"
    echo "      ros2 launch mycobot_280pi mycobot_280pi_moveit.launch.py \\"
    echo "        port:=/dev/ttyAMA0 baud:=1000000"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 15 - VERIFY ALL INSTALLS
# Quick version check on all installed tools.
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 15 - VERIFY ALL INSTALLS"
echo "============================================================"
echo " "

check_cmd() {
    local label=$1
    local cmd=$2
    local flag=${3:---version}
    printf "  %-28s " "$label:"
    if command -v "$cmd" &>/dev/null; then
        echo "$($cmd $flag 2>&1 | head -1)"
    else
        echo "NOT FOUND"
    fi
}

check_path() {
    local label=$1
    local path=$2
    local flag=${3:---version}
    printf "  %-28s " "$label:"
    if [ -f "$path" ]; then
        echo "$($path $flag 2>&1 | head -1)"
    else
        echo "NOT FOUND at $path"
    fi
}

check_pymodule() {
    local label=$1
    local module=$2
    printf "  %-28s " "$label:"
    if "$HOME/robot-env/bin/python" -c "import $module" 2>/dev/null; then
        echo "OK (import $module)"
    else
        echo "NOT IMPORTABLE in robot-env"
    fi
}

echo "--- Core Tools ---"
check_cmd "curl"          curl
check_cmd "git"           git
check_cmd "ssh"           ssh    -V
check_cmd "wget"          wget
check_cmd "nmap"          nmap
check_cmd "minicom"       minicom
check_cmd "neofetch"      neofetch
check_cmd "htop"          htop
check_cmd "tree"          tree
check_cmd "ifconfig"      ifconfig

echo " "
echo "--- Python (system) ---"
check_cmd "python3"       python3
check_cmd "pip3"          pip3

echo " "
echo "--- Robot Python venv (~/robot-env) ---"
check_path "robot-env python"  "$HOME/robot-env/bin/python"
check_pymodule "pymycobot"    "pymycobot"
check_pymodule "pyserial"     "serial"
check_pymodule "numpy"        "numpy"

echo " "
echo "--- Hardware / GPIO / I2C ---"
printf "  %-28s " "i2cdetect:"
if command -v i2cdetect &>/dev/null; then
    echo "$(i2cdetect -V 2>&1 | head -1)"
else
    echo "NOT FOUND"
fi
check_cmd "esptool"       esptool

echo " "
echo "--- IDEs and Editors ---"
check_cmd "vim"           vim
check_cmd "nano"          nano
check_cmd "thonny"        thonny
check_cmd "code"          code
check_cmd "arduino"       arduino  --version 2>/dev/null || true

echo " "
echo "--- Browser ---"
printf "  %-28s " "chromium:"
if command -v chromium-browser &>/dev/null; then
    chromium-browser --version 2>/dev/null | head -1
elif command -v chromium &>/dev/null; then
    chromium --version 2>/dev/null | head -1
else
    echo "NOT FOUND"
fi

echo " "
echo "--- Docker ---"
check_cmd "docker"        docker
printf "  %-28s " "docker compose:"
docker compose version 2>/dev/null | head -1 || echo "NOT FOUND"

echo " "
echo "--- ROS 2 Humble ---"
printf "  %-28s " "ros2:"
if command -v ros2 &>/dev/null; then
    ros2 --version 2>/dev/null | head -1
else
    echo "NOT FOUND (source ~/.bashrc)"
fi
printf "  %-28s " "ROS_DISTRO:"
echo "${ROS_DISTRO:-not set}"
printf "  %-28s " "mycobot pkg:"
ros2 pkg list 2>/dev/null | grep mycobot | head -1 || echo "not found"
check_cmd "colcon"        colcon
check_cmd "rosdep"        rosdep

echo " "
echo "--- UART for myCobot ---"
printf "  %-28s " "/dev/ttyAMA0:"
ls -l /dev/ttyAMA0 2>/dev/null | awk '{print $1, $3, $4}' || echo "NOT FOUND (check after reboot)"
printf "  %-28s " "disable-bt in config.txt:"
grep -q "disable-bt" /boot/firmware/config.txt 2>/dev/null \
    && echo "PRESENT" || echo "NOT PRESENT"
printf "  %-28s " "enable_uart in config.txt:"
grep -q "enable_uart=1" /boot/firmware/config.txt 2>/dev/null \
    && echo "PRESENT" || echo "NOT PRESENT"
printf "  %-28s " "core_freq=250 in config.txt:"
grep -q "core_freq=250" /boot/firmware/config.txt 2>/dev/null \
    && echo "PRESENT" || echo "NOT PRESENT"
printf "  %-28s " "bluetooth service:"
BT_STATE=$(systemctl is-enabled bluetooth 2>/dev/null || echo "unknown")
echo "$BT_STATE (disabled=correct; masked=overly restrictive; can re-enable later)"
printf "  %-28s " "hciuart service:"
systemctl is-enabled hciuart 2>/dev/null || echo "disabled/not-found (expected)"

echo " "
echo "--- Services ---"
printf "  %-28s " "docker:"
systemctl is-active docker 2>/dev/null || echo "NOT RUNNING"
printf "  %-28s " "ssh:"
systemctl is-active ssh 2>/dev/null || echo "NOT RUNNING"
printf "  %-28s " "pigpiod:"
systemctl is-active pigpiod 2>/dev/null || echo "NOT RUNNING"

echo " "
echo "--- Git Config ---"
echo "  user.name  = $(git config --global user.name  2>/dev/null || echo 'not set')"
echo "  user.email = $(git config --global user.email 2>/dev/null || echo 'not set')"

echo " "
echo "--- Groups for $USER ---"
groups "$USER"

echo " "
echo "--- Disk Usage ---"
df -h / | tail -1 | awk '{print "  Root filesystem: " $3 " used of " $2 " (" $5 " full)"}'

echo " "
echo "--- ~/.bashrc sources (load order) ---"
grep -E "robot-env|humble|colcon_ws" "$HOME/.bashrc"

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
echo "  Done: Pi 4B Ubuntu 22.04 STEAM Clown Setup - Rev 0.01"
echo " "
echo "  Log file saved to: $LOG_FILE"
echo " "
echo "  REQUIRED MANUAL STEPS AFTER REBOOT:"
echo " "
echo "  1. LOG OUT AND BACK IN (or reboot)"
echo "     Groups (dialout, i2c, plugdev, docker) take effect"
echo "     robot-env venv auto-activates in new terminals"
echo " "
echo "  2. VERIFY UART FOR myCobot ARM:"
echo "     ls -l /dev/ttyAMA0"
echo "     Expected: crw-rw---- 1 root dialout ..."
echo "     PL011 -> robot arm @ 1,000,000 baud"
echo "     mini UART -> Bluetooth (stable via core_freq=250)"
echo "     Bluetooth NOT destroyed — re-enable anytime:"
echo "       sudo systemctl enable bluetooth && sudo reboot"
echo " "
echo "  3. TEST ROBOT CONNECTION (arm must be powered on):"
echo "     robot-test"
echo "     or: python ~/robot-labs/python-only/test_connection.py"
echo " "
echo "  4. TEST ROS 2:"
echo "     Terminal 1: ros2 run demo_nodes_cpp talker"
echo "     Terminal 2: ros2 run demo_nodes_py listener"
echo " "
echo "  5. THONNY - Point at robot venv:"
echo "     Tools > Options > Interpreter > Alternative Python 3"
echo "     Path: /home/$USER/robot-env/bin/python"
echo " "
echo "  6. ENABLE VNC REMOTE DESKTOP:"
echo "     Settings > Sharing > Remote Desktop > Toggle ON"
echo "     Set VNC password, connect: vnc://$(hostname -I | awk '{print $1}'):5900"
echo " "
echo "  7. ROS 2 myCobot QUICK START:"
echo "     ros2 launch mycobot_280pi slider_control.launch.py \\"
echo "       port:=/dev/ttyAMA0 baud:=1000000"
echo "============================================================"

# ============================================================================
# AUTO REBOOT
# ============================================================================
echo " "
echo "============================================================"
echo "  About to reboot in 15 seconds..."
echo "  Press Ctrl+C to cancel"
echo "============================================================"
sleep 15
sudo reboot
