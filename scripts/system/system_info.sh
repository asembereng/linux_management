#!/bin/bash

# System Information Script
# Displays comprehensive system information

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}           SYSTEM INFORMATION${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_section() {
    echo -e "\n${GREEN}$1${NC}"
    echo "-------------------------------------------"
}

# System Information
print_header

# Basic System Info
print_section "BASIC SYSTEM INFORMATION"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
echo "Architecture: $(uname -m)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"

# CPU Information
print_section "CPU INFORMATION"
if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket"
else
    grep -E "model name|processor|cores|siblings" /proc/cpuinfo | head -8
fi

# Memory Information
print_section "MEMORY INFORMATION"
free -h

# Disk Information
print_section "DISK USAGE"
df -h | grep -vE '^Filesystem|tmpfs|cdrom|udev'

# Network Information
print_section "NETWORK INTERFACES"
if command -v ip >/dev/null 2>&1; then
    ip -br addr show
else
    ifconfig | grep -E "^[a-zA-Z]|inet "
fi

# Load Average
print_section "SYSTEM LOAD"
echo "Load Average: $(cat /proc/loadavg)"

# Top Processes by CPU
print_section "TOP 5 PROCESSES BY CPU"
ps aux --sort=-%cpu | head -6

# Top Processes by Memory
print_section "TOP 5 PROCESSES BY MEMORY"
ps aux --sort=-%mem | head -6

echo -e "\n${BLUE}===========================================${NC}"