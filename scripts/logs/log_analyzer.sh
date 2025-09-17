#!/bin/bash

# Log Analyzer Script
# Analyzes system logs for errors, warnings, and patterns

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default log files to analyze
DEFAULT_LOGS=(
    "/var/log/syslog"
    "/var/log/messages"
    "/var/log/auth.log"
    "/var/log/secure"
    "/var/log/kern.log"
    "/var/log/dmesg"
)

# Show usage
show_usage() {
    echo -e "${BLUE}Log Analyzer Script${NC}"
    echo "Usage: $0 [OPTIONS] [LOG_FILES...]"
    echo ""
    echo "Options:"
    echo "  -e, --errors           Show only errors"
    echo "  -w, --warnings         Show only warnings"
    echo "  -t, --tail LINES       Show last N lines (default: 100)"
    echo "  -f, --follow           Follow log files (like tail -f)"
    echo "  -d, --date DATE        Filter by date (YYYY-MM-DD)"
    echo "  -p, --pattern REGEX    Search for specific pattern"
    echo "  -s, --summary          Show summary statistics"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e                  Show errors from default logs"
    echo "  $0 -t 50 /var/log/auth.log"
    echo "  $0 -p 'ssh' -d $(date +%Y-%m-%d)"
    echo ""
}

# Check if log file exists and is readable
check_log_file() {
    local logfile="$1"
    
    if [[ ! -f "$logfile" ]]; then
        return 1
    fi
    
    if [[ ! -r "$logfile" ]]; then
        return 2
    fi
    
    return 0
}

# Get available log files from defaults
get_available_logs() {
    local available_logs=()
    
    for log in "${DEFAULT_LOGS[@]}"; do
        if check_log_file "$log"; then
            available_logs+=("$log")
        fi
    done
    
    printf '%s\n' "${available_logs[@]}"
}

# Analyze single log file
analyze_log() {
    local logfile="$1"
    local filter="$2"
    local tail_lines="$3"
    local date_filter="$4"
    local pattern="$5"
    local follow="$6"
    
    if ! check_log_file "$logfile"; then
        case $? in
            1) echo -e "${YELLOW}Warning: Log file '$logfile' does not exist${NC}" ;;
            2) echo -e "${YELLOW}Warning: Log file '$logfile' is not readable${NC}" ;;
        esac
        return 1
    fi
    
    echo -e "${BLUE}Analyzing: $logfile${NC}"
    echo "----------------------------------------"
    
    # Build command
    local cmd="cat '$logfile'"
    
    # Apply date filter if specified
    if [[ -n "$date_filter" ]]; then
        cmd="$cmd | grep '$date_filter'"
    fi
    
    # Apply pattern filter if specified
    if [[ -n "$pattern" ]]; then
        cmd="$cmd | grep -i '$pattern'"
    fi
    
    # Apply error/warning filter
    case "$filter" in
        "errors")
            cmd="$cmd | grep -iE '(error|err|fail|fatal|critical)'"
            ;;
        "warnings")
            cmd="$cmd | grep -iE '(warn|warning|caution)'"
            ;;
    esac
    
    # Apply tail if not following
    if [[ "$follow" != "true" && "$tail_lines" -gt 0 ]]; then
        cmd="$cmd | tail -n $tail_lines"
    fi
    
    # Follow mode
    if [[ "$follow" == "true" ]]; then
        cmd="tail -f '$logfile'"
        if [[ -n "$pattern" ]]; then
            cmd="$cmd | grep --line-buffered -i '$pattern'"
        fi
    fi
    
    # Execute command
    if eval "$cmd"; then
        echo ""
        return 0
    else
        echo -e "${YELLOW}No matching entries found${NC}"
        echo ""
        return 1
    fi
}

# Show log summary
show_summary() {
    local logfiles=("$@")
    
    echo -e "${BLUE}Log Summary${NC}"
    echo "============================================"
    
    for logfile in "${logfiles[@]}"; do
        if ! check_log_file "$logfile"; then
            continue
        fi
        
        echo -e "${GREEN}$logfile:${NC}"
        
        # File info
        local size=$(ls -lh "$logfile" | awk '{print $5}')
        local modified=$(ls -l "$logfile" | awk '{print $6, $7, $8}')
        echo "  Size: $size"
        echo "  Modified: $modified"
        
        # Line counts
        local total_lines=$(wc -l < "$logfile" 2>/dev/null || echo "0")
        local error_lines=$(grep -ic "error\|err\|fail\|fatal\|critical" "$logfile" 2>/dev/null || echo "0")
        local warning_lines=$(grep -ic "warn\|warning\|caution" "$logfile" 2>/dev/null || echo "0")
        
        echo "  Total lines: $total_lines"
        echo "  Error entries: $error_lines"
        echo "  Warning entries: $warning_lines"
        
        # Recent activity (last hour)
        local recent_lines=$(grep "$(date '+%b %d %H')" "$logfile" 2>/dev/null | wc -l || echo "0")
        echo "  Recent activity (last hour): $recent_lines"
        
        echo ""
    done
}

# Main function
main() {
    local filter=""
    local tail_lines=100
    local follow="false"
    local date_filter=""
    local pattern=""
    local show_summary_flag="false"
    local logfiles=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--errors)
                filter="errors"
                shift
                ;;
            -w|--warnings)
                filter="warnings"
                shift
                ;;
            -t|--tail)
                tail_lines="$2"
                shift 2
                ;;
            -f|--follow)
                follow="true"
                shift
                ;;
            -d|--date)
                date_filter="$2"
                shift 2
                ;;
            -p|--pattern)
                pattern="$2"
                shift 2
                ;;
            -s|--summary)
                show_summary_flag="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
            *)
                logfiles+=("$1")
                shift
                ;;
        esac
    done
    
    # Use default logs if none specified
    if [[ ${#logfiles[@]} -eq 0 ]]; then
        mapfile -t logfiles < <(get_available_logs)
        if [[ ${#logfiles[@]} -eq 0 ]]; then
            echo -e "${RED}Error: No readable log files found${NC}"
            exit 1
        fi
        echo -e "${BLUE}Using available system logs${NC}"
    fi
    
    # Show summary if requested
    if [[ "$show_summary_flag" == "true" ]]; then
        show_summary "${logfiles[@]}"
        exit 0
    fi
    
    # Follow mode warning
    if [[ "$follow" == "true" && ${#logfiles[@]} -gt 1 ]]; then
        echo -e "${YELLOW}Warning: Follow mode with multiple files - showing first file only${NC}"
        logfiles=("${logfiles[0]}")
    fi
    
    # Analyze logs
    local success_count=0
    for logfile in "${logfiles[@]}"; do
        if analyze_log "$logfile" "$filter" "$tail_lines" "$date_filter" "$pattern" "$follow"; then
            ((success_count++))
        fi
    done
    
    if [[ $success_count -eq 0 ]]; then
        echo -e "${YELLOW}No log entries found matching criteria${NC}"
        exit 1
    fi
}

main "$@"