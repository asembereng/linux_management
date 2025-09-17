#!/bin/bash

# Security Hardening Script
# Basic security hardening for Linux systems

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log file
SECURITY_LOG="/var/log/security_hardening.log"

# Logging function
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | sudo tee -a "$SECURITY_LOG" >/dev/null 2>&1 || echo "[$timestamp] $message"
    echo -e "$message"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo -e "${BLUE}Security Hardening Script${NC}"
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  audit                  Perform security audit"
    echo "  harden                 Apply basic hardening"
    echo "  firewall               Configure basic firewall"
    echo "  ssh-harden             Harden SSH configuration"
    echo "  password-policy        Set password policy"
    echo "  fail2ban               Install and configure fail2ban"
    echo "  updates                Configure automatic updates"
    echo "  permissions            Fix common permission issues"
    echo "  all                    Run all hardening steps"
    echo ""
}

# Security audit
security_audit() {
    log_message "${BLUE}=== Security Audit Started ===${NC}"
    
    # Check users with UID 0
    log_message "${BLUE}Checking for users with UID 0:${NC}"
    awk -F: '$3 == 0 {print $1}' /etc/passwd
    
    # Check for empty passwords
    log_message "${BLUE}Checking for empty passwords:${NC}"
    awk -F: '$2 == "" {print $1}' /etc/shadow 2>/dev/null || echo "Cannot access /etc/shadow"
    
    # Check world-writable files
    log_message "${BLUE}Checking for world-writable files in critical directories:${NC}"
    find /etc /usr/bin /usr/sbin /bin /sbin -type f -perm -002 2>/dev/null | head -10
    
    # Check SUID/SGID files
    log_message "${BLUE}Checking SUID/SGID files:${NC}"
    find / -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null | head -10
    
    # Check listening services
    log_message "${BLUE}Checking listening services:${NC}"
    if command -v ss >/dev/null 2>&1; then
        ss -tuln
    else
        netstat -tuln
    fi
    
    # Check last logins
    log_message "${BLUE}Recent login activity:${NC}"
    last -10
    
    # Check failed login attempts
    log_message "${BLUE}Recent failed login attempts:${NC}"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 || echo "No auth.log or no failed attempts"
    
    log_message "${GREEN}Security audit completed${NC}"
}

# Basic hardening
basic_hardening() {
    check_root
    log_message "${BLUE}=== Basic Hardening Started ===${NC}"
    
    # Disable unused network protocols
    log_message "${BLUE}Disabling unused network protocols...${NC}"
    cat >> /etc/modprobe.d/blacklist-rare-network.conf << 'EOF'
# Disable rare network protocols
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF
    
    # Set kernel parameters for security
    log_message "${BLUE}Setting secure kernel parameters...${NC}"
    cat >> /etc/sysctl.d/99-security.conf << 'EOF'
# IP Spoofing protection
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Ignore ICMP ping requests
net.ipv4.icmp_echo_ignore_all = 1

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log Martians
net.ipv4.conf.all.log_martians = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
EOF
    
    sysctl -p /etc/sysctl.d/99-security.conf
    
    # Set umask for better default permissions
    log_message "${BLUE}Setting secure umask...${NC}"
    echo "umask 027" >> /etc/profile
    
    log_message "${GREEN}Basic hardening completed${NC}"
}

