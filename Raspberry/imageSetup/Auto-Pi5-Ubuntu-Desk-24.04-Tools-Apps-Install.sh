#! /bin/bash
# ============================================================================
# Shell script to pull the bash shell scripts for Desktop on Raspberry Pi 5 Ubuntu 24.04
# ============================================================================
# Usage:
# sudo wget -O Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh https://raw.githubusercontent.com/jimTheSTEAMClown/Robots-Rovers-Project-Template/refs/heads/main/Raspberry/imageSetup/Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
# sudo chmod 755 Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
# ./Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
# ============================================================================
# Shell script to set up tools and apps on a Raspberry Pi 5 Ubuntu 24.04 image for STEAM robotics
# Source: STEAM Clown - www.steamclown.org
# GitHub: https://github.com/jimTheSTEAMClown/Linux
# Hacker: Jim Burnham - STEAM Clown, Engineer, Maker, Propmaster & Adrenologist
# This example code is licensed under the CC BY-NC-SA 4.0, GNU GPL and EUPL
# https://creativecommons.org/licenses/by-nc-sa/4.0/
# https://www.gnu.org/licenses/gpl-3.0.en.html
# https://eupl.eu/
#
# Program/Design Name:   Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
# Description:           Shell script to configure a fresh Ubuntu 24.04 install
#                        on a Raspberry Pi 5 for STEAM/Robotics/Mechatronics use.
#                        Installs dev tools, Python libraries, GPIO support,
#                        I2C/serial tools, Docker, nmap, Chromium, VS Code,
#                        Thonny, VNC, Arduino, PlatformIO, and more.
#                        All output is logged to ~/pi5-install-<timestamp>.log
#                        while also displaying in the terminal (tee).
#
# Target Hardware:       Raspberry Pi 5 (ARM64 / aarch64)
# Target OS:             Ubuntu 24.04.x LTS (64-bit)
#
# Dependencies:          Run as a normal user with sudo privileges
#                        Must have internet access
#
# Revision:
#  Revision 0.01 - Copied original script from rev 5 - Fixed xdg-desktop-portal deadlock on Pi 5 GNOME session:
#                  Replaced xdg-desktop-portal-gnome (deadlocks on Pi 5 ARM64)
#                  with xdg-desktop-portal-gtk (stable, no deadlock)
#                  Added portals.conf routing gtk for file chooser,
#                  gnome for screencast/screenshot (future-proof if gnome fixes)
#                  * Replaced all 'apt' with 'apt-get' (script-safe interface)
#                  * Removed pigpio (not in Ubuntu 24.04 repos); confirmed lgpio
#                    is installed via python3-gpiozero dependency; documented
#                    lgpio as the correct Pi 5 GPIO backend on Ubuntu 24.04
#                  * Fixed VS Code install: replaced unavailable ARM64 snap with
#                    Microsoft's official ARM64 .deb apt repository method
#                  * Fixed Arduino step: Arduino IDE 2.x has NO official ARM64
#                    Linux build. Now installs Arduino Legacy 1.8.x via apt
#                    (ARM64 native) as primary option, plus optional Flatpak
#                    path for Arduino IDE 2.x
#                  * Fixed libfuse2 package name to libfuse2t64 (Ubuntu 24.04)
#                  * Fixed verify block: i2cdetect uses -V not --version;
#                    removed pigpiod check; fixed docker compose check;
#                    fixed code check; improved pio check
#                  * Added apt-get autoremove after upgrade to clear orphans
#
# Steps:
#  STEP  1 - Update, Upgrade, and Autoremove
#  STEP  2 - Core System and Networking Tools
#  STEP  3 - Python Tools
#  STEP  4 - Hardware, GPIO, I2C, Serial, and ESP Tools (lgpio / gpiozero)
#  STEP  5 - Text Editors and IDEs (VS Code via Microsoft ARM64 .deb repo)
#  STEP  6 - Web Browser (Chromium ARM64)
#  STEP  7 - Docker and Docker Compose
#  STEP  8 - GNOME Desktop Tweaks + neofetch
#  STEP  9 - VNC Remote Desktop (gnome-remote-desktop)
#  STEP 10 - Arduino (Legacy 1.8.x ARM64 via apt + optional Flatpak 2.x)
#  STEP 11 - PlatformIO (VS Code extension + CLI + udev rules)
#  STEP 12 - Git Global Config (interactive name/email setup)
#  STEP 13 - Verify All Installs
#
# Usage:
#   chmod +x Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
#   ./Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install.sh
#
# References:
#   https://ubuntu.com/tutorials/how-to-install-ubuntu-on-raspberry-pi
#   https://gpiozero.readthedocs.io/en/stable/
#   https://docs.docker.com/engine/install/ubuntu/
#   https://code.visualstudio.com/docs/setup/linux
#   https://docs.platformio.org/en/latest/core/installation/index.html
#   https://tigervnc.org/
# ============================================================================

# ============================================================================
# LOGGING SETUP
# All output goes to terminal AND to a timestamped log file in home directory.
# Uses 'tee' so you see everything live in the terminal while it is captured.
# Log file:  ~/log-Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install-YYYYMMDD-HHMMSS.log
# ============================================================================
LOG_FILE="$HOME/log-Auto-Pi5-Ubuntu-Desk-24.04-Tools-Apps-Install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================================"
echo "  LOGGING ENABLED"
echo "  Log file: $LOG_FILE"
echo "  All terminal output is being saved to that file."
echo "============================================================"
echo " "

