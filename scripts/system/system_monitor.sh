#!/bin/bash

# System Monitor Script
# Monitors system resources and alerts on high usage

set -euo pipefail

# Configuration
CPU_THRESHOLD=${1:-80}      # CPU usage threshold (default 80%)
MEMORY_THRESHOLD=${2:-85}   # Memory usage threshold (default 85%)
DISK_THRESHOLD=${3:-90}     # Disk usage threshold (default 90%)

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Log file
LOG_FILE="/var/log/system_monitor.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" >/dev/null 2>&1 || echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check CPU usage
check_cpu() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    
    # Handle different top output formats
    if [[ -z "$cpu_usage" ]]; then
        cpu_usage=$(sar -u 1 1 2>/dev/null | tail -1 | awk '{print 100-$8}' | cut -d. -f1 || echo "0")
    fi
    
    # If still empty, use alternative method
    if [[ -z "$cpu_usage" || "$cpu_usage" == "0" ]]; then
        cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print int(usage)}')
    fi
    
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${RED}WARNING: High CPU usage detected: ${cpu_usage}%${NC}"
        log_message "HIGH CPU USAGE: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        return 1
    else
        echo -e "${GREEN}CPU usage: ${cpu_usage}% (OK)${NC}"
        return 0
    fi
}

# Function to check memory usage
check_memory() {
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    
    if (( mem_usage > MEMORY_THRESHOLD )); then
        echo -e "${RED}WARNING: High memory usage detected: ${mem_usage}%${NC}"
        log_message "HIGH MEMORY USAGE: ${mem_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        return 1
    else
        echo -e "${GREEN}Memory usage: ${mem_usage}% (OK)${NC}"
        return 0
    fi
}

# Function to check disk usage
check_disk() {
    local alert_triggered=false
    
    while IFS= read -r line; do
        local usage filesystem
        usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        filesystem=$(echo "$line" | awk '{print $6}')
        
        if (( usage > DISK_THRESHOLD )); then
            echo -e "${RED}WARNING: High disk usage on ${filesystem}: ${usage}%${NC}"
            log_message "HIGH DISK USAGE: ${filesystem} at ${usage}% (threshold: ${DISK_THRESHOLD}%)"
            alert_triggered=true
        else
            echo -e "${GREEN}Disk usage on ${filesystem}: ${usage}% (OK)${NC}"
        fi
    done < <(df -h | grep -vE '^Filesystem|tmpfs|cdrom|udev' | awk '$5 != "-"')
    
    if [[ "$alert_triggered" == "true" ]]; then
        return 1
    else
        return 0
    fi
}

# Function to check system load
check_load() {
    local load_1min cpu_cores load_per_core
    load_1min=$(cat /proc/loadavg | awk '{print $1}')
    cpu_cores=$(nproc)
    load_per_core=$(echo "scale=2; $load_1min / $cpu_cores" | bc -l 2>/dev/null || echo "0")
    
    if (( $(echo "$load_per_core > 1.5" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${YELLOW}CAUTION: High system load: ${load_1min} (${load_per_core} per core)${NC}"
        log_message "HIGH SYSTEM LOAD: ${load_1min} across ${cpu_cores} cores"
        return 1
    else
        echo -e "${GREEN}System load: ${load_1min} (OK)${NC}"
        return 0
    fi
}

# Main monitoring function
main() {
    echo "System Monitor - $(date)"
    echo "Thresholds: CPU=${CPU_THRESHOLD}%, Memory=${MEMORY_THRESHOLD}%, Disk=${DISK_THRESHOLD}%"
    echo "========================================="
    
    local exit_code=0
    
    check_cpu || exit_code=1
    check_memory || exit_code=1
    check_disk || exit_code=1
    check_load || exit_code=1
    
    echo "========================================="
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}All systems normal${NC}"
        log_message "SYSTEM CHECK: All systems normal"
    else
        echo -e "${RED}System alerts detected - check log file${NC}"
        log_message "SYSTEM CHECK: Alerts detected"
    fi
    
    return $exit_code
}

# Install bc if not available (for calculations)
if ! command -v bc >/dev/null 2>&1; then
    echo "Installing bc for calculations..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y bc
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y bc
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y bc
    fi
fi

# Run main function
main "$@"