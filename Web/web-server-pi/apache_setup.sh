#!/bin/bash
# =============================================================================
# apache_setup.sh
# Jim The STEAM Clown — Raspberry Pi Apache Web Server Setup Script
#
# Purpose:  Check for Apache2, run apt update, and install if needed.
#           Logs all actions and results to a timestamped log file.
#
# Usage:    sudo bash apache_setup.sh        (interactive — prompts before install)
#           sudo bash apache_setup.sh -y     (auto-yes — installs without prompting)
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
LOG_DIR="/var/log/steam_clown"
LOG_FILE="${LOG_DIR}/apache_setup_$(date +%Y%m%d_%H%M%S).log"
APACHE_SERVICE="apache2"
AUTO_YES=false          # set to true if -y flag is passed

# -----------------------------------------------------------------------------
# COLOR CODES (terminal output only — not written to log)
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# -----------------------------------------------------------------------------
# LOGGING FUNCTIONS
# -----------------------------------------------------------------------------

# Create log directory if it doesn't exist
setup_log() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    echo "============================================================" >> "${LOG_FILE}"
    echo "  Apache Setup Script — $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
    echo "  Host: $(hostname)  |  User: $(whoami)" >> "${LOG_FILE}"
    echo "============================================================" >> "${LOG_FILE}"
}

# log_info: general info — goes to log + terminal (cyan)
log_info() {
    local msg="[INFO]  $(date '+%Y-%m-%d %H:%M:%S') — $*"
    echo "${msg}" >> "${LOG_FILE}"
    echo -e "${CYAN}${msg}${RESET}"
}

# log_ok: success — goes to log + terminal (green)
log_ok() {
    local msg="[OK]    $(date '+%Y-%m-%d %H:%M:%S') — $*"
    echo "${msg}" >> "${LOG_FILE}"
    echo -e "${GREEN}${msg}${RESET}"
}

# log_warn: warning — goes to log + terminal (yellow)
log_warn() {
    local msg="[WARN]  $(date '+%Y-%m-%d %H:%M:%S') — $*"
    echo "${msg}" >> "${LOG_FILE}"
    echo -e "${YELLOW}${msg}${RESET}"
}

# log_error: error — goes to log + terminal (red)
log_error() {
    local msg="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') — $*"
    echo "${msg}" >> "${LOG_FILE}"
    echo -e "${RED}${msg}${RESET}"
}

# log_section: visual divider for readability
log_section() {
    local divider="------------------------------------------------------------"
    echo "${divider}" >> "${LOG_FILE}"
    echo "  STEP: $*" >> "${LOG_FILE}"
    echo "${divider}" >> "${LOG_FILE}"
    echo -e "${BOLD}${divider}${RESET}"
    echo -e "${BOLD}  STEP: $*${RESET}"
    echo -e "${BOLD}${divider}${RESET}"
}

# run_cmd: run a command, log full output, return exit code
run_cmd() {
    local cmd="$*"
    log_info "Running: ${cmd}"
    echo "--- Command output begin ---" >> "${LOG_FILE}"
    # Run command; tee stdout/stderr to log
    eval "${cmd}" 2>&1 | tee -a "${LOG_FILE}"
    local exit_code=${PIPESTATUS[0]}
    echo "--- Command output end (exit code: ${exit_code}) ---" >> "${LOG_FILE}"
    return ${exit_code}
}

# -----------------------------------------------------------------------------
# EARLY SUDO CHECK — runs before log setup (can't write to /var/log without root)
# -----------------------------------------------------------------------------
early_check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo ""
        echo -e "${RED}[ERROR] This script must be run with sudo.${RESET}"
        echo ""
        echo -e "  Usage:  ${BOLD}sudo bash apache_setup.sh${RESET}"
        echo -e "  Or:     ${BOLD}sudo bash apache_setup.sh -y${RESET}   (skip install prompt)"
        echo ""
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# ARGUMENT PARSING — check for -y flag
# -----------------------------------------------------------------------------
parse_args() {
    for arg in "$@"; do
        case "${arg}" in
            -y|--yes)
                AUTO_YES=true
                ;;
            -h|--help)
                echo ""
                echo "Usage: sudo bash apache_setup.sh [OPTIONS]"
                echo ""
                echo "  (no flag)   Check for Apache2; prompt before installing if missing"
                echo "  -y          Auto-yes: install without prompting"
                echo "  -h          Show this help message"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${YELLOW}[WARN] Unknown argument: ${arg} — ignoring${RESET}"
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# PREFLIGHT — log sudo confirmation after log is open
# -----------------------------------------------------------------------------
check_root() {
    log_section "Preflight: Sudo / Root Privileges"
    log_ok "Running as root (UID 0) — OK"
    if [[ "${AUTO_YES}" == true ]]; then
        log_info "Mode: AUTO-YES (-y flag set — will install without prompting)"
    else
        log_info "Mode: INTERACTIVE (will prompt before installing)"
    fi
}

