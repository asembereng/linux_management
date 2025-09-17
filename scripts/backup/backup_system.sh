#!/bin/bash

# Backup Script
# Creates backups of important system files and directories

set -euo pipefail

# Configuration
BACKUP_BASE_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/backup.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default backup sources
DEFAULT_SOURCES=(
    "/etc"
    "/home"
    "/var/www"
    "/var/log"
    "/root"
)

# Logging function
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | sudo tee -a "$LOG_FILE" >/dev/null 2>&1 || echo "[$timestamp] $message"
    echo -e "$message"
}

# Show usage
show_usage() {
    echo -e "${BLUE}Backup Script${NC}"
    echo "Usage: $0 [OPTIONS] [SOURCE_PATHS...]"
    echo ""
    echo "Options:"
    echo "  -d, --destination DIR  Backup destination directory (default: $BACKUP_BASE_DIR)"
    echo "  -c, --compress         Compress backup with gzip"
    echo "  -e, --exclude PATTERN  Exclude files matching pattern"
    echo "  -s, --system           Backup default system directories"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /home/user          Backup specific directory"
    echo "  $0 -s                  Backup system directories"
    echo "  $0 -c /home            Backup and compress /home"
    echo ""
}

# Create backup directory
create_backup_dir() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_message "${BLUE}Creating backup directory: $backup_dir${NC}"
        sudo mkdir -p "$backup_dir" || {
            log_message "${RED}Error: Failed to create backup directory${NC}"
            exit 1
        }
    fi
}

# Backup function
backup_directory() {
    local source="$1"
    local destination="$2"
    local compress="$3"
    local exclude_pattern="${4:-}"
    
    if [[ ! -d "$source" && ! -f "$source" ]]; then
        log_message "${YELLOW}Warning: Source '$source' does not exist, skipping${NC}"
        return 1
    fi
    
    local source_name=$(basename "$source")
    local backup_name="${source_name}_${DATE}"
    local backup_path="$destination/$backup_name"
    
    log_message "${BLUE}Backing up: $source -> $backup_path${NC}"
    
    # Build rsync command
    local rsync_cmd="sudo rsync -av --progress"
    
    if [[ -n "$exclude_pattern" ]]; then
        rsync_cmd="$rsync_cmd --exclude='$exclude_pattern'"
    fi
    
    # Common exclusions
    rsync_cmd="$rsync_cmd --exclude='*.tmp' --exclude='*.cache' --exclude='lost+found'"
    
    rsync_cmd="$rsync_cmd '$source' '$backup_path'"
    
    # Execute backup
    if eval "$rsync_cmd"; then
        log_message "${GREEN}Successfully backed up: $source${NC}"
        
        # Compress if requested
        if [[ "$compress" == "true" ]]; then
            log_message "${BLUE}Compressing backup...${NC}"
            if sudo tar -czf "${backup_path}.tar.gz" -C "$destination" "$backup_name" && sudo rm -rf "$backup_path"; then
                log_message "${GREEN}Compression completed: ${backup_path}.tar.gz${NC}"
            else
                log_message "${YELLOW}Warning: Compression failed, keeping uncompressed backup${NC}"
            fi
        fi
        
        return 0
    else
        log_message "${RED}Error: Failed to backup $source${NC}"
        return 1
    fi
}

# Calculate directory size
calculate_size() {
    local path="$1"
    if [[ -d "$path" || -f "$path" ]]; then
        du -sh "$path" 2>/dev/null | cut -f1 || echo "Unknown"
    else
        echo "N/A"
    fi
}

# Main function
main() {
    local destination="$BACKUP_BASE_DIR"
    local compress="false"
    local exclude_pattern=""
    local system_backup="false"
    local sources=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--destination)
                destination="$2"
                shift 2
                ;;
            -c|--compress)
                compress="true"
                shift
                ;;
            -e|--exclude)
                exclude_pattern="$2"
                shift 2
                ;;
            -s|--system)
                system_backup="true"
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
                sources+=("$1")
                shift
                ;;
        esac
    done
    
    # Set sources
    if [[ "$system_backup" == "true" ]]; then
        sources=("${DEFAULT_SOURCES[@]}")
    elif [[ ${#sources[@]} -eq 0 ]]; then
        echo -e "${RED}Error: No source paths specified${NC}"
        show_usage
        exit 1
    fi
    
    # Create backup directory
    create_backup_dir "$destination"
    
    log_message "${GREEN}=== Backup started at $(date) ===${NC}"
    log_message "${BLUE}Destination: $destination${NC}"
    log_message "${BLUE}Compression: $compress${NC}"
    
    local success_count=0
    local total_count=${#sources[@]}
    
    # Show backup summary
    log_message "${BLUE}Backup Summary:${NC}"
    for source in "${sources[@]}"; do
        local size=$(calculate_size "$source")
        log_message "  $source ($size)"
    done
    
    # Perform backups
    for source in "${sources[@]}"; do
        if backup_directory "$source" "$destination" "$compress" "$exclude_pattern"; then
            ((success_count++))
        fi
    done
    
    # Show results
    log_message "${GREEN}=== Backup completed at $(date) ===${NC}"
    log_message "${BLUE}Results: $success_count/$total_count successful${NC}"
    
    if [[ $success_count -eq $total_count ]]; then
        log_message "${GREEN}All backups completed successfully${NC}"
        exit 0
    else
        log_message "${YELLOW}Some backups failed - check log file${NC}"
        exit 1
    fi
}

# Check if running as root for system directories
if [[ $EUID -ne 0 ]] && [[ "$*" == *"-s"* || "$*" == *"--system"* ]]; then
    echo -e "${YELLOW}Warning: Running system backup without root privileges${NC}"
    echo "Some directories may not be accessible"
fi

main "$@"