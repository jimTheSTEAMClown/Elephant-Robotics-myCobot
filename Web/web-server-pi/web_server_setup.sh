#!/bin/bash
# =============================================================================
# apache_setup.sh
# Jim The STEAM Clown — Raspberry Pi Apache Web Server Setup Script
#
# Purpose:  Check for Apache2, run apt update, and install if needed.
#           Logs all actions and results to a timestamped log file.
#
# Usage:    sudo bash apache_setup.sh
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
LOG_DIR="/var/log/steam_clown"
LOG_FILE="${LOG_DIR}/apache_setup_$(date +%Y%m%d_%H%M%S).log"
APACHE_SERVICE="apache2"

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
# PREFLIGHT CHECK — must run as root
# -----------------------------------------------------------------------------
check_root() {
    log_section "Preflight: Checking for root / sudo privileges"
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo or as root."
        log_error "Usage: sudo bash apache_setup.sh"
        exit 1
    fi
    log_ok "Running as root — OK"
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
        log_warn "Apache2 is NOT installed — will proceed with installation"
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

    # Report local IP for browser test
    local ip_addr
    ip_addr=$(hostname -I | awk '{print $1}')
    log_info "To verify in a browser, navigate to: http://${ip_addr}"
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
    setup_log
    log_info "Starting Apache2 setup script on $(hostname)"
    log_info "Log file: ${LOG_FILE}"

    check_root
    check_apache_installed   # Step 1
    run_apt_update           # Step 2
    install_apache           # Step 3
    verify_installation      # Post-install checks
    wrap_up
}

main "$@"