# ============================================================================
# PRE-FLIGHT BOOTSTRAP
# Install bare-minimum tools needed by this script BEFORE any prompted steps.
# These are not guaranteed on a brand new Ubuntu 24.04 Desktop image and are
# required for later steps to succeed.
#
# NOTE: Uses apt-get (not apt) throughout this script.
#   apt       = human-friendly interactive tool (produces noisy warnings in
#               scripts: "WARNING: apt does not have a stable CLI interface")
#   apt-get   = the correct scriptable interface; no warnings, stable output
#
#   curl             - Used in Steps 5, 7, 11 to download keys and installers
#   wget             - Used in Step 10 to download Arduino
#   gnupg            - Required for apt to verify GPG signing keys
#   lsb-release      - Used by Docker and VS Code repo setup for Ubuntu codename
#   ca-certificates  - Required for HTTPS apt repo connections
#   snapd            - Snap package manager; required for Chromium (Step 6)
#   xdg-desktop-portal-gtk  - Portal backend for file chooser, printing, etc.
#                            Replaces xdg-desktop-portal-gnome which deadlocks
#                            on Pi 5 ARM64 GNOME sessions causing terminals,
#                            Firefox, and Chromium to hang or never open.
#                            GTK backend is stable and covers all curriculum needs.
#                            A portals.conf is written after install to route
#                            file chooser calls to gtk and leave screencast/
#                            screenshot routed to gnome (for future compatibility).
#   flatpak          - Required for optional Arduino IDE 2.x Flatpak (Step 10)
# ============================================================================
echo " "
echo "============================================================"
echo "PRE-FLIGHT BOOTSTRAP"
echo "  Installing script dependencies on fresh Ubuntu 24.04..."
echo "  Using apt-get (script-safe interface, no apt warnings)"
echo "============================================================"
echo "STEP 1 - UPDATE, UPGRADE, AND AUTOREMOVE"
echo "  Running: sudo apt-get update"
echo "  Running: sudo apt-get upgrade -y"
echo "  Running: sudo apt-get autoremove -y"
echo "  Running: sudo apt-get autoclean"
echo "============================================================"
  sudo apt-get update         # sync package lists from repos
  sudo apt-get upgrade -y     # apply all available upgrades
  sudo apt-get autoremove -y  # drop orphaned dependencies left by upgrades
  sudo apt-get autoclean      # purge stale .deb cache files
  sudo apt-get update         # re-sync so next install has clean fresh index
sudo apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    snapd \
    flatpak \
    xdg-desktop-portal-gtk
echo "  Pre-flight bootstrap complete"
echo " "

# Write portals.conf to route file chooser to gtk backend
# This prevents the gnome portal deadlock on Pi 5 GNOME sessions while
# keeping gnome routed for screencast/screenshot for future compatibility
echo "----------------------------------------------------"
echo "  Writing ~/.config/xdg-desktop-portal/portals.conf"
echo "  Routes file chooser to gtk backend (avoids Pi 5 deadlock)"
echo "  Routes screencast/screenshot to gnome (future-proof)"
echo "----------------------------------------------------"
mkdir -p "$HOME/.config/xdg-desktop-portal"
cat > "$HOME/.config/xdg-desktop-portal/portals.conf" << 'PORTALEOF'
[preferred]
# xdg-desktop-portal-gnome deadlocks on Pi 5 Ubuntu 24.04 ARM64 GNOME sessions
# causing terminals, Firefox, and Chromium to hang. Route file chooser to gtk.
# If gnome backend is ever fixed in a future Ubuntu update, screencast and
# screenshot will automatically use it again via the gnome routing below.
default=gtk
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.Print=gtk

# Route screencast and screenshot to gnome for future compatibility
# (gnome backend handles these better when it is working correctly)
org.freedesktop.impl.portal.ScreenCast=gnome
org.freedesktop.impl.portal.Screenshot=gnome
PORTALEOF
echo "  portals.conf written to: $HOME/.config/xdg-desktop-portal/portals.conf"
echo " "

echo "  Waiting for snapd to be ready..."
sudo systemctl enable snapd
sudo systemctl start snapd
sudo snap wait system seed.loaded
echo "  snapd is ready"
echo " "

# ============================================================================
# ARCHITECTURE CHECK
# Confirms we are running on ARM64 (aarch64) as required for Pi 5.
# ============================================================================
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"
if [ "$ARCH" != "aarch64" ]; then
    echo "----------------------------------------------------"
    echo "WARNING: This script is designed for ARM64 (aarch64)"
    echo "You appear to be running on: $ARCH"
    echo "Some packages may not work correctly."
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
echo " "
echo "  Raspberry Pi 5 Ubuntu 24.04 - Adding Tools and Apps - STEAM Clown Setup Script"
echo "  Revision 0.05"
echo "  Target: Pi 5 / ARM64 / Ubuntu 24.04 LTS"
echo "  For: Fire Breathing Robots / Mechatronics Curriculum"
echo "  Log: $LOG_FILE"
echo "============================================================"
echo " "
pwd
ls
echo " "

# ============================================================================
# STEP 2 - CORE SYSTEM AND NETWORKING TOOLS
# Foundational tools used by virtually every other install step and for
# day-to-day SSH, file transfer, network diagnostics, and navigation.
#
#   curl           - Command-line URL tool; downloads files and calls APIs
#   git            - Version control; clones repos and manages curriculum files
#   openssh-server - Enables SSH access to the Pi from laptops/desktops
#   net-tools      - Provides 'ifconfig' for checking IP addresses
#   htop           - Interactive process/resource viewer; better than 'ps aux'
#   tree           - Displays directory structure as a visual tree
#   wget           - Downloads files from the web via command line
#   nmap           - Network scanner; finds Pi/Arduino/ESP IPs on local network
#                    Use: nmap -sn 192.168.1.0/24  to scan your subnet
#   minicom        - Serial terminal for debugging Arduino/ESP over USB UART
#                    Use: minicom -D /dev/ttyUSB0 -b 115200
#                    Exit: Ctrl+A then X
#   neofetch       - Prints system info banner (distro, CPU, RAM, etc.)
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 2 - CORE SYSTEM AND NETWORKING TOOLS"
echo "  Installing:"
echo "    - curl, git, openssh-server (+ ufw allow ssh)"
echo "    - net-tools (ifconfig), htop, tree, wget"
echo "    - nmap  (network scanner)"
echo "    - minicom (serial terminal for Arduino/ESP debugging)"
echo "    - neofetch (system info banner)"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing curl - command-line URL and download tool"
    echo "Running: sudo apt-get install curl -y"
    echo "----------------------------------------------------"
    sudo apt-get install curl -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing git - version control system"
    echo "Running: sudo apt-get install git -y"
    echo "----------------------------------------------------"
    sudo apt-get install git -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing openssh-server - enables SSH into this Pi"
    echo "Running: sudo apt-get install openssh-server -y"
    echo "----------------------------------------------------"
    sudo apt-get install openssh-server -y
    sudo ufw --force enable
    sudo ufw allow ssh
    echo "  ufw enabled and SSH firewall rule added"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing net-tools - provides ifconfig command"
    echo "Running: sudo apt-get install net-tools -y"
    echo "----------------------------------------------------"
    sudo apt-get install net-tools -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing htop - interactive process and resource viewer"
    echo "Running: sudo apt-get install htop -y"
    echo "----------------------------------------------------"
    sudo apt-get install htop -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing tree - visual directory structure display"
    echo "Running: sudo apt-get install tree -y"
    echo "----------------------------------------------------"
    sudo apt-get install tree -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing wget - command-line file downloader"
    echo "Running: sudo apt-get install wget -y"
    echo "----------------------------------------------------"
    sudo apt-get install wget -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing nmap - network scanner"
    echo "  Scan local network: nmap -sn 192.168.1.0/24"
    echo "  Find Pi/Arduino/ESP device IPs on the lab network"
    echo "Running: sudo apt-get install nmap -y"
    echo "----------------------------------------------------"
    sudo apt-get install nmap -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing minicom - serial terminal emulator"
    echo "  Debug Arduino/ESP serial output over USB"
    echo "  Usage: minicom -D /dev/ttyUSB0 -b 115200"
    echo "  Exit minicom: Ctrl+A then X"
    echo "Running: sudo apt-get install minicom -y"
    echo "----------------------------------------------------"
    sudo apt-get install minicom -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing neofetch - system info banner"
    echo "  Displays distro, CPU, RAM, and Pi 5 specs"
    echo "  Run: neofetch"
    echo "Running: sudo apt-get install neofetch -y"
    echo "----------------------------------------------------"
    sudo apt-get install neofetch -y

    echo " "
    echo "----------------------------------------------------"
    echo "Done: CORE SYSTEM AND NETWORKING TOOLS"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 3 - PYTHON TOOLS
