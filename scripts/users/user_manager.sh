#!/bin/bash

# User Management Script
# Manage users, groups, and permissions

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo -e "${BLUE}User Management Script${NC}"
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "User Commands:"
    echo "  add-user <username>        Add new user"
    echo "  del-user <username>        Delete user"
    echo "  mod-user <username>        Modify user"
    echo "  lock-user <username>       Lock user account"
    echo "  unlock-user <username>     Unlock user account"
    echo "  passwd <username>          Change user password"
    echo "  list-users                 List all users"
    echo ""
    echo "Group Commands:"
    echo "  add-group <groupname>      Add new group"
    echo "  del-group <groupname>      Delete group"
    echo "  add-to-group <user> <group> Add user to group"
    echo "  remove-from-group <user> <group> Remove user from group"
    echo "  list-groups                List all groups"
    echo ""
    echo "Permission Commands:"
    echo "  check-perms <file/dir>     Check permissions"
    echo "  set-perms <file/dir> <perms> Set permissions"
    echo "  show-sudo                  Show sudo users"
    echo ""
}

# Add user
add_user() {
    local username="$1"
    local create_home="${2:-yes}"
    local shell="${3:-/bin/bash}"
    
    if id "$username" &>/dev/null; then
        echo -e "${YELLOW}User '$username' already exists${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Creating user: $username${NC}"
    
    local useradd_cmd="useradd"
    
    if [[ "$create_home" == "yes" ]]; then
        useradd_cmd="$useradd_cmd -m"
    fi
    
    useradd_cmd="$useradd_cmd -s $shell $username"
    
    if eval "$useradd_cmd"; then
        echo -e "${GREEN}User '$username' created successfully${NC}"
        
        # Set password
        echo -e "${BLUE}Setting password for $username${NC}"
        passwd "$username"
        
        return 0
    else
        echo -e "${RED}Failed to create user '$username'${NC}"
        return 1
    fi
}

# Delete user
delete_user() {
    local username="$1"
    local remove_home="${2:-no}"
    
    if ! id "$username" &>/dev/null; then
        echo -e "${YELLOW}User '$username' does not exist${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Deleting user: $username${NC}"
    
    local userdel_cmd="userdel"
    
    if [[ "$remove_home" == "yes" ]]; then
        userdel_cmd="$userdel_cmd -r"
    fi
    
    userdel_cmd="$userdel_cmd $username"
    
    if eval "$userdel_cmd"; then
        echo -e "${GREEN}User '$username' deleted successfully${NC}"
        return 0
    else
        echo -e "${RED}Failed to delete user '$username'${NC}"
        return 1
    fi
}

# Lock user
lock_user() {
    local username="$1"
    
    if ! id "$username" &>/dev/null; then
        echo -e "${YELLOW}User '$username' does not exist${NC}"
        return 1
    fi
    
    if usermod -L "$username"; then
        echo -e "${GREEN}User '$username' locked successfully${NC}"
        return 0
    else
        echo -e "${RED}Failed to lock user '$username'${NC}"
        return 1
    fi
}

# Unlock user
unlock_user() {
    local username="$1"
    
    if ! id "$username" &>/dev/null; then
        echo -e "${YELLOW}User '$username' does not exist${NC}"
        return 1
    fi
    
    if usermod -U "$username"; then
        echo -e "${GREEN}User '$username' unlocked successfully${NC}"
        return 0
    else
        echo -e "${RED}Failed to unlock user '$username'${NC}"
        return 1
    fi
}

# List users
list_users() {
    echo -e "${BLUE}System Users:${NC}"
    echo "Username:UID:GID:Home:Shell"
    echo "------------------------------"
    
    while IFS=: read -r username _ uid gid _ home shell; do
        # Skip system users (typically UID < 1000)
        if [[ $uid -ge 1000 ]] || [[ "$username" == "root" ]]; then
            echo "$username:$uid:$gid:$home:$shell"
        fi
    done < /etc/passwd
}

# Add group
add_group() {
    local groupname="$1"
    
    if getent group "$groupname" &>/dev/null; then
        echo -e "${YELLOW}Group '$groupname' already exists${NC}"
        return 1
    fi
    
    if groupadd "$groupname"; then
        echo -e "${GREEN}Group '$groupname' created successfully${NC}"
        return 0
    else
        echo -e "${RED}Failed to create group '$groupname'${NC}"
        return 1
    fi
}

# Delete group
delete_group() {
    local groupname="$1"
    
    if ! getent group "$groupname" &>/dev/null; then
        echo -e "${YELLOW}Group '$groupname' does not exist${NC}"
        return 1
    fi
    
    if groupdel "$groupname"; then
        echo -e "${GREEN}Group '$groupname' deleted successfully${NC}"
        return 0
    else
        echo -e "${RED}Failed to delete group '$groupname'${NC}"
        return 1
    fi
}

# Add user to group
add_to_group() {
    local username="$1"
    local groupname="$2"
    
    if ! id "$username" &>/dev/null; then
        echo -e "${YELLOW}User '$username' does not exist${NC}"
        return 1
    fi
    
    if ! getent group "$groupname" &>/dev/null; then
        echo -e "${YELLOW}Group '$groupname' does not exist${NC}"
        return 1
    fi
    
    if usermod -a -G "$groupname" "$username"; then
        echo -e "${GREEN}User '$username' added to group '$groupname'${NC}"
        return 0
    else
        echo -e "${RED}Failed to add user '$username' to group '$groupname'${NC}"
        return 1
    fi
}