# Configure firewall
configure_firewall() {
    check_root
    log_message "${BLUE}=== Configuring Firewall ===${NC}"
    
    if command -v ufw >/dev/null 2>&1; then
        log_message "${BLUE}Configuring UFW firewall...${NC}"
        
        # Reset to defaults
        ufw --force reset
        
        # Default policies
        ufw default deny incoming
        ufw default allow outgoing
        
        # Allow SSH (be careful not to lock yourself out)
        ufw allow ssh
        
        # Allow common services (uncomment as needed)
        # ufw allow http
        # ufw allow https
        
        # Enable firewall
        ufw --force enable
        
        ufw status verbose
        
    elif command -v firewall-cmd >/dev/null 2>&1; then
        log_message "${BLUE}Configuring firewalld...${NC}"
        
        systemctl enable firewalld
        systemctl start firewalld
        
        # Set default zone
        firewall-cmd --set-default-zone=public
        
        # Allow SSH
        firewall-cmd --permanent --add-service=ssh
        
        # Reload configuration
        firewall-cmd --reload
        
        firewall-cmd --list-all
        
    elif command -v iptables >/dev/null 2>&1; then
        log_message "${BLUE}Configuring iptables...${NC}"
        
        # Basic iptables rules
        iptables -F
        iptables -X
        iptables -t nat -F
        iptables -t nat -X
        iptables -t mangle -F
        iptables -t mangle -X
        
        # Default policies
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        
        # Allow loopback
        iptables -A INPUT -i lo -j ACCEPT
        
        # Allow established connections
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        
        # Allow SSH
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        
        # Save rules (method varies by distribution)
        if command -v iptables-save >/dev/null 2>&1; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
            iptables-save > /etc/iptables.rules 2>/dev/null || \
            echo "Manual iptables save required"
        fi
        
    else
        log_message "${YELLOW}No supported firewall found${NC}"
        return 1
    fi
    
    log_message "${GREEN}Firewall configuration completed${NC}"
}

# Harden SSH
harden_ssh() {
    check_root
    log_message "${BLUE}=== Hardening SSH Configuration ===${NC}"
    
    local ssh_config="/etc/ssh/sshd_config"
    
    if [[ ! -f "$ssh_config" ]]; then
        log_message "${YELLOW}SSH configuration file not found${NC}"
        return 1
    fi
    
    # Backup original config
    cp "$ssh_config" "${ssh_config}.backup"
    
    # Apply hardening settings
    log_message "${BLUE}Applying SSH hardening settings...${NC}"
    
    # Create hardened config
    cat >> "${ssh_config}.hardened" << 'EOF'

# Security hardening settings
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers *
DenyUsers root
MaxStartups 2
Banner /etc/issue.net
EOF
    
    # Merge configurations (basic approach)
    grep -v "^#" "$ssh_config" | grep -v "^$" > "${ssh_config}.clean"
    cat "${ssh_config}.hardened" >> "${ssh_config}.clean"
    
    # Apply new configuration
    mv "${ssh_config}.clean" "$ssh_config"
    
    # Create security banner
    cat > /etc/issue.net << 'EOF'
***************************************************************************
                            NOTICE TO USERS
***************************************************************************

This computer system is the private property of its owner, whether
individual, corporate or government.  It is for authorized use only.
Users (authorized or unauthorized) have no explicit or implicit
expectation of privacy.

Any or all uses of this system and all files on this system may be
intercepted, monitored, recorded, copied, audited, inspected, and
disclosed to your employer, to authorized site, government, and law
enforcement personnel, as well as authorized officials of government
agencies, both domestic and foreign.

By using this system, the user consents to such interception, monitoring,
recording, copying, auditing, inspection, and disclosure at the
discretion of such personnel or officials.  Unauthorized or improper use
of this system may result in civil and criminal penalties and
administrative or disciplinary action, as well as termination of
employment or access.  By continuing to use this system you indicate
your awareness of and consent to these terms and conditions of use.
LOG OFF IMMEDIATELY if you do not agree to the conditions stated in
this warning.

***************************************************************************
EOF
    
    # Test configuration
    if sshd -t; then
        log_message "${GREEN}SSH configuration test passed${NC}"
        systemctl reload sshd || service ssh reload
    else
        log_message "${RED}SSH configuration test failed - reverting${NC}"
        mv "${ssh_config}.backup" "$ssh_config"
        return 1
    fi
    
    log_message "${GREEN}SSH hardening completed${NC}"
}