# Python is the primary language for Pi robotics and student curriculum.
#
#   python3-pip    - Python package manager
#                    NOTE: Ubuntu 24.04 uses PEP 668 externally-managed env.
#                    Use '--break-system-packages' when running pip directly,
#                    or prefer apt-installed python3-* packages where available.
#   python3-venv   - Virtual environment support; best practice for pip installs
#   python3-dev    - Python C headers; required by some native pip packages
#   build-essential - gcc/g++/make; required for compiling native Python modules
#                     and by PlatformIO toolchain (installed in Step 11)
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 3 - PYTHON TOOLS"
echo "  Installing:"
echo "    - python3-pip    (pip package manager)"
echo "    - python3-venv   (virtual environment support)"
echo "    - python3-dev    (Python C headers for native packages)"
echo "    - build-essential (gcc/make toolchain)"
echo "  NOTE: Ubuntu 24.04 PEP 668 - prefer apt-get python3-* packages"
echo "        or use venv / '--break-system-packages' with pip"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing python3-pip - Python 3 package manager"
    echo "Running: sudo apt-get install python3-pip -y"
    echo "----------------------------------------------------"
    sudo apt-get install python3-pip -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing python3-venv - Python virtual environments"
    echo "Running: sudo apt-get install python3-venv -y"
    echo "----------------------------------------------------"
    sudo apt-get install python3-venv -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing python3-dev - Python C headers"
    echo "  Required by some pip packages that compile native code"
    echo "Running: sudo apt-get install python3-dev -y"
    echo "----------------------------------------------------"
    sudo apt-get install python3-dev -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing build-essential - gcc/g++/make toolchain"
    echo "  Required for compiling native Python modules"
    echo "  Also required by PlatformIO firmware toolchain (Step 11)"
    echo "Running: sudo apt-get install build-essential -y"
    echo "----------------------------------------------------"
    sudo apt-get install build-essential -y

    echo " "
    echo "----------------------------------------------------"
    echo "Done: PYTHON TOOLS"
    echo "----------------------------------------------------"
    python3 -V
    pip3 -V

