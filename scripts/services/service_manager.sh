#!/bin/bash

# Service Management Script
# Unified interface for managing system services

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect init system
detect_init_system() {
    if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
        echo "systemd"
    elif command -v service >/dev/null 2>&1; then
        echo "sysv"
    else
        echo "unknown"
    fi
}

# Show usage
show_usage() {
    echo -e "${BLUE}Service Management Script${NC}"
    echo "Usage: $0 [COMMAND] [SERVICE_NAME]"
    echo ""
    echo "Commands:"
    echo "  start <service>     - Start a service"
    echo "  stop <service>      - Stop a service"
    echo "  restart <service>   - Restart a service"
    echo "  reload <service>    - Reload a service"
    echo "  status <service>    - Show service status"
    echo "  enable <service>    - Enable service at boot"
    echo "  disable <service>   - Disable service at boot"
    echo "  list               - List all services"
    echo "  active             - List active services"
    echo "  failed             - List failed services"
    echo ""
}

# Execute service command
execute_service_command() {
    local init_system="$1"
    local cmd="$2"
    local service="${3:-}"
    
    case "$init_system" in
        "systemd")
            case "$cmd" in
                "start") sudo systemctl start "$service" ;;
                "stop") sudo systemctl stop "$service" ;;
                "restart") sudo systemctl restart "$service" ;;
                "reload") sudo systemctl reload "$service" ;;
                "status") systemctl status "$service" ;;
                "enable") sudo systemctl enable "$service" ;;
                "disable") sudo systemctl disable "$service" ;;
                "list") systemctl list-units --type=service ;;
                "active") systemctl list-units --type=service --state=active ;;
                "failed") systemctl list-units --type=service --state=failed ;;
                *) echo -e "${RED}Unknown command: $cmd${NC}"; return 1 ;;
            esac
            ;;
        "sysv")
            case "$cmd" in
                "start") sudo service "$service" start ;;
                "stop") sudo service "$service" stop ;;
                "restart") sudo service "$service" restart ;;
                "reload") sudo service "$service" reload ;;
                "status") service "$service" status ;;
                "enable") sudo update-rc.d "$service" enable ;;
                "disable") sudo update-rc.d "$service" disable ;;
                "list") service --status-all ;;
                "active") service --status-all | grep "+" ;;
                "failed") service --status-all | grep "-" ;;
                *) echo -e "${RED}Unknown command: $cmd${NC}"; return 1 ;;
            esac
            ;;
        *)
            echo -e "${RED}Unsupported init system: $init_system${NC}"
            return 1
            ;;
    esac
}

# Check if service exists
service_exists() {
    local init_system="$1"
    local service="$2"
    
    case "$init_system" in
        "systemd")
            systemctl list-unit-files | grep -q "^${service}.service"
            ;;
        "sysv")
            [[ -f "/etc/init.d/$service" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Main function
main() {
    local init_system cmd service
    
    init_system=$(detect_init_system)
    
    if [[ "$init_system" == "unknown" ]]; then
        echo -e "${RED}Error: No supported init system found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Detected init system: $init_system${NC}"
    
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    cmd="$1"
    service="${2:-}"
    
    # Commands that don't require service name
    if [[ "$cmd" != "list" && "$cmd" != "active" && "$cmd" != "failed" && -z "$service" ]]; then
        echo -e "${RED}Error: Service name required for $cmd command${NC}"
        show_usage
        exit 1
    fi
    
    # Check if service exists (for commands that require it)
    if [[ -n "$service" && "$cmd" != "enable" ]]; then
        if ! service_exists "$init_system" "$service"; then
            echo -e "${YELLOW}Warning: Service '$service' may not exist${NC}"
        fi
    fi
    
    echo -e "${BLUE}Executing: $cmd $service${NC}"
    execute_service_command "$init_system" "$cmd" "$service"
    
    # Show result status for some commands
    case "$cmd" in
        "start"|"stop"|"restart"|"reload")
            echo -e "${BLUE}Current status:${NC}"
            execute_service_command "$init_system" "status" "$service" || true
            ;;
    esac
}

main "$@"