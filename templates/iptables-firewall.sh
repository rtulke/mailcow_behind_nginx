#!/bin/bash
# iptables firewall configuration

set -euo pipefail

# Define allowed TCP ports
readonly ALLOWED_TCP_PORTS=(22 80 443 25 465 587 993 995)
readonly SCRIPT_NAME="${0##*/}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME}: $*" >&2
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# Backup current iptables rules
backup_rules() {
    local BACKUP_FILE="/etc/iptables/rules.backup.$(date +%Y%m%d_%H%M%S)"
    
    if command -v iptables-save >/dev/null 2>&1; then
        mkdir -p "$(dirname "$BACKUP_FILE")"
        iptables-save > "$BACKUP_FILE"
        log "Current rules backed up to: $BACKUP_FILE"
    fi
}

# Flush existing rules
flush_rules() {
    log "Flushing existing iptables rules"
    
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
}

# Set default policies
set_default_policies() {
    log "Setting default policies"
    
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
}

# Allow loopback traffic
allow_loopback() {
    log "Allowing loopback traffic"
    
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
}

# Allow established and related connections
allow_established() {
    log "Allowing established and related connections"
    
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
}

# Allow specific TCP ports
allow_tcp_ports() {
    local PORT
    
    for PORT in "${ALLOWED_TCP_PORTS[@]}"; do
        log "Allowing TCP port $PORT"
        iptables -A INPUT -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    done
}

# Drop invalid packets
drop_invalid() {
    log "Dropping invalid packets"
    
    iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
}

# Rate limiting for SSH (optional security measure)
rate_limit_ssh() {
    log "Applying rate limiting to SSH"
    
    # Remove existing SSH rule and add rate-limited version
    iptables -D INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
    iptables -I INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    iptables -I INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
}

# Save rules (Debian/Ubuntu)
save_rules() {
    if command -v iptables-save >/dev/null 2>&1; then
        log "Saving iptables rules"
        
        # For Debian/Ubuntu systems
        if [[ -d /etc/iptables ]]; then
            iptables-save > /etc/iptables/rules.v4
        elif [[ -f /etc/iptables.rules ]]; then
            iptables-save > /etc/iptables.rules
        else
            log "WARNING: Could not determine where to save rules permanently"
        fi
    fi
}

# Display current rules
show_rules() {
    log "Current iptables rules:"
    iptables -L -n -v --line-numbers
}

# Main function
main() {
    log "Starting iptables firewall configuration"
    
    check_root
    backup_rules
    flush_rules
    set_default_policies
    allow_loopback
    allow_established
    drop_invalid
    allow_tcp_ports
    rate_limit_ssh
    save_rules
    show_rules
    
    log "Firewall configuration completed successfully"
    log "Services allowed: SSH(22), HTTP(80), HTTPS(443), SMTP(25,465,587), IMAP(993), POP3(995)"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