# ============================================================================
# STEP 4 - HARDWARE, GPIO, I2C, SERIAL, AND ESP TOOLS
# Enables Python control of GPIO pins, I2C bus, SPI, UART, and ESP flashing.
#
# IMPORTANT NOTE ON GPIO LIBRARIES FOR UBUNTU 24.04 / PI 5:
#   pigpio was REMOVED from Ubuntu 24.04 apt repositories.
#   The correct replacement is lgpio, which is maintained by the same author
#   and fully supported on Pi 5 with Ubuntu 24.04.
#
#   python3-gpiozero  - High-level GPIO library; preferred for student code
#                       On Ubuntu 24.04 + Pi 5, gpiozero automatically uses
#                       lgpio as its backend (replaces pigpio backend)
#                       Simple safe API: LED("GPIO17"), Motor(4,14), etc.
#                       Docs: https://gpiozero.readthedocs.io
#   python3-lgpio     - Installed automatically as gpiozero dependency
#                       Low-level GPIO access; replaces pigpio on Ubuntu 24.04
#                       Docs: https://lg.nicholasjohnson.co.uk/lgpio/
#   liblgpio1         - Installed automatically as lgpio dependency
#   python3-serial    - PySerial; UART/serial comms with Arduino, GPS, BT, etc.
#                       Docs: https://pyserial.readthedocs.io
#   python3-smbus     - I2C bus access for sensors (IMU, OLED, ADC, etc.)
#   i2c-tools         - CLI I2C utilities: i2cdetect, i2cdump, i2cget, i2cset
#                       Use: i2cdetect -y 1  to scan for connected I2C devices
#   esptool           - Flashes firmware to ESP32/ESP8266 boards from Pi
#   cheese            - Webcam viewer; useful for rover camera testing
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 4 - HARDWARE, GPIO, I2C, SERIAL, AND ESP TOOLS"
echo "  Installing:"
echo "    - python3-gpiozero (high-level GPIO; lgpio backend on Ubuntu 24.04)"
echo "    - python3-lgpio + liblgpio1 (replaces pigpio on Ubuntu 24.04)"
echo "    - python3-serial (PySerial; UART/serial comms)"
echo "    - python3-smbus  (I2C sensor access)"
echo "    - i2c-tools      (i2cdetect and I2C CLI utilities)"
echo "    - esptool        (flash ESP32/ESP8266 from Pi)"
echo "    - cheese         (webcam viewer for rover cameras)"
echo "  NOTE: pigpio is NOT available on Ubuntu 24.04"
echo "        lgpio is the correct replacement and is ARM64 native"
echo "  Also: adds user to gpio, i2c, dialout, plugdev groups"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing python3-gpiozero"
    echo "  High-level GPIO library; great for student rover code"
    echo "  Example: from gpiozero import Motor, LED, Button"
    echo "  On Ubuntu 24.04 + Pi 5, uses lgpio backend automatically"
    echo "  Also installs python3-lgpio and liblgpio1 as dependencies"
    echo "  Docs: https://gpiozero.readthedocs.io"
    echo "Running: sudo apt-get install python3-gpiozero -y"
    echo "----------------------------------------------------"
    sudo apt-get install python3-gpiozero -y

    echo " "
    echo "----------------------------------------------------"
    echo "Explicitly installing python3-lgpio and liblgpio1"
    echo "  lgpio replaces pigpio on Ubuntu 24.04 (pigpio not available)"
    echo "  liblgpio1 is the C library underlying python3-lgpio"
    echo "  These are the Pi 5 GPIO daemon/PWM backend on Ubuntu 24.04"
    echo "  Docs: https://lg.nicholasjohnson.co.uk/lgpio/"
    echo "Running: sudo apt-get install python3-lgpio liblgpio1 -y"
    echo "----------------------------------------------------"
    sudo apt-get install python3-lgpio liblgpio1 -y

    echo " "
    echo "----------------------------------------------------"
    echo "Verifying lgpio is available to Python"
    echo "----------------------------------------------------"
    python3 -c "import lgpio; print('  lgpio import OK')" 2>/dev/null && \
        echo "  lgpio: WORKING" || \
        echo "  lgpio: import check failed - may need log out/in"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing python3-serial (PySerial)"
    echo "  UART/serial comms with Arduino, GPS, Bluetooth modules"
    echo "  Example: ser = serial.Serial('/dev/ttyUSB0', 115200)"
    echo "  Docs: https://pyserial.readthedocs.io"
    echo "Running: sudo apt-get install python3-serial -y"
    echo "----------------------------------------------------"
    sudo apt-get install python3-serial -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing python3-smbus - I2C bus access library"
    echo "  Communicates with I2C sensors: IMU, OLED display, ADC, etc."
    echo "Running: sudo apt-get install python3-smbus -y"
    echo "----------------------------------------------------"
    sudo apt-get install python3-smbus -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing i2c-tools - command-line I2C scan utilities"
    echo "  Scan I2C bus: i2cdetect -y 1"
    echo "  Read register: i2cget -y 1 0x68 0x00"
    echo "Running: sudo apt-get install i2c-tools -y"
    echo "----------------------------------------------------"
    sudo apt-get install i2c-tools -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing esptool - ESP32/ESP8266 firmware flash tool"
    echo "  Flash firmware: esptool.py --port /dev/ttyUSB0 write_flash ..."
    echo "  Check chip:     esptool.py --port /dev/ttyUSB0 flash_id"
    echo "  Docs: https://docs.espressif.com/projects/esptool"
    echo "Running: sudo apt-get install esptool -y"
    echo "----------------------------------------------------"
    sudo apt-get install esptool -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing cheese - webcam viewer"
    echo "  Test and view USB or CSI cameras attached to rover"
    echo "  Docs: https://wiki.gnome.org/Apps/Cheese"
    echo "Running: sudo apt-get install cheese -y"
    echo "----------------------------------------------------"
    sudo apt-get install cheese -y

    echo " "
    echo "----------------------------------------------------"
    echo "Adding $USER to hardware access groups"
    echo "  gpio    - GPIO pin access"
    echo "  i2c     - I2C bus access"
    echo "  dialout - serial/USB port write access for uploads"
    echo "  plugdev - USB device access"
    echo "  NOTE: Log out and back in for group changes to take effect"
    echo "----------------------------------------------------"
    # gpio group may not exist on Ubuntu 24.04 (uses udev rules instead)
    if getent group gpio > /dev/null 2>&1; then
        sudo usermod -aG gpio "$USER"
        echo "  Added $USER to gpio group"
    else
        echo "  gpio group does not exist on this system (normal on Ubuntu 24.04)"
        echo "  GPIO access is managed via udev rules instead"
    fi
    sudo usermod -aG i2c "$USER"
    sudo usermod -aG dialout "$USER"
    sudo usermod -aG plugdev "$USER"
    echo "  User $USER added to i2c, dialout, plugdev groups"

    echo " "
    echo "----------------------------------------------------"
    echo "Done: HARDWARE, GPIO, I2C, SERIAL, AND ESP TOOLS"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 5 - TEXT EDITORS AND IDEs
# A range of editors from beginner-friendly to professional.
#
#   vim      - Classic terminal text editor; essential for SSH config editing
#   thonny   - Beginner Python IDE with built-in debugger and variable
#              inspector; ideal for student first steps with Pi GPIO
#              Docs: https://thonny.org
#   code     - Visual Studio Code via Microsoft's official ARM64 .deb repo
#              The snap version of VS Code is amd64 ONLY and does NOT work
#              on Pi 5 ARM64. The Microsoft .deb repo provides native ARM64.
#              Docs: https://code.visualstudio.com/docs/setup/linux
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 5 - TEXT EDITORS AND IDEs"
echo "  Installing:"
echo "    - vim    (terminal text editor)"
echo "    - thonny (beginner Python IDE for students)"
echo "    - VS Code via Microsoft ARM64 .deb repository"
echo "  NOTE: VS Code snap is amd64 ONLY - does not work on Pi 5"
echo "        Using Microsoft's official ARM64 .deb package instead"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing vim - terminal-based text editor"
    echo "  Essential for editing config files over SSH"
    echo "Running: sudo apt-get install vim -y"
    echo "----------------------------------------------------"
    sudo apt-get install vim -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing Thonny - beginner Python IDE"
    echo "  Simple UI, built-in step debugger, variable inspector"
    echo "  Supports MicroPython for microcontrollers"
    echo "  Docs: https://thonny.org"
    echo "Running: sudo apt-get install thonny -y"
    echo "----------------------------------------------------"
    sudo apt-get install thonny -y

    echo " "
    echo "----------------------------------------------------"
    echo "Installing Visual Studio Code via Microsoft ARM64 .deb repo"
    echo "  VS Code snap is amd64 ONLY - fails on Pi 5 ARM64"
    echo "  Microsoft provides an official ARM64 .deb package"
    echo "  This adds Microsoft's apt repository and installs from it"
    echo "  Docs: https://code.visualstudio.com/docs/setup/linux"
    echo "----------------------------------------------------"

    echo "  Step 5a: Add Microsoft GPG key"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
        sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
    sudo chmod a+r /etc/apt/keyrings/microsoft.gpg
    echo "  Microsoft GPG key added"

    echo "  Step 5b: Add Microsoft VS Code ARM64 apt repository"
    echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    echo "  VS Code ARM64 repository added"

    echo "  Step 5c: Update apt and install VS Code"
    sudo apt-get update
    sudo apt-get install code -y

    echo " "
    echo "----------------------------------------------------"
    echo "Done: TEXT EDITORS AND IDEs"
    echo "----------------------------------------------------"
    code --version 2>/dev/null && echo "  VS Code installed successfully" || \
        echo "  VS Code: verify with 'code --version' after new terminal"

