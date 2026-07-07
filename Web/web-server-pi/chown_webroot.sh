#!/bin/bash
# =============================================================================
# chown_webroot.sh
# Jim The STEAM Clown — Raspberry Pi Web Root Ownership Script
#
# Purpose:  Transfer ownership of /var/www/html (and all contents) to the
#           user who invoked this script with sudo, so they can edit web
#           files directly without needing sudo every time.
#
# Usage:    sudo bash chown_webroot.sh
#
# Why SUDO_USER and not $USER?
#   When run with sudo, $USER becomes "root".
#   SUDO_USER is the real logged-in user who called sudo — that's who we want.
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
LOG_DIR="/var/log/steam_clown"
LOG_FILE="${LOG_DIR}/chown_webroot_$(date +%Y%m%d_%H%M%S).log"
WEBROOT="/var/www/html"

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

setup_log() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    echo "============================================================" >> "${LOG_FILE}"
    echo "  chown_webroot.sh — $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
    echo "  Host: $(hostname)  |  Invoked by: ${SUDO_USER:-root}" >> "${LOG_FILE}"
    echo "============================================================" >> "${LOG_FILE}"
}

log_info() {
    local msg="[INFO]  $(date '+%Y-%m-%d %H:%M:%S') — $*"
    echo "${msg}" >> "${LOG_FILE}"
    echo -e "${CYAN}${msg}${RESET}"
}

log_ok() {
    local msg="[OK]    $(date '+%Y-%m-%d %H:%M:%S') — $*"
    echo "${msg}" >> "${LOG_FILE}"
    echo -e "${GREEN}${msg}${RESET}"
}

log_warn() {
    local msg="[WARN]  $(date '+%Y-%m-%d %H:%M:%S') — $*"
    echo "${msg}" >> "${LOG_FILE}"
    echo -e "${YELLOW}${msg}${RESET}"
}

log_error() {
    local msg="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') — $*"
    echo "${msg}" >> "${LOG_FILE}"
    echo -e "${RED}${msg}${RESET}"
}

log_section() {
    local divider="------------------------------------------------------------"
    echo "${divider}" >> "${LOG_FILE}"
    echo "  STEP: $*" >> "${LOG_FILE}"
    echo "${divider}" >> "${LOG_FILE}"
    echo -e "${BOLD}${divider}${RESET}"
    echo -e "${BOLD}  STEP: $*${RESET}"
    echo -e "${BOLD}${divider}${RESET}"
}

run_cmd() {
    local cmd="$*"
    log_info "Running: ${cmd}"
    echo "--- Command output begin ---" >> "${LOG_FILE}"
    eval "${cmd}" 2>&1 | tee -a "${LOG_FILE}"
    local exit_code=${PIPESTATUS[0]}
    echo "--- Command output end (exit code: ${exit_code}) ---" >> "${LOG_FILE}"
    return ${exit_code}
}

# -----------------------------------------------------------------------------
# EARLY SUDO CHECK — must run before setup_log (needs root to write to /var/log)
# -----------------------------------------------------------------------------
early_check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo ""
        echo -e "${RED}[ERROR] This script must be run with sudo.${RESET}"
        echo ""
        echo -e "  Usage:  ${BOLD}sudo bash chown_webroot.sh${RESET}"
        echo ""
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# RESOLVE THE REAL USER
# SUDO_USER = the person who ran sudo (what we want)
# If somehow run directly as root with no sudo, fall back gracefully
# -----------------------------------------------------------------------------
resolve_target_user() {
    log_section "Preflight: Resolve Target User"

    if [[ -n "${SUDO_USER}" && "${SUDO_USER}" != "root" ]]; then
        TARGET_USER="${SUDO_USER}"
        log_ok "Target user resolved from SUDO_USER: ${TARGET_USER}"
    else
        # Edge case: script was run as root directly (not via sudo)
        # Prompt for the username rather than blindly chowning to root
        log_warn "SUDO_USER is not set or is root — cannot auto-detect the target user"
        echo ""
        echo -e "${YELLOW}Could not detect the logged-in user automatically.${RESET}"
        echo -e "Please enter the username who should own ${WEBROOT}:"
        echo -n "  > "
        read -r TARGET_USER

        if [[ -z "${TARGET_USER}" ]]; then
            log_error "No username entered — exiting"
            exit 1
        fi

        # Verify the user actually exists on this system
        if ! id "${TARGET_USER}" &>/dev/null; then
            log_error "User '${TARGET_USER}' does not exist on this system — exiting"
            exit 1
        fi

        log_info "Target user set manually to: ${TARGET_USER}"
    fi

    # Log the user's UID and primary group for the audit trail
    local target_uid target_group
    target_uid=$(id -u "${TARGET_USER}")
    target_group=$(id -gn "${TARGET_USER}")
    log_info "UID: ${target_uid}  |  Primary group: ${target_group}"
}

