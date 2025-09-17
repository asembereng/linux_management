#!/bin/bash

# Package Manager Wrapper Script
# Provides unified interface for different package managers

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect package manager
detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Show usage information
show_usage() {
    echo -e "${BLUE}Package Manager Wrapper${NC}"
    echo "Usage: $0 [COMMAND] [PACKAGE_NAME]"
    echo ""
    echo "Commands:"
    echo "  install <package>   - Install a package"
    echo "  remove <package>    - Remove a package"
    echo "  update             - Update package lists"
    echo "  upgrade            - Upgrade all packages"
    echo "  search <term>      - Search for packages"
    echo "  info <package>     - Show package information"
    echo "  list               - List installed packages"
    echo "  clean              - Clean package cache"
    echo ""
}

# Execute package manager command
execute_command() {
    local pm="$1"
    local cmd="$2"
    local package="${3:-}"
    
    case "$pm" in
        "apt")
            case "$cmd" in
                "install") sudo apt-get install -y "$package" ;;
                "remove") sudo apt-get remove -y "$package" ;;
                "update") sudo apt-get update ;;
                "upgrade") sudo apt-get upgrade -y ;;
                "search") apt-cache search "$package" ;;
                "info") apt-cache show "$package" ;;
                "list") dpkg -l ;;
                "clean") sudo apt-get clean ;;
                *) echo -e "${RED}Unknown command: $cmd${NC}"; return 1 ;;
            esac
            ;;
        "yum")
            case "$cmd" in
                "install") sudo yum install -y "$package" ;;
                "remove") sudo yum remove -y "$package" ;;
                "update") sudo yum check-update ;;
                "upgrade") sudo yum update -y ;;
                "search") yum search "$package" ;;
                "info") yum info "$package" ;;
                "list") yum list installed ;;
                "clean") sudo yum clean all ;;
                *) echo -e "${RED}Unknown command: $cmd${NC}"; return 1 ;;
            esac
            ;;
        "dnf")
            case "$cmd" in
                "install") sudo dnf install -y "$package" ;;
                "remove") sudo dnf remove -y "$package" ;;
                "update") sudo dnf check-update ;;
                "upgrade") sudo dnf upgrade -y ;;
                "search") dnf search "$package" ;;
                "info") dnf info "$package" ;;
                "list") dnf list installed ;;
                "clean") sudo dnf clean all ;;
                *) echo -e "${RED}Unknown command: $cmd${NC}"; return 1 ;;
            esac
            ;;
        "pacman")
            case "$cmd" in
                "install") sudo pacman -S --noconfirm "$package" ;;
                "remove") sudo pacman -R --noconfirm "$package" ;;
                "update") sudo pacman -Sy ;;
                "upgrade") sudo pacman -Syu --noconfirm ;;
                "search") pacman -Ss "$package" ;;
                "info") pacman -Si "$package" ;;
                "list") pacman -Q ;;
                "clean") sudo pacman -Sc --noconfirm ;;
                *) echo -e "${RED}Unknown command: $cmd${NC}"; return 1 ;;
            esac
            ;;
        "zypper")
            case "$cmd" in
                "install") sudo zypper install -y "$package" ;;
                "remove") sudo zypper remove -y "$package" ;;
                "update") sudo zypper refresh ;;
                "upgrade") sudo zypper update -y ;;
                "search") zypper search "$package" ;;
                "info") zypper info "$package" ;;
                "list") zypper search --installed-only ;;
                "clean") sudo zypper clean ;;
                *) echo -e "${RED}Unknown command: $cmd${NC}"; return 1 ;;
            esac
            ;;
        *)
            echo -e "${RED}Unsupported package manager: $pm${NC}"
            return 1
            ;;
    esac
}

# Main function
main() {
    local pm cmd package
    
    pm=$(detect_package_manager)
    
    if [[ "$pm" == "unknown" ]]; then
        echo -e "${RED}Error: No supported package manager found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Detected package manager: $pm${NC}"
    
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    cmd="$1"
    package="${2:-}"
    
    if [[ "$cmd" != "update" && "$cmd" != "upgrade" && "$cmd" != "list" && "$cmd" != "clean" && -z "$package" ]]; then
        echo -e "${RED}Error: Package name required for $cmd command${NC}"
        show_usage
        exit 1
    fi
    
    echo -e "${BLUE}Executing: $cmd $package${NC}"
    execute_command "$pm" "$cmd" "$package"
}

main "$@"