# ============================================================================
# STEP 6 - WEB BROWSER (CHROMIUM - ARM64)
# Google Chrome does NOT have an ARM64 Linux build.
# Chromium is the correct open-source ARM64 browser for Ubuntu on Pi 5.
# Ubuntu's chromium-browser package installs via snap automatically.
#
#   chromium-browser - Open-source Chromium browser; ARM64 native
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 6 - WEB BROWSER (CHROMIUM - ARM64)"
echo "  Installing:"
echo "    - chromium-browser (ARM64 native; installs via snap)"
echo "  NOTE: Google Chrome amd64 .deb will NOT install on Pi 5 ARM64"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing chromium-browser"
    echo "  ARM64 native open-source browser; Chrome equivalent for Pi"
    echo "  Ubuntu's chromium-browser package installs the snap version"
    echo "Running: sudo apt-get install chromium-browser -y"
    echo "----------------------------------------------------"
    sudo apt-get install chromium-browser -y

    echo " "
    echo "----------------------------------------------------"
    echo "Done: WEB BROWSER"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 7 - DOCKER AND DOCKER COMPOSE
# Docker runs containerized apps without affecting the base OS.
# The Ubuntu apt package 'docker.io' is outdated.
# This installs Docker CE from the official Docker apt repository.
#
#   docker-ce            - Docker Community Edition engine
#   docker-ce-cli        - Docker command-line interface
#   containerd.io        - Container runtime used by Docker
#   docker-buildx-plugin - Multi-platform image build support
#   docker-compose-plugin- 'docker compose' v2 command
#
# Reference: https://docs.docker.com/engine/install/ubuntu/
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 7 - DOCKER AND DOCKER COMPOSE"
echo "  Installing Docker CE from official Docker apt repository"
echo "  (NOT docker.io from Ubuntu repos - that version is outdated)"
echo "  Installing:"
echo "    - docker-ce + docker-ce-cli + containerd.io"
echo "    - docker-buildx-plugin"
echo "    - docker-compose-plugin (docker compose v2)"
echo "  Also: adds user to docker group"
echo "  Docs: https://docs.docker.com/engine/install/ubuntu/"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Removing any old/conflicting Docker packages"
    echo "----------------------------------------------------"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 \
                podman-docker containerd runc; do
        sudo apt-get remove "$pkg" -y 2>/dev/null || true
    done

    echo " "
    echo "----------------------------------------------------"
    echo "Adding Docker official GPG key"
    echo "----------------------------------------------------"
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo " "
    echo "----------------------------------------------------"
    echo "Adding Docker apt repository for ARM64"
    echo "----------------------------------------------------"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    echo " "
    echo "----------------------------------------------------"
    echo "Installing Docker CE and Docker Compose plugin"
    echo "Running: sudo apt-get install docker-ce docker-ce-cli"
    echo "         containerd.io docker-buildx-plugin docker-compose-plugin -y"
    echo "----------------------------------------------------"
    sudo apt-get install docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin -y

    echo " "
    echo "----------------------------------------------------"
    echo "Adding $USER to docker group"
    echo "  Allows running 'docker' commands without sudo"
    echo "  NOTE: Log out and back in for group change to take effect"
    echo "----------------------------------------------------"
    sudo usermod -aG docker "$USER"
    echo "  User $USER added to docker group"

    echo " "
    echo "----------------------------------------------------"
    echo "Enabling Docker service to start at boot"
    echo "----------------------------------------------------"
    sudo systemctl enable docker
    sudo systemctl start docker

    echo " "
    echo "----------------------------------------------------"
    echo "Verifying Docker install"
    echo "----------------------------------------------------"
    docker --version
    docker compose version

    echo " "
    echo "----------------------------------------------------"
    echo "Done: DOCKER AND DOCKER COMPOSE"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 8 - GNOME DESKTOP TWEAKS AND NEOFETCH
# Quality-of-life GNOME settings for a classroom or lab Pi.
# Prevents screen locking during student demos or long compiles.
# neofetch auto-runs at terminal open to show Pi 5 specs to students.
#
#   idle-delay   - Seconds before screensaver activates (0 = never)
#   lock-delay   - Seconds after screensaver before screen locks
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 8 - GNOME DESKTOP TWEAKS AND NEOFETCH"
echo "  Applying:"
echo "    - Extend idle/screensaver delay (classroom demo friendly)"
echo "    - Extend screen lock delay"
echo "    - Add neofetch to ~/.bashrc (auto-shows Pi 5 specs)"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Setting GNOME idle delay to 800 seconds (~13 min)"
    echo "Running: gsettings set org.gnome.desktop.session idle-delay 800"
    echo "----------------------------------------------------"
    gsettings set org.gnome.desktop.session idle-delay 800

    echo " "
    echo "----------------------------------------------------"
    echo "Setting GNOME screen lock delay to 900 seconds (15 min)"
    echo "Running: gsettings set org.gnome.desktop.screensaver lock-delay 900"
    echo "----------------------------------------------------"
    gsettings set org.gnome.desktop.screensaver lock-delay 900

    echo " "
    echo "----------------------------------------------------"
    echo "Adding neofetch to ~/.bashrc"
    echo "  Displays Pi 5 system specs each time a terminal opens"
    echo "  Remove later by deleting the neofetch line from ~/.bashrc"
    echo "----------------------------------------------------"
    if ! grep -q 'neofetch' "$HOME/.bashrc"; then
        echo '' >> "$HOME/.bashrc"
        echo '# Show system info on terminal open' >> "$HOME/.bashrc"
        echo 'neofetch' >> "$HOME/.bashrc"
        echo "  neofetch added to ~/.bashrc"
    else
        echo "  neofetch already in ~/.bashrc, skipping"
    fi

    echo " "
    echo "----------------------------------------------------"
    echo "Done: GNOME DESKTOP TWEAKS AND NEOFETCH"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 9 - VNC REMOTE DESKTOP