# -----------------------------------------------------------------------------
# STEP 1 — Verify /var/www/html exists
# -----------------------------------------------------------------------------
check_webroot() {
    log_section "Step 1: Verify Web Root Exists"

    if [[ -d "${WEBROOT}" ]]; then
        log_ok "Web root found: ${WEBROOT}"

        # Log current ownership before we change anything
        local current_owner current_group current_perms
        current_owner=$(stat -c '%U' "${WEBROOT}")
        current_group=$(stat -c '%G' "${WEBROOT}")
        current_perms=$(stat -c '%a' "${WEBROOT}")
        log_info "Current owner:  ${current_owner}"
        log_info "Current group:  ${current_group}"
        log_info "Current perms:  ${current_perms}"
    else
        log_error "Web root '${WEBROOT}' does not exist"
        log_error "Is Apache installed? Run apache_setup.sh first."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# STEP 2 — Check ownership of index.html before the change
# -----------------------------------------------------------------------------
check_index_before() {
    log_section "Step 2: Pre-Change Ownership Snapshot"

    local index="${WEBROOT}/index.html"

    if [[ -f "${index}" ]]; then
        local owner group perms
        owner=$(stat -c '%U' "${index}")
        group=$(stat -c '%G' "${index}")
        perms=$(stat -c '%a' "${index}")
        log_info "index.html owner:  ${owner}"
        log_info "index.html group:  ${group}"
        log_info "index.html perms:  ${perms}"
    else
        log_warn "index.html not found at ${index} — it may not exist yet"
        log_info "Ownership change will still apply to the directory and any other files"
    fi

    # Log a full recursive ownership snapshot before the change
    log_info "Full pre-change ownership listing of ${WEBROOT}:"
    echo "--- pre-change ls -la ---" >> "${LOG_FILE}"
    ls -la "${WEBROOT}" 2>&1 | tee -a "${LOG_FILE}"
    echo "---" >> "${LOG_FILE}"
}

# -----------------------------------------------------------------------------
# STEP 3 — Change ownership recursively
# -----------------------------------------------------------------------------
chown_webroot() {
    log_section "Step 3: Change Ownership of ${WEBROOT}"

    log_info "Setting owner of ${WEBROOT} (recursive) to: ${TARGET_USER}"
    run_cmd "chown -R ${TARGET_USER}:${TARGET_USER} ${WEBROOT}"
    local exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_ok "chown completed successfully"
    else
        log_error "chown failed (exit code: ${exit_code})"
        exit ${exit_code}
    fi
}

# -----------------------------------------------------------------------------
# STEP 4 — Verify ownership after the change
# -----------------------------------------------------------------------------
verify_ownership() {
    log_section "Step 4: Post-Change Ownership Verification"

    # Check the directory itself
    local dir_owner
    dir_owner=$(stat -c '%U' "${WEBROOT}")
    if [[ "${dir_owner}" == "${TARGET_USER}" ]]; then
        log_ok "${WEBROOT} is now owned by: ${dir_owner}"
    else
        log_error "${WEBROOT} owner is '${dir_owner}' — expected '${TARGET_USER}'"
    fi

    # Check index.html specifically
    local index="${WEBROOT}/index.html"
    if [[ -f "${index}" ]]; then
        local index_owner
        index_owner=$(stat -c '%U' "${index}")
        if [[ "${index_owner}" == "${TARGET_USER}" ]]; then
            log_ok "index.html is now owned by: ${index_owner}"
        else
            log_error "index.html owner is '${index_owner}' — expected '${TARGET_USER}'"
        fi
    else
        log_warn "index.html still not present — ownership of directory confirmed above"
    fi

    # Scan for any files NOT owned by the target user (shouldn't be any, but good to verify)
    log_info "Scanning for files not owned by ${TARGET_USER}..."
    local not_owned
    not_owned=$(find "${WEBROOT}" ! -user "${TARGET_USER}" 2>/dev/null)
    if [[ -z "${not_owned}" ]]; then
        log_ok "All files and directories under ${WEBROOT} are owned by ${TARGET_USER}"
    else
        log_warn "The following items are still NOT owned by ${TARGET_USER}:"
        echo "${not_owned}" | tee -a "${LOG_FILE}"
    fi

    # Full post-change listing for the audit trail
    log_info "Full post-change ownership listing of ${WEBROOT}:"
    echo "--- post-change ls -la ---" >> "${LOG_FILE}"
    ls -la "${WEBROOT}" 2>&1 | tee -a "${LOG_FILE}"
    echo "---" >> "${LOG_FILE}"
}

# -----------------------------------------------------------------------------
# WRAP-UP
# -----------------------------------------------------------------------------
wrap_up() {
    log_section "Script Complete"
    log_ok "Web root ownership transfer finished."
    log_ok "  Target user:  ${TARGET_USER}"
    log_ok "  Directory:    ${WEBROOT}"
    log_ok "  Log file:     ${LOG_FILE}"
    echo "" >> "${LOG_FILE}"
    echo "============================================================" >> "${LOG_FILE}"
    echo "  Script ended — $(date '+%Y-%m-%d %H:%M:%S')" >> "${LOG_FILE}"
    echo "============================================================" >> "${LOG_FILE}"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    early_check_root        # Must be first — needs root to write to /var/log

    setup_log
    log_info "Starting chown_webroot.sh on $(hostname)"
    log_info "Log file: ${LOG_FILE}"

    resolve_target_user     # Preflight: figure out who gets ownership
    check_webroot           # Step 1: confirm /var/www/html exists
    check_index_before      # Step 2: snapshot ownership before the change
    chown_webroot           # Step 3: do the chown -R
    verify_ownership        # Step 4: confirm everything is correct
    wrap_up
}

main "$@"