# Set password policy
set_password_policy() {
    check_root
    log_message "${BLUE}=== Setting Password Policy ===${NC}"
    
    # Install libpam-pwquality if available
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y libpam-pwquality
    elif command -v yum >/dev/null 2>&1; then
        yum install -y libpwquality
    fi
    
    # Configure password quality
    if [[ -f /etc/security/pwquality.conf ]]; then
        log_message "${BLUE}Configuring password quality...${NC}"
        
        cp /etc/security/pwquality.conf /etc/security/pwquality.conf.backup
        
        cat >> /etc/security/pwquality.conf << 'EOF'

# Password quality requirements
minlen = 12
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
minclass = 4
maxrepeat = 3
maxclasschng = 0
maxsequence = 3
gecoscheck = 1
dictcheck = 1
usercheck = 1
enforcing = 1
EOF
    fi
    
    # Set password aging
    log_message "${BLUE}Setting password aging policy...${NC}"
    
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS\t90/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS\t7/' /etc/login.defs
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE\t14/' /etc/login.defs
    
    log_message "${GREEN}Password policy configuration completed${NC}"
}

# Install and configure fail2ban
setup_fail2ban() {
    check_root
    log_message "${BLUE}=== Setting up Fail2ban ===${NC}"
    
    # Install fail2ban
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y fail2ban
    elif command -v yum >/dev/null 2>&1; then
        yum install -y fail2ban
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y fail2ban
    else
        log_message "${YELLOW}Package manager not supported for fail2ban installation${NC}"
        return 1
    fi
    
    # Configure fail2ban
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd
destemail = root@localhost
sender = fail2ban@localhost
mta = sendmail
protocol = tcp
chain = INPUT

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
    
    # Enable and start fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    log_message "${GREEN}Fail2ban setup completed${NC}"
}

# Configure automatic updates
configure_updates() {
    check_root
    log_message "${BLUE}=== Configuring Automatic Updates ===${NC}"
    
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y unattended-upgrades
        
        # Configure unattended upgrades
        cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF
        
        echo 'APT::Periodic::Update-Package-Lists "1";' > /etc/apt/apt.conf.d/20auto-upgrades
        echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/20auto-upgrades
        
    elif command -v yum >/dev/null 2>&1; then
        yum install -y yum-cron
        systemctl enable yum-cron
        systemctl start yum-cron
    fi
    
    log_message "${GREEN}Automatic updates configuration completed${NC}"
}

# Fix common permission issues
fix_permissions() {
    check_root
    log_message "${BLUE}=== Fixing Common Permission Issues ===${NC}"
    
    # Secure important files
    chmod 600 /etc/shadow 2>/dev/null || true
    chmod 640 /etc/passwd
    chmod 640 /etc/group
    chmod 600 /etc/gshadow 2>/dev/null || true
    
    # Secure SSH directory
    if [[ -d /etc/ssh ]]; then
        chmod 755 /etc/ssh
        chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null || true
        chmod 644 /etc/ssh/ssh_host_*_key.pub 2>/dev/null || true
        chmod 644 /etc/ssh/sshd_config
    fi
    
    # Secure home directories
    for home in /home/*; do
        if [[ -d "$home" ]]; then
            chmod 750 "$home"
            chown "$(basename "$home"):$(basename "$home")" "$home" 2>/dev/null || true
        fi
    done
    
    # Remove world-writable permissions from system directories
    find /usr /etc -type d -perm -002 -exec chmod o-w {} \; 2>/dev/null || true
    
    log_message "${GREEN}Permission fixes completed${NC}"
}

# Run all hardening steps
run_all_hardening() {
    log_message "${BLUE}=== Running All Security Hardening Steps ===${NC}"
    
    security_audit
    basic_hardening
    configure_firewall
    harden_ssh
    set_password_policy
    setup_fail2ban
    configure_updates
    fix_permissions
    
    log_message "${GREEN}=== All Security Hardening Completed ===${NC}"
    log_message "${YELLOW}Please review the changes and test your system${NC}"
    log_message "${YELLOW}Reboot may be required for some changes to take effect${NC}"
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    local command="$1"
    
    case "$command" in
        "audit")
            security_audit
            ;;
        "harden")
            basic_hardening
            ;;
        "firewall")
            configure_firewall
            ;;
        "ssh-harden")
            harden_ssh
            ;;
        "password-policy")
            set_password_policy
            ;;
        "fail2ban")
            setup_fail2ban
            ;;
        "updates")
            configure_updates
            ;;
        "permissions")
            fix_permissions
            ;;
        "all")
            run_all_hardening
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"