# Enables viewing and controlling the Pi desktop from Windows or Linux laptops.
#
# SERVER (on the Pi):
#   gnome-remote-desktop - Built-in Ubuntu 24.04 VNC/RDP server.
#                          Shows your actual logged-in GNOME desktop.
#                          Enable after install via:
#                          Settings > Sharing > Remote Desktop
#
# CLIENT (on your Windows/Linux laptop - install separately):
#   TigerVNC Viewer - Open-source VNC client. Download: https://tigervnc.org/
#   RealVNC Viewer  - Free (not open source). Download: https://www.realvnc.com/
#
# CONNECT: vnc://<pi-ip-address>:5900
#   Find Pi IP: ip addr | grep "inet " | grep -v 127.0.0.1
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 9 - VNC REMOTE DESKTOP"
echo "  Installing on Pi (server):"
echo "    - gnome-remote-desktop (built-in Ubuntu VNC/RDP server)"
echo " "
echo "  VNC CLIENT (install on your Windows/Linux laptop separately):"
echo "    - TigerVNC Viewer (open source): https://tigervnc.org/"
echo "    - RealVNC Viewer  (free):        https://www.realvnc.com/"
echo " "
echo "  After install: Settings > Sharing > Remote Desktop > Enable"
echo "  Connect from laptop: vnc://<pi-ip-address>:5900"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing gnome-remote-desktop"
    echo "  Enables VNC and RDP access to the Pi desktop"
    echo "  Shows the actual logged-in GNOME session to remote clients"
    echo "  xdg-desktop-portal-gtk installed in pre-flight bootstrap"
    echo "  (required for VNC sharing toggle to work in Settings)"
    echo "  Docs: https://ubuntu.com/tutorials/access-remote-desktop"
    echo "Running: sudo apt-get install gnome-remote-desktop -y"
    echo "----------------------------------------------------"
    sudo apt-get install gnome-remote-desktop -y

    echo " "
    echo "----------------------------------------------------"
    echo "Done: VNC REMOTE DESKTOP"
    echo " "
    echo "  IMPORTANT - Manual steps required after this script:"
    echo "  1. Open Settings > Sharing > Remote Desktop"
    echo "  2. Toggle 'Remote Desktop' ON"
    echo "  3. Toggle 'Remote Control' ON (allows mouse/keyboard)"
    echo "  4. Set a VNC password under Authentication"
    echo "  5. Note your Pi IP: ip addr | grep 'inet '"
    echo "  6. On your laptop, open TigerVNC or RealVNC Viewer"
    echo "     and connect to: <pi-ip-address>:5900"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 10 - ARDUINO
#
# IMPORTANT: Arduino IDE 2.x has NO official ARM64 Linux build.
# The Arduino IDE 2.x GitHub releases page only lists:
#   - Linux_64bit (x86_64 / amd64)
#   - macOS, Windows
# There is NO Linux_aarch64 AppImage in any release.
#
# OPTIONS FOR ARDUINO ON PI 5 ARM64:
#
# OPTION A - Arduino IDE Legacy 1.8.x via apt (RECOMMENDED)
#   Package: arduino
#   ARM64 native, installs cleanly via apt-get
#   Includes: IDE, Arduino CLI, boards manager, library manager
#   Suitable for: teaching students, uploading sketches, serial monitor
#   Note: This is the 1.8.x "legacy" IDE but fully functional on Pi 5
#
# OPTION B - Arduino IDE 2.x via Flatpak (OPTIONAL)
#   Flatpak provides a community-maintained Arduino IDE 2.x for ARM64
#   Requires: flatpak runtime (~500MB additional download)
#   More modern UI but heavier resource usage
#   Flatpak ID: cc.arduino.IDE2
#
# OPTION C - PlatformIO in VS Code (INSTALLED IN STEP 11)
#   The professional Arduino-compatible workflow on ARM64
#   Full C++ project support, library management, multiple boards
#   Already handles Arduino sketches natively
#
# References:
#   https://github.com/arduino/arduino-ide/releases (no ARM64 Linux builds)
#   https://flathub.org/apps/cc.arduino.IDE2
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 10 - ARDUINO"
echo " "
echo "  IMPORTANT: Arduino IDE 2.x has NO official ARM64 Linux build."
echo "  The official releases only include Linux_64bit (x86/amd64)."
echo " "
echo "  Available options on Pi 5 ARM64:"
echo "    A) Arduino IDE Legacy 1.8.x via apt (ARM64 native, recommended)"
echo "    B) Arduino IDE 2.x via Flatpak (community ARM64 build, heavier)"
echo "    C) Skip (use PlatformIO in VS Code from Step 11 instead)"
echo "============================================================"
echo "    Installing Option A) Arduino IDE Legacy 1.8.x via apt (ARM64 native, recommended)"
echo "============================================================"
    echo " "
    echo "----------------------------------------------------"
    echo "OPTION A: Installing Arduino IDE Legacy 1.8.x via apt"
    echo "  ARM64 native package from Ubuntu repos"
    echo "  Includes IDE, CLI, boards manager, library manager"
    echo "  Launch from terminal: arduino"
    echo "  Or find it in the Applications menu"
    echo "Running: sudo apt-get install arduino -y"
    echo "----------------------------------------------------"
    sudo apt-get install arduino -y

    echo " "
    echo "----------------------------------------------------"
    echo "Adding $USER to dialout group for Arduino USB upload"
    echo "  Required to write to /dev/ttyUSB0 or /dev/ttyACM0"
    echo "  NOTE: Log out and back in for group change to take effect"
    echo "----------------------------------------------------"
    sudo usermod -aG dialout "$USER"
    echo "  User $USER added to dialout group"

    echo " "
    echo "----------------------------------------------------"
    echo "Done: ARDUINO IDE LEGACY 1.8.x"
    echo "  Launch: arduino"
    echo "  Or: Applications menu > Programming > Arduino IDE"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 11 - PLATFORMIO (VS CODE EXTENSION + CLI)
