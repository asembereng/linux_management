#!/bin/bash

# Linux Management Master Script
# Central interface for all Linux management tools

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show main menu
show_main_menu() {
    clear
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}     Linux Management Tools Suite${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
    echo -e "${GREEN}Available Categories:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} System Information & Monitoring"
    echo -e "${CYAN}2.${NC} Package Management"
    echo -e "${CYAN}3.${NC} Service Management"
    echo -e "${CYAN}4.${NC} Backup & Recovery"
    echo -e "${CYAN}5.${NC} Log Analysis"
    echo -e "${CYAN}6.${NC} User & Permission Management"
    echo -e "${CYAN}7.${NC} Network Configuration"
    echo -e "${CYAN}8.${NC} Security & Hardening"
    echo ""
    echo -e "${CYAN}9.${NC} View Examples & Documentation"
    echo -e "${CYAN}0.${NC} Exit"
    echo ""
    echo -e "${BLUE}=========================================${NC}"
}

# System menu
show_system_menu() {
    clear
    echo -e "${BLUE}=== System Information & Monitoring ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Show system information"
    echo -e "${GREEN}2.${NC} Monitor system resources"
    echo -e "${GREEN}3.${NC} Monitor with custom thresholds"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# Package menu
show_package_menu() {
    clear
    echo -e "${BLUE}=== Package Management ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Update package lists"
    echo -e "${GREEN}2.${NC} Upgrade all packages"
    echo -e "${GREEN}3.${NC} Install a package"
    echo -e "${GREEN}4.${NC} Remove a package"
    echo -e "${GREEN}5.${NC} Search for packages"
    echo -e "${GREEN}6.${NC} List installed packages"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# Service menu
show_service_menu() {
    clear
    echo -e "${BLUE}=== Service Management ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} List all services"
    echo -e "${GREEN}2.${NC} List active services"
    echo -e "${GREEN}3.${NC} List failed services"
    echo -e "${GREEN}4.${NC} Check service status"
    echo -e "${GREEN}5.${NC} Start a service"
    echo -e "${GREEN}6.${NC} Stop a service"
    echo -e "${GREEN}7.${NC} Restart a service"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# Backup menu
show_backup_menu() {
    clear
    echo -e "${BLUE}=== Backup & Recovery ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Backup system directories"
    echo -e "${GREEN}2.${NC} Backup system directories (compressed)"
    echo -e "${GREEN}3.${NC} Backup custom directory"
    echo -e "${GREEN}4.${NC} Backup with custom settings"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# Log menu
show_log_menu() {
    clear
    echo -e "${BLUE}=== Log Analysis ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Show log summary"
    echo -e "${GREEN}2.${NC} Show recent errors"
    echo -e "${GREEN}3.${NC} Show recent warnings"
    echo -e "${GREEN}4.${NC} Search logs for pattern"
    echo -e "${GREEN}5.${NC} Analyze specific log file"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# User menu
show_user_menu() {
    clear
    echo -e "${BLUE}=== User & Permission Management ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} List users"
    echo -e "${GREEN}2.${NC} List groups"
    echo -e "${GREEN}3.${NC} Show sudo users"
    echo -e "${GREEN}4.${NC} Add user"
    echo -e "${GREEN}5.${NC} Add group"
    echo -e "${GREEN}6.${NC} Check file permissions"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# Network menu
show_network_menu() {
    clear
    echo -e "${BLUE}=== Network Configuration ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Show network status"
    echo -e "${GREEN}2.${NC} List network interfaces"
    echo -e "${GREEN}3.${NC} Show routing table"
    echo -e "${GREEN}4.${NC} Show DNS configuration"
    echo -e "${GREEN}5.${NC} Show active connections"
    echo -e "${GREEN}6.${NC} Scan for WiFi networks"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# Security menu
show_security_menu() {
    clear
    echo -e "${BLUE}=== Security & Hardening ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Perform security audit"
    echo -e "${GREEN}2.${NC} Apply basic hardening"
    echo -e "${GREEN}3.${NC} Configure firewall"
    echo -e "${GREEN}4.${NC} Harden SSH"
    echo -e "${GREEN}5.${NC} Set password policy"
    echo -e "${GREEN}6.${NC} Setup fail2ban"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# Documentation menu
show_docs_menu() {
    clear
    echo -e "${BLUE}=== Examples & Documentation ===${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} View usage examples"
    echo -e "${GREEN}2.${NC} View cron job examples"
    echo -e "${GREEN}3.${NC} View installation guide"
    echo -e "${GREEN}4.${NC} View README"
    echo -e "${GREEN}0.${NC} Back to main menu"
    echo ""
}

# Get user input
get_input() {
    echo -n -e "${YELLOW}Enter your choice: ${NC}"
    read -r choice
    echo "$choice"
}

# Press any key to continue
press_any_key() {
    echo ""
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
}

# Execute script with error handling
execute_script() {
    local script_path="$1"
    shift
    local args=("$@")
    
    echo -e "${BLUE}Executing: $(basename "$script_path") ${args[*]}${NC}"
    echo ""
    
    if [[ -x "$script_path" ]]; then
        if "${script_path}" "${args[@]}"; then
            echo ""
            echo -e "${GREEN}Command completed successfully${NC}"
        else
            echo ""
            echo -e "${RED}Command failed with exit code $?${NC}"
        fi
    else
        echo -e "${RED}Script not found or not executable: $script_path${NC}"
    fi
    
    press_any_key
}

# Get user input for parameters
get_parameter() {
    local prompt="$1"
    local value
    echo -n -e "${YELLOW}$prompt: ${NC}"
    read -r value
    echo "$value"
}

# Main application loop
main() {
    while true; do
        show_main_menu
        choice=$(get_input)
        
        case "$choice" in
            1)
                while true; do
                    show_system_menu
                    sys_choice=$(get_input)
                    case "$sys_choice" in
                        1) execute_script "$SCRIPT_DIR/scripts/system/system_info.sh" ;;
                        2) execute_script "$SCRIPT_DIR/scripts/system/system_monitor.sh" ;;
                        3) 
                            cpu=$(get_parameter "Enter CPU threshold (default 80)")
                            mem=$(get_parameter "Enter Memory threshold (default 85)")
                            disk=$(get_parameter "Enter Disk threshold (default 90)")
                            execute_script "$SCRIPT_DIR/scripts/system/system_monitor.sh" "${cpu:-80}" "${mem:-85}" "${disk:-90}"
                            ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            2)
                while true; do
                    show_package_menu
                    pkg_choice=$(get_input)
                    case "$pkg_choice" in
                        1) execute_script "$SCRIPT_DIR/scripts/packages/package_manager.sh" update ;;
                        2) execute_script "$SCRIPT_DIR/scripts/packages/package_manager.sh" upgrade ;;
                        3) 
                            package=$(get_parameter "Enter package name")
                            [[ -n "$package" ]] && execute_script "$SCRIPT_DIR/scripts/packages/package_manager.sh" install "$package"
                            ;;
                        4) 
                            package=$(get_parameter "Enter package name")
                            [[ -n "$package" ]] && execute_script "$SCRIPT_DIR/scripts/packages/package_manager.sh" remove "$package"
                            ;;
                        5) 
                            term=$(get_parameter "Enter search term")
                            [[ -n "$term" ]] && execute_script "$SCRIPT_DIR/scripts/packages/package_manager.sh" search "$term"
                            ;;
                        6) execute_script "$SCRIPT_DIR/scripts/packages/package_manager.sh" list ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            3)
                while true; do
                    show_service_menu
                    svc_choice=$(get_input)
                    case "$svc_choice" in
                        1) execute_script "$SCRIPT_DIR/scripts/services/service_manager.sh" list ;;
                        2) execute_script "$SCRIPT_DIR/scripts/services/service_manager.sh" active ;;
                        3) execute_script "$SCRIPT_DIR/scripts/services/service_manager.sh" failed ;;
                        4) 
                            service=$(get_parameter "Enter service name")
                            [[ -n "$service" ]] && execute_script "$SCRIPT_DIR/scripts/services/service_manager.sh" status "$service"
                            ;;
                        5) 
                            service=$(get_parameter "Enter service name")
                            [[ -n "$service" ]] && execute_script "$SCRIPT_DIR/scripts/services/service_manager.sh" start "$service"
                            ;;
                        6) 
                            service=$(get_parameter "Enter service name")
                            [[ -n "$service" ]] && execute_script "$SCRIPT_DIR/scripts/services/service_manager.sh" stop "$service"
                            ;;
                        7) 
                            service=$(get_parameter "Enter service name")
                            [[ -n "$service" ]] && execute_script "$SCRIPT_DIR/scripts/services/service_manager.sh" restart "$service"
                            ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            4)
                while true; do
                    show_backup_menu
                    backup_choice=$(get_input)
                    case "$backup_choice" in
                        1) execute_script "$SCRIPT_DIR/scripts/backup/backup_system.sh" -s ;;
                        2) execute_script "$SCRIPT_DIR/scripts/backup/backup_system.sh" -s -c ;;
                        3) 
                            directory=$(get_parameter "Enter directory to backup")
                            [[ -n "$directory" ]] && execute_script "$SCRIPT_DIR/scripts/backup/backup_system.sh" "$directory"
                            ;;
                        4) 
                            directory=$(get_parameter "Enter directory to backup")
                            destination=$(get_parameter "Enter backup destination (optional)")
                            compress=$(get_parameter "Compress backup? (y/n)")
                            args=()
                            [[ "$compress" =~ ^[Yy] ]] && args+=("-c")
                            [[ -n "$destination" ]] && args+=("-d" "$destination")
                            [[ -n "$directory" ]] && args+=("$directory")
                            execute_script "$SCRIPT_DIR/scripts/backup/backup_system.sh" "${args[@]}"
                            ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            5)
                while true; do
                    show_log_menu
                    log_choice=$(get_input)
                    case "$log_choice" in
                        1) execute_script "$SCRIPT_DIR/scripts/logs/log_analyzer.sh" -s ;;
                        2) execute_script "$SCRIPT_DIR/scripts/logs/log_analyzer.sh" -e ;;
                        3) execute_script "$SCRIPT_DIR/scripts/logs/log_analyzer.sh" -w ;;
                        4) 
                            pattern=$(get_parameter "Enter search pattern")
                            [[ -n "$pattern" ]] && execute_script "$SCRIPT_DIR/scripts/logs/log_analyzer.sh" -p "$pattern"
                            ;;
                        5) 
                            logfile=$(get_parameter "Enter log file path")
                            [[ -n "$logfile" ]] && execute_script "$SCRIPT_DIR/scripts/logs/log_analyzer.sh" "$logfile"
                            ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            6)
                while true; do
                    show_user_menu
                    user_choice=$(get_input)
                    case "$user_choice" in
                        1) execute_script "$SCRIPT_DIR/scripts/users/user_manager.sh" list-users ;;
                        2) execute_script "$SCRIPT_DIR/scripts/users/user_manager.sh" list-groups ;;
                        3) execute_script "$SCRIPT_DIR/scripts/users/user_manager.sh" show-sudo ;;
                        4) 
                            username=$(get_parameter "Enter username")
                            [[ -n "$username" ]] && execute_script "$SCRIPT_DIR/scripts/users/user_manager.sh" add-user "$username"
                            ;;
                        5) 
                            groupname=$(get_parameter "Enter group name")
                            [[ -n "$groupname" ]] && execute_script "$SCRIPT_DIR/scripts/users/user_manager.sh" add-group "$groupname"
                            ;;
                        6) 
                            filepath=$(get_parameter "Enter file/directory path")
                            [[ -n "$filepath" ]] && execute_script "$SCRIPT_DIR/scripts/users/user_manager.sh" check-perms "$filepath"
                            ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            7)
                while true; do
                    show_network_menu
                    net_choice=$(get_input)
                    case "$net_choice" in
                        1) execute_script "$SCRIPT_DIR/scripts/network/network_config.sh" status ;;
                        2) execute_script "$SCRIPT_DIR/scripts/network/network_config.sh" interfaces ;;
                        3) execute_script "$SCRIPT_DIR/scripts/network/network_config.sh" routes ;;
                        4) execute_script "$SCRIPT_DIR/scripts/network/network_config.sh" dns ;;
                        5) execute_script "$SCRIPT_DIR/scripts/network/network_config.sh" connections ;;
                        6) execute_script "$SCRIPT_DIR/scripts/network/network_config.sh" scan-wifi ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            8)
                while true; do
                    show_security_menu
                    sec_choice=$(get_input)
                    case "$sec_choice" in
                        1) execute_script "$SCRIPT_DIR/scripts/security/security_hardening.sh" audit ;;
                        2) execute_script "$SCRIPT_DIR/scripts/security/security_hardening.sh" harden ;;
                        3) execute_script "$SCRIPT_DIR/scripts/security/security_hardening.sh" firewall ;;
                        4) execute_script "$SCRIPT_DIR/scripts/security/security_hardening.sh" ssh-harden ;;
                        5) execute_script "$SCRIPT_DIR/scripts/security/security_hardening.sh" password-policy ;;
                        6) execute_script "$SCRIPT_DIR/scripts/security/security_hardening.sh" fail2ban ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            9)
                while true; do
                    show_docs_menu
                    doc_choice=$(get_input)
                    case "$doc_choice" in
                        1) 
                            if [[ -f "$SCRIPT_DIR/examples/usage_examples.sh" ]]; then
                                execute_script "$SCRIPT_DIR/examples/usage_examples.sh"
                            else
                                echo -e "${RED}Usage examples file not found${NC}"
                                press_any_key
                            fi
                            ;;
                        2) 
                            if [[ -f "$SCRIPT_DIR/examples/cron_examples.sh" ]]; then
                                clear
                                echo -e "${BLUE}=== Cron Job Examples ===${NC}"
                                echo ""
                                cat "$SCRIPT_DIR/examples/cron_examples.sh"
                                press_any_key
                            else
                                echo -e "${RED}Cron examples file not found${NC}"
                                press_any_key
                            fi
                            ;;
                        3) 
                            if [[ -f "$SCRIPT_DIR/docs/INSTALLATION.md" ]]; then
                                clear
                                echo -e "${BLUE}=== Installation Guide ===${NC}"
                                echo ""
                                cat "$SCRIPT_DIR/docs/INSTALLATION.md"
                                press_any_key
                            else
                                echo -e "${RED}Installation guide not found${NC}"
                                press_any_key
                            fi
                            ;;
                        4) 
                            if [[ -f "$SCRIPT_DIR/README.md" ]]; then
                                clear
                                echo -e "${BLUE}=== README ===${NC}"
                                echo ""
                                less "$SCRIPT_DIR/README.md" || cat "$SCRIPT_DIR/README.md"
                            else
                                echo -e "${RED}README file not found${NC}"
                                press_any_key
                            fi
                            ;;
                        0) break ;;
                        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
                    esac
                done
                ;;
            0)
                echo -e "${GREEN}Thank you for using Linux Management Tools!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check if scripts directory exists
if [[ ! -d "$SCRIPT_DIR/scripts" ]]; then
    echo -e "${RED}Error: Scripts directory not found at $SCRIPT_DIR/scripts${NC}"
    echo "Please make sure you're running this script from the linux_management directory"
    exit 1
fi

# Welcome message
echo -e "${GREEN}Welcome to Linux Management Tools Suite!${NC}"
echo -e "${YELLOW}This interactive menu will help you access all available tools.${NC}"
echo ""
sleep 2

# Run main application
main