# Remove user from group
remove_from_group() {
    local username="$1"
    local groupname="$2"
    
    if ! id "$username" &>/dev/null; then
        echo -e "${YELLOW}User '$username' does not exist${NC}"
        return 1
    fi
    
    if gpasswd -d "$username" "$groupname"; then
        echo -e "${GREEN}User '$username' removed from group '$groupname'${NC}"
        return 0
    else
        echo -e "${RED}Failed to remove user '$username' from group '$groupname'${NC}"
        return 1
    fi
}

# List groups
list_groups() {
    echo -e "${BLUE}System Groups:${NC}"
    echo "Groupname:GID:Members"
    echo "---------------------"
    
    while IFS=: read -r groupname _ gid members; do
        # Skip system groups (typically GID < 1000) except important ones
        if [[ $gid -ge 1000 ]] || [[ "$groupname" =~ ^(root|sudo|wheel|adm|staff)$ ]]; then
            echo "$groupname:$gid:$members"
        fi
    done < /etc/group
}

# Check permissions
check_permissions() {
    local target="$1"
    
    if [[ ! -e "$target" ]]; then
        echo -e "${YELLOW}File or directory '$target' does not exist${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Permissions for: $target${NC}"
    ls -la "$target"
    
    echo -e "\n${BLUE}Detailed permissions:${NC}"
    stat "$target"
}

# Set permissions
set_permissions() {
    local target="$1"
    local perms="$2"
    
    if [[ ! -e "$target" ]]; then
        echo -e "${YELLOW}File or directory '$target' does not exist${NC}"
        return 1
    fi
    
    if chmod "$perms" "$target"; then
        echo -e "${GREEN}Permissions set to $perms for '$target'${NC}"
        check_permissions "$target"
        return 0
    else
        echo -e "${RED}Failed to set permissions for '$target'${NC}"
        return 1
    fi
}

# Show sudo users
show_sudo_users() {
    echo -e "${BLUE}Users with sudo privileges:${NC}"
    
    # Check sudo group members
    if getent group sudo &>/dev/null; then
        echo -e "${GREEN}Sudo group members:${NC}"
        getent group sudo | cut -d: -f4 | tr ',' '\n' | grep -v '^$'
    fi
    
    # Check wheel group members (common on RHEL/CentOS)
    if getent group wheel &>/dev/null; then
        echo -e "${GREEN}Wheel group members:${NC}"
        getent group wheel | cut -d: -f4 | tr ',' '\n' | grep -v '^$'
    fi
    
    # Check sudoers file for individual entries
    if [[ -f /etc/sudoers ]]; then
        echo -e "\n${BLUE}Individual sudoers entries:${NC}"
        grep -E "^[^#]*ALL=.*ALL" /etc/sudoers 2>/dev/null || echo "None found"
    fi
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "add-user")
            check_root
            [[ $# -ge 1 ]] || { echo -e "${RED}Username required${NC}"; exit 1; }
            add_user "$@"
            ;;
        "del-user")
            check_root
            [[ $# -ge 1 ]] || { echo -e "${RED}Username required${NC}"; exit 1; }
            delete_user "$@"
            ;;
        "lock-user")
            check_root
            [[ $# -ge 1 ]] || { echo -e "${RED}Username required${NC}"; exit 1; }
            lock_user "$1"
            ;;
        "unlock-user")
            check_root
            [[ $# -ge 1 ]] || { echo -e "${RED}Username required${NC}"; exit 1; }
            unlock_user "$1"
            ;;
        "passwd")
            check_root
            [[ $# -ge 1 ]] || { echo -e "${RED}Username required${NC}"; exit 1; }
            passwd "$1"
            ;;
        "list-users")
            list_users
            ;;
        "add-group")
            check_root
            [[ $# -ge 1 ]] || { echo -e "${RED}Group name required${NC}"; exit 1; }
            add_group "$1"
            ;;
        "del-group")
            check_root
            [[ $# -ge 1 ]] || { echo -e "${RED}Group name required${NC}"; exit 1; }
            delete_group "$1"
            ;;
        "add-to-group")
            check_root
            [[ $# -ge 2 ]] || { echo -e "${RED}Username and group name required${NC}"; exit 1; }
            add_to_group "$1" "$2"
            ;;
        "remove-from-group")
            check_root
            [[ $# -ge 2 ]] || { echo -e "${RED}Username and group name required${NC}"; exit 1; }
            remove_from_group "$1" "$2"
            ;;
        "list-groups")
            list_groups
            ;;
        "check-perms")
            [[ $# -ge 1 ]] || { echo -e "${RED}File/directory path required${NC}"; exit 1; }
            check_permissions "$1"
            ;;
        "set-perms")
            check_root
            [[ $# -ge 2 ]] || { echo -e "${RED}File/directory path and permissions required${NC}"; exit 1; }
            set_permissions "$1" "$2"
            ;;
        "show-sudo")
            show_sudo_users
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"