# PlatformIO is a professional embedded development platform that extends
# VS Code for multi-file C++ rover and robotics projects.
# Supports Arduino-compatible boards and hundreds of others.
#
#   platformio.platformio-ide - VS Code extension; project wizard, board
#                               manager, serial monitor, and build toolbar
#   PlatformIO Core CLI       - 'pio' command for terminal build/upload
#                               Installs to ~/.platformio/penv/bin/pio
#   99-platformio-udev.rules  - udev rules for Arduino/ESP USB detection
#
# Reference: https://docs.platformio.org/en/latest/core/installation/index.html
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 11 - PLATFORMIO (VS Code Extension + CLI)"
echo "  Installing:"
echo "    - PlatformIO Core CLI via official installer"
echo "    - PlatformIO IDE extension into VS Code"
echo "    - PlatformIO udev rules for USB board detection"
echo "  Requires VS Code installed (Step 5)"
echo "  Docs: https://platformio.org"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing PlatformIO Core CLI via official installer"
    echo "  Downloads and installs 'pio' to ~/.platformio/penv/bin/"
    echo "  Docs: https://docs.platformio.org/en/latest/core/installation"
    echo "----------------------------------------------------"
    curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py \
        -o /tmp/get-platformio.py
    python3 /tmp/get-platformio.py
    rm /tmp/get-platformio.py

    echo " "
    echo "----------------------------------------------------"
    echo "Adding PlatformIO CLI to PATH in ~/.bashrc"
    echo "  Enables 'pio' command from any terminal session"
    echo "  PlatformIO installs to ~/.platformio/penv/bin/"
    echo "----------------------------------------------------"
    PIO_PATH='$HOME/.platformio/penv/bin'
    if ! grep -q 'platformio' "$HOME/.bashrc"; then
        echo '' >> "$HOME/.bashrc"
        echo '# PlatformIO CLI' >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:$PIO_PATH\"" >> "$HOME/.bashrc"
        echo "  PATH entry added to ~/.bashrc"
    else
        echo "  PlatformIO PATH entry already in ~/.bashrc, skipping"
    fi
    export PATH="$PATH:$HOME/.platformio/penv/bin"

    echo " "
    echo "----------------------------------------------------"
    echo "Installing PlatformIO IDE extension into VS Code"
    echo "  Provides: project wizard, board manager, serial monitor"
    echo "  Requires VS Code (code) to be installed and in PATH"
    echo "Running: code --install-extension platformio.platformio-ide"
    echo "----------------------------------------------------"
    if command -v code &>/dev/null; then
        code --install-extension platformio.platformio-ide
        echo "  PlatformIO IDE extension installed"
    else
        echo "  WARNING: 'code' not found in PATH"
        echo "  VS Code may not have installed correctly in Step 5"
        echo "  After fixing VS Code, run manually:"
        echo "    code --install-extension platformio.platformio-ide"
    fi

    echo " "
    echo "----------------------------------------------------"
    echo "Installing PlatformIO udev rules"
    echo "  Allows Pi to detect Arduino/ESP boards over USB"
    echo "  without needing sudo for uploads"
    echo "  Rule: /etc/udev/rules.d/99-platformio-udev.rules"
    echo "----------------------------------------------------"
    curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules \
        | sudo tee /etc/udev/rules.d/99-platformio-udev.rules > /dev/null
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "  udev rules installed and reloaded"

    echo " "
    echo "----------------------------------------------------"
    echo "Verifying PlatformIO CLI"
    echo "----------------------------------------------------"
    if command -v pio &>/dev/null; then
        echo "  pio: $(pio --version)"
    elif [ -f "$HOME/.platformio/penv/bin/pio" ]; then
        echo "  pio: $($HOME/.platformio/penv/bin/pio --version)"
        echo "  (pio in PATH after new terminal session)"
    else
        echo "  pio: NOT FOUND - open a new terminal and run: pio --version"
    fi

    echo " "
    echo "----------------------------------------------------"
    echo "Done: PLATFORMIO"
    echo " "
    echo "  NEXT STEPS for PlatformIO:"
    echo "  1. Log out and back in (PATH change takes effect)"
    echo "  2. Open VS Code -> click the PlatformIO alien-head icon"
    echo "  3. New Project -> search your board:"
    echo "       'Arduino UNO R4 WiFi' or 'Arduino Mega 2560'"
    echo "  4. PlatformIO downloads the toolchain automatically on first build"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 12 - GIT GLOBAL CONFIG
# Sets the global git user name and email used for all commits on this Pi.
# These appear in every git commit log and are required before committing.
# Stored in ~/.gitconfig
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 12 - GIT GLOBAL CONFIG"
echo "  Configures git global user name, email, and default editor"
echo "  Stored in: ~/.gitconfig"
echo "============================================================"

    echo " "
    echo "----------------------------------------------------"
    read -p "Git user name (e.g. Jim Burnham): " GIT_NAME
    read -p "Git email (e.g. jburnham@metroed.net): " GIT_EMAIL
    echo "----------------------------------------------------"

    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global core.editor "code --wait"
    git config --global init.defaultBranch main

    echo " "
    echo "  Git global config set:"
    echo "    user.name         = $GIT_NAME"
    echo "    user.email        = $GIT_EMAIL"
    echo "    core.editor       = code --wait"
    echo "    init.defaultBranch = main"
    echo " "
    echo "  Stored in: ~/.gitconfig"
    echo "  View anytime with: git config --list --global"

    echo " "
    echo "----------------------------------------------------"
    echo "Done: GIT GLOBAL CONFIG"
    echo "----------------------------------------------------"

# ============================================================================
# STEP 13 - VERIFY ALL INSTALLS
# Quick check on all installed tools.
# Flags anything NOT FOUND so you know what to investigate.
#
# NOTES ON VERIFY FLAGS:
#   i2cdetect   - uses '-V' flag (uppercase), NOT '--version'
#   pigpiod     - REMOVED: not available on Ubuntu 24.04; lgpio is replacement
#   docker compose - called as 'docker compose version' (v2 plugin syntax)
#   pio         - may not be in PATH until new terminal; checks direct path too
#   code        - installed via .deb, should be in /usr/bin/code
# ============================================================================
echo " "
echo "============================================================"
echo "STEP 13 - VERIFY ALL INSTALLS"
echo "============================================================"
echo " "

# Helper: check if a command exists and print version
check_cmd() {
    local label=$1
    local cmd=$2
    local flag=${3:---version}
    printf "  %-24s " "$label:"
    if command -v "$cmd" &>/dev/null; then
        echo "$($cmd $flag 2>&1 | head -1)"
    else
        echo "NOT FOUND"
    fi
}