# -----------------------------------------------------------------------------
# STEP 1 — Check if Apache is already installed
# -----------------------------------------------------------------------------
check_apache_installed() {
    log_section "Step 1: Check if Apache2 is installed"

    # Check with dpkg (package database)
    if dpkg -s "${APACHE_SERVICE}" &>/dev/null; then
        local installed_version
        installed_version=$(dpkg -s "${APACHE_SERVICE}" | grep '^Version:' | awk '{print $2}')
        log_ok "Apache2 is already installed — version: ${installed_version}"

        # Also verify the binary exists
        if command -v apache2 &>/dev/null; then
            log_ok "Apache2 binary found at: $(command -v apache2)"
        else
            log_warn "Apache2 package is installed but binary not found in PATH — may need reinstall"
        fi

        # Check service status
        log_info "Checking Apache2 service status..."
        if systemctl is-active --quiet "${APACHE_SERVICE}"; then
            log_ok "Apache2 service is RUNNING"
        else
            log_warn "Apache2 service is NOT running (status: $(systemctl is-active ${APACHE_SERVICE}))"
            log_info "Tip: start it with: sudo systemctl start apache2"
        fi

        APACHE_WAS_INSTALLED=true
    else
        log_warn "Apache2 is NOT installed"
        APACHE_WAS_INSTALLED=false
    fi
}

# -----------------------------------------------------------------------------
# STEP 2 — Run apt update
# -----------------------------------------------------------------------------
run_apt_update() {
    log_section "Step 2: Running sudo apt update"
    log_info "Refreshing package lists from repositories..."

    run_cmd "apt update"
    local exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "apt update completed successfully"
    else
        log_error "apt update failed (exit code: ${exit_code})"
        log_error "Check your network connection and /etc/apt/sources.list"
        exit ${exit_code}
    fi
}

# -----------------------------------------------------------------------------
# STEP 3 — Install Apache2 if not already installed
# -----------------------------------------------------------------------------
install_apache() {
    log_section "Step 3: Install Apache2 (if needed)"

    if [[ "${APACHE_WAS_INSTALLED}" == true ]]; then
        log_info "Apache2 was already installed — skipping installation"
        log_info "To upgrade if a newer version is available, run:"
        log_info "  sudo apt install --only-upgrade apache2"
        return 0
    fi

    # ---- Determine whether to prompt or auto-proceed ----
    if [[ "${AUTO_YES}" == true ]]; then
        log_info "AUTO-YES mode: proceeding with installation automatically"
    else
        echo ""
        echo -e "${YELLOW}Apache2 is not installed on this system.${RESET}"
        echo -e "Would you like to install it now? ${BOLD}(y/n)${RESET}"
        echo -n "  > "
        read -r user_response

        case "${user_response}" in
            [yY]|[yY][eE][sS])
                log_info "User confirmed: proceeding with installation"
                ;;
            [nN]|[nN][oO])
                log_warn "User declined installation — exiting without installing Apache2"
                log_warn "To install later, run:  sudo bash apache_setup.sh"
                wrap_up
                exit 0
                ;;
            *)
                log_warn "Unrecognized response: '${user_response}' — treating as NO, exiting"
                wrap_up
                exit 0
                ;;
        esac
    fi

    log_info "Installing apache2..."
    run_cmd "apt install apache2 -y"
    local exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "Apache2 installed successfully"
    else
        log_error "Apache2 installation failed (exit code: ${exit_code})"
        exit ${exit_code}
    fi
}

# -----------------------------------------------------------------------------
# POST-INSTALL VERIFICATION
# -----------------------------------------------------------------------------
verify_installation() {
    log_section "Post-Install Verification"

    # Confirm package is registered
    if dpkg -s "${APACHE_SERVICE}" &>/dev/null; then
        local installed_version
        installed_version=$(dpkg -s "${APACHE_SERVICE}" | grep '^Version:' | awk '{print $2}')
        log_ok "Package verified via dpkg — version: ${installed_version}"
    else
        log_error "dpkg does not show apache2 as installed — something went wrong"
        exit 1
    fi

    # Confirm binary
    if command -v apache2 &>/dev/null; then
        log_ok "apache2 binary found: $(command -v apache2)"
    else
        log_warn "apache2 binary not found in PATH"
    fi

    # Confirm service is enabled and running
    if systemctl is-enabled --quiet "${APACHE_SERVICE}" 2>/dev/null; then
        log_ok "Apache2 service is ENABLED (will start on boot)"
    else
        log_warn "Apache2 service is NOT enabled — enabling now..."
        run_cmd "systemctl enable apache2"
    fi

    if systemctl is-active --quiet "${APACHE_SERVICE}"; then
        log_ok "Apache2 service is RUNNING"
    else
        log_warn "Apache2 service is not running — starting now..."
        run_cmd "systemctl start apache2"
        if systemctl is-active --quiet "${APACHE_SERVICE}"; then
            log_ok "Apache2 service started successfully"
        else
            log_error "Failed to start Apache2 service"
            log_info "Check: sudo systemctl status apache2"
        fi
    fi

}