# Helper: check if a binary exists at a specific path
check_path() {
    local label=$1
    local path=$2
    local flag=${3:---version}
    printf "  %-24s " "$label:"
    if [ -f "$path" ]; then
        echo "$($path $flag 2>&1 | head -1)"
    else
        echo "NOT FOUND at $path"
    fi
}

# Helper: check Python module import
check_pymodule() {
    local label=$1
    local module=$2
    printf "  %-24s " "$label:"
    if python3 -c "import $module" 2>/dev/null; then
        echo "OK (import $module)"
    else
        echo "NOT IMPORTABLE"
    fi
}

echo "--- Core Tools ---"
check_cmd "curl"       curl
check_cmd "git"        git
check_cmd "ssh"        ssh        -V
check_cmd "wget"       wget
check_cmd "nmap"       nmap
check_cmd "minicom"    minicom
check_cmd "neofetch"   neofetch
check_cmd "htop"       htop
check_cmd "tree"       tree
check_cmd "ifconfig"   ifconfig
check_cmd "snap"       snap

echo " "
echo "--- Python ---"
check_cmd "python3"    python3
check_cmd "pip3"       pip3

echo " "
echo "--- Hardware / GPIO / I2C ---"
# i2cdetect uses -V (uppercase) not --version
printf "  %-24s " "i2cdetect:"
if command -v i2cdetect &>/dev/null; then
    echo "$(i2cdetect -V 2>&1 | head -1)"
else
    echo "NOT FOUND"
fi
check_cmd "esptool"    esptool
check_pymodule "python lgpio"     lgpio
check_pymodule "python gpiozero"  gpiozero
check_pymodule "python serial"    serial
check_pymodule "python smbus"     smbus

echo " "
echo "--- IDEs and Editors ---"
check_cmd "vim"        vim
check_cmd "thonny"     thonny
check_cmd "code"       code
check_cmd "arduino"    arduino    --version 2>/dev/null || true

echo " "
echo "--- Browser ---"
printf "  %-24s " "chromium:"
if command -v chromium-browser &>/dev/null; then
    chromium-browser --version 2>/dev/null | head -1
elif command -v chromium &>/dev/null; then
    chromium --version 2>/dev/null | head -1
else
    echo "NOT FOUND"
fi

echo " "
echo "--- Docker ---"
check_cmd "docker"     docker
# docker compose v2 is a plugin, called as 'docker compose'
printf "  %-24s " "docker compose:"
if docker compose version &>/dev/null 2>&1; then
    docker compose version 2>&1 | head -1
else
    echo "NOT FOUND"
fi

echo " "
echo "--- PlatformIO ---"
# pio may not be in PATH yet this session; check direct path too
printf "  %-24s " "pio:"
if command -v pio &>/dev/null; then
    echo "$(pio --version 2>&1 | head -1)"
elif [ -f "$HOME/.platformio/penv/bin/pio" ]; then
    echo "$($HOME/.platformio/penv/bin/pio --version 2>&1 | head -1) (needs new terminal for PATH)"
else
    echo "NOT FOUND"
fi

echo " "
echo "--- Services ---"
printf "  %-24s " "docker service:"
sudo systemctl is-active docker 2>/dev/null || echo "NOT RUNNING"

printf "  %-24s " "ssh service:"
sudo systemctl is-active ssh 2>/dev/null || echo "NOT RUNNING"

echo " "
echo "--- Git Config ---"
echo "  user.name  = $(git config --global user.name  2>/dev/null || echo 'not set')"
echo "  user.email = $(git config --global user.email 2>/dev/null || echo 'not set')"

echo " "
echo "--- Groups for $USER ---"
groups "$USER"

echo " "
echo "--- Disk Usage Summary ---"
df -h / | tail -1 | awk '{print "  Root filesystem: " $3 " used of " $2 " (" $5 " full)"}'

echo "  Running: sudo apt-get update"
echo "  Running: sudo apt-get upgrade -y"
echo "  Running: sudo apt-get autoremove -y"
echo "  Running: sudo apt-get autoclean"
echo "============================================================"
  sudo apt-get update         # sync package lists from repos
  sudo apt-get upgrade -y     # apply all available upgrades
  sudo apt-get autoremove -y  # drop orphaned dependencies left by upgrades
  sudo apt-get autoclean      # purge stale .deb cache files
  sudo apt-get update         # re-sync so next install has clean fresh index

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

    echo " "
    echo "----------------------------------------------------"
    echo "Done: fixing Gnome"
    echo "----------------------------------------------------"


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
echo "  Done: Pi 5 Ubuntu 24.04 STEAM Clown Setup - Rev 0.05"
echo " "
echo "  Log file saved to:"
echo "  $LOG_FILE"
echo " "
echo "  REQUIRED MANUAL STEPS AFTER REBOOT:"
echo "  1. LOG OUT AND BACK IN"
echo "     (i2c, dialout, plugdev, docker group changes take effect)"
echo "     (PlatformIO pio PATH takes effect)"
echo " "
echo "  2. ENABLE VNC REMOTE DESKTOP"
echo "     Settings > Sharing > Remote Desktop > Toggle ON"
echo "     Set a VNC password, note your Pi IP: ip addr"
echo "     Connect with TigerVNC or RealVNC Viewer"
echo "     TigerVNC: https://tigervnc.org/"
echo " "
echo "  3. ARDUINO"
echo "     Legacy 1.8.x: launch 'arduino' from terminal or Apps menu"
echo "     Flatpak 2.x:  flatpak run cc.arduino.IDE2"
echo "     PlatformIO:   Open VS Code > click alien-head icon"
echo " "
echo "  4. PLATFORMIO FIRST USE"
echo "     Open VS Code > PlatformIO alien-head icon > New Project"
echo "     Toolchain downloads automatically on first board selection"
echo " "
echo "  5. ROS2 JAZZY (install separately if needed)"
echo "     https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html"
echo " "
echo "  OPTIONAL CLEANUP:"
echo "     sudo apt-get autoremove -y   (remove any remaining orphaned packages)"
echo "============================================================"

# ============================================================================
# STEP 15 - Auto reboot/restart
# ============================================================================
echo "============================================================"
echo "  About to restart"
echo "============================================================"
    echo "Rebooting in 15 seconds to reset xdg-desktop-portal..."
    echo "Press Ctrl+C to cancel"
    sleep 15
    sudo reboot