# -----------------------------------------------------------------------------
# SYSTEM & NETWORK REPORT
# Logged at the end of the script — gives a full snapshot of the Pi's state
# -----------------------------------------------------------------------------
system_report() {
    log_section "System & Network Report"

    # ---- Hostname ----
    log_info "Hostname:       $(hostname)"
    log_info "FQDN:           $(hostname -f 2>/dev/null || echo 'n/a')"

    # ---- OS & Kernel ----
    local os_desc
    os_desc=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
    log_info "OS:             ${os_desc:-unknown}"
    log_info "Kernel:         $(uname -r)"
    log_info "Architecture:   $(uname -m)"

    # ---- Raspberry Pi model (if available) ----
    if [[ -f /proc/device-tree/model ]]; then
        local pi_model
        pi_model=$(tr -d '\0' < /proc/device-tree/model)
        log_info "Pi Model:       ${pi_model}"
    fi

    # ---- Uptime ----
    log_info "Uptime:         $(uptime -p 2>/dev/null || uptime)"

    # ---- Network interfaces — IP addresses & MAC addresses ----
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo "  NETWORK INTERFACES" >> "${LOG_FILE}"
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"
    echo -e "${BOLD}  NETWORK INTERFACES${RESET}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"

    # Loop over every active interface (skip loopback 'lo')
    local interfaces
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$')

    for iface in ${interfaces}; do
        # MAC address
        local mac
        mac=$(ip link show "${iface}" | awk '/ether/ {print $2}')

        # IPv4 address(es)
        local ipv4
        ipv4=$(ip -4 addr show "${iface}" 2>/dev/null \
               | awk '/inet / {print $2}' \
               | tr '\n' '  ' \
               | sed 's/  *$//')

        # IPv6 address(es) — skip link-local fe80 to keep output clean
        local ipv6
        ipv6=$(ip -6 addr show "${iface}" 2>/dev/null \
               | awk '/inet6/ && !/fe80/ {print $2}' \
               | tr '\n' '  ' \
               | sed 's/  *$//')

        log_info "Interface:      ${iface}"
        log_info "  MAC Address:  ${mac:-n/a}"
        log_info "  IPv4:         ${ipv4:-not assigned}"
        log_info "  IPv6:         ${ipv6:-not assigned}"
    done

    # ---- Open / listening ports (focus on web-relevant ones) ----
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo "  LISTENING PORTS" >> "${LOG_FILE}"
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"
    echo -e "${BOLD}  LISTENING PORTS${RESET}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"

    # ss is available on all modern Pi OS; falls back to netstat if missing
    if command -v ss &>/dev/null; then
        local port_list
        port_list=$(ss -tlnp 2>/dev/null | awk 'NR>1 {print "  " $4 "\t" $1 "\t" $6}')
        log_info "Listening TCP ports (via ss):"
        echo "${port_list}" | tee -a "${LOG_FILE}"
    elif command -v netstat &>/dev/null; then
        local port_list
        port_list=$(netstat -tlnp 2>/dev/null | awk 'NR>2 {print "  " $4 "\t" $1 "\t" $7}')
        log_info "Listening TCP ports (via netstat):"
        echo "${port_list}" | tee -a "${LOG_FILE}"
    else
        log_warn "Neither ss nor netstat found — skipping port listing"
    fi

    # Explicit check for ports 80 and 443
    for port in 80 443; do
        if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
            log_ok "Port ${port} is OPEN and listening"
        else
            log_warn "Port ${port} is NOT listening"
        fi
    done

    # ---- Apache version ----
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo "  APACHE INFO" >> "${LOG_FILE}"
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"
    echo -e "${BOLD}  APACHE INFO${RESET}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"

    if command -v apache2 &>/dev/null; then
        local apache_ver
        apache_ver=$(apache2 -v 2>/dev/null | head -1)
        log_info "Apache version: ${apache_ver}"

        # Config syntax test
        log_info "Running Apache config test (apache2ctl configtest)..."
        local config_result
        config_result=$(apache2ctl configtest 2>&1)
        if echo "${config_result}" | grep -q "Syntax OK"; then
            log_ok "Apache config syntax: OK"
        else
            log_warn "Apache config test output:"
            echo "${config_result}" | tee -a "${LOG_FILE}"
        fi
    else
        log_warn "apache2 binary not found — skipping version and config check"
    fi

    # ---- Disk space ----
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo "  DISK SPACE" >> "${LOG_FILE}"
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"
    echo -e "${BOLD}  DISK SPACE${RESET}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"

    log_info "Disk usage (df -h):"
    df -h --output=source,fstype,size,used,avail,pcent,target \
        2>/dev/null | grep -v tmpfs | grep -v devtmpfs \
        | tee -a "${LOG_FILE}"

    # Warn if root partition is over 85% full
    local root_usage
    root_usage=$(df / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    if [[ "${root_usage}" -ge 85 ]]; then
        log_warn "Root partition is ${root_usage}% full — consider cleaning up"
    else
        log_ok "Root partition disk usage: ${root_usage}% — OK"
    fi

    # ---- Memory / RAM ----
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo "  MEMORY" >> "${LOG_FILE}"
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"
    echo -e "${BOLD}  MEMORY${RESET}"
    echo -e "${BOLD}------------------------------------------------------------${RESET}"

    log_info "Memory usage (free -h):"
    free -h | tee -a "${LOG_FILE}"

    # Warn if less than 100MB free
    local free_mb
    free_mb=$(free -m | awk '/^Mem:/ {print $7}')
    if [[ "${free_mb}" -lt 100 ]]; then
        log_warn "Available RAM is low: ${free_mb}MB free"
    else
        log_ok "Available RAM: ${free_mb}MB free — OK"
    fi

    # ---- Browser test reminder ----
    echo "------------------------------------------------------------" >> "${LOG_FILE}"
    local primary_ip
    primary_ip=$(hostname -I | awk '{print $1}')
    log_info "Browser test URL: http://${primary_ip}"
    log_info "You should see the Apache2 default 'It works!' page"
}

# -----------------------------------------------------------------------------
# WRAP-UP — print log file location
# -----------------------------------------------------------------------------
wrap_up() {
    log_section "Script Complete"
    log_ok "All steps finished. Full log written to:"
    log_ok "  ${LOG_FILE}"
    echo "" >> "${LOG_FILE}"
    echo "============================================================" >> "${LOG_FILE}"
    echo "  Script ended — $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
    echo "============================================================" >> "${LOG_FILE}"
}

# =============================================================================
# MAIN — execute steps in order
# =============================================================================
main() {
    # Must check sudo BEFORE setup_log — can't write to /var/log/ without root
    early_check_root
    parse_args "$@"

    setup_log
    log_info "Starting Apache2 setup script on $(hostname)"
    log_info "Log file: ${LOG_FILE}"

    check_root
    check_apache_installed   # Step 1
    run_apt_update           # Step 2
    install_apache           # Step 3
    verify_installation      # Post-install checks
    system_report            # Network & system snapshot
    wrap_up
}

main "$@"
