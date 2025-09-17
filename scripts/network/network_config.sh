#!/bin/bash

# Network Configuration Script
# Manage network interfaces and connections

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Show usage
show_usage() {
    echo -e "${BLUE}Network Configuration Script${NC}"
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Information Commands:"
    echo "  interfaces             List network interfaces"
    echo "  status                 Show network status"
    echo "  routes                 Show routing table"
    echo "  dns                    Show DNS configuration"
    echo "  connections            Show active connections"
    echo ""
    echo "Configuration Commands:"
    echo "  set-ip <interface> <ip> <netmask>  Set static IP"
    echo "  set-dhcp <interface>               Enable DHCP"
    echo "  add-route <dest> <gateway>         Add route"
    echo "  del-route <dest>                   Delete route"
    echo "  set-dns <server1> [server2]        Set DNS servers"
    echo ""
    echo "Control Commands:"
    echo "  up <interface>         Bring interface up"
    echo "  down <interface>       Bring interface down"
    echo "  restart <interface>    Restart interface"
    echo "  scan-wifi              Scan for WiFi networks"
    echo ""
}

# Check if running as root for configuration changes
check_root_for_config() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: Root privileges required for configuration changes${NC}"
        exit 1
    fi
}

# List network interfaces
list_interfaces() {
    echo -e "${BLUE}Network Interfaces:${NC}"
    echo "==================="
    
    if command -v ip >/dev/null 2>&1; then
        ip link show
    else
        ifconfig -a
    fi
    
    echo -e "\n${BLUE}Interface Details:${NC}"
    echo "=================="
    
    if command -v ip >/dev/null 2>&1; then
        ip addr show
    else
        ifconfig
    fi
}

# Show network status
show_status() {
    echo -e "${BLUE}Network Status Summary:${NC}"
    echo "======================"
    
    # Active interfaces
    echo -e "\n${GREEN}Active Interfaces:${NC}"
    if command -v ip >/dev/null 2>&1; then
        ip -br addr show up
    else
        ifconfig | grep -E "^[a-zA-Z].*UP"
    fi
    
    # Default gateway
    echo -e "\n${GREEN}Default Gateway:${NC}"
    if command -v ip >/dev/null 2>&1; then
        ip route show default
    else
        route -n | grep "^0.0.0.0"
    fi
    
    # DNS servers
    echo -e "\n${GREEN}DNS Servers:${NC}"
    if [[ -f /etc/resolv.conf ]]; then
        grep nameserver /etc/resolv.conf
    fi
    
    # Connectivity test
    echo -e "\n${GREEN}Connectivity Test:${NC}"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Internet connectivity: OK${NC}"
    else
        echo -e "${RED}✗ Internet connectivity: FAILED${NC}"
    fi
    
    if ping -c 1 google.com >/dev/null 2>&1; then
        echo -e "${GREEN}✓ DNS resolution: OK${NC}"
    else
        echo -e "${RED}✗ DNS resolution: FAILED${NC}"
    fi
}

# Show routing table
show_routes() {
    echo -e "${BLUE}Routing Table:${NC}"
    echo "============="
    
    if command -v ip >/dev/null 2>&1; then
        ip route show
    else
        route -n
    fi
}

# Show DNS configuration
show_dns() {
    echo -e "${BLUE}DNS Configuration:${NC}"
    echo "=================="
    
    if [[ -f /etc/resolv.conf ]]; then
        echo -e "${GREEN}/etc/resolv.conf:${NC}"
        cat /etc/resolv.conf
    fi
    
    if [[ -f /etc/systemd/resolved.conf ]]; then
        echo -e "\n${GREEN}systemd-resolved configuration:${NC}"
        grep -v "^#" /etc/systemd/resolved.conf | grep -v "^$"
    fi
    
    # Test DNS resolution
    echo -e "\n${GREEN}DNS Resolution Test:${NC}"
    if command -v nslookup >/dev/null 2>&1; then
        nslookup google.com
    elif command -v dig >/dev/null 2>&1; then
        dig google.com +short
    fi
}

# Show active connections
show_connections() {
    echo -e "${BLUE}Active Network Connections:${NC}"
    echo "=========================="
    
    if command -v ss >/dev/null 2>&1; then
        echo -e "${GREEN}Listening ports:${NC}"
        ss -tuln
        
        echo -e "\n${GREEN}Established connections:${NC}"
        ss -tun state established
    else
        echo -e "${GREEN}All connections:${NC}"
        netstat -tuln
    fi
}

# Set static IP
set_static_ip() {
    check_root_for_config
    local interface="$1"
    local ip_addr="$2"
    local netmask="$3"
    
    echo -e "${BLUE}Setting static IP on $interface: $ip_addr/$netmask${NC}"
    
    if command -v ip >/dev/null 2>&1; then
        # Modern approach with ip command
        ip addr flush dev "$interface"
        ip addr add "$ip_addr/$netmask" dev "$interface"
        ip link set "$interface" up
    else
        # Legacy approach with ifconfig
        ifconfig "$interface" "$ip_addr" netmask "$netmask" up
    fi
    
    echo -e "${GREEN}Static IP configured successfully${NC}"
    
    # Show result
    if command -v ip >/dev/null 2>&1; then
        ip addr show "$interface"
    else
        ifconfig "$interface"
    fi
}

# Enable DHCP
set_dhcp() {
    check_root_for_config
    local interface="$1"
    
    echo -e "${BLUE}Enabling DHCP on $interface${NC}"
    
    # Try different DHCP clients
    if command -v dhclient >/dev/null 2>&1; then
        dhclient "$interface"
    elif command -v dhcpcd >/dev/null 2>&1; then
        dhcpcd "$interface"
    elif command -v pump >/dev/null 2>&1; then
        pump -i "$interface"
    else
        echo -e "${RED}No DHCP client found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}DHCP enabled successfully${NC}"
    
    # Show result
    sleep 3
    if command -v ip >/dev/null 2>&1; then
        ip addr show "$interface"
    else
        ifconfig "$interface"
    fi
}

# Add route
add_route() {
    check_root_for_config
    local destination="$1"
    local gateway="$2"
    
    echo -e "${BLUE}Adding route: $destination via $gateway${NC}"
    
    if command -v ip >/dev/null 2>&1; then
        ip route add "$destination" via "$gateway"
    else
        route add -net "$destination" gw "$gateway"
    fi
    
    echo -e "${GREEN}Route added successfully${NC}"
    show_routes
}

# Delete route
delete_route() {
    check_root_for_config
    local destination="$1"
    
    echo -e "${BLUE}Deleting route: $destination${NC}"
    
    if command -v ip >/dev/null 2>&1; then
        ip route del "$destination"
    else
        route del -net "$destination"
    fi
    
    echo -e "${GREEN}Route deleted successfully${NC}"
    show_routes
}

# Set DNS servers
set_dns() {
    check_root_for_config
    local dns1="$1"
    local dns2="${2:-}"
    
    echo -e "${BLUE}Setting DNS servers: $dns1 ${dns2:+$dns2}${NC}"
    
    # Backup current resolv.conf
    cp /etc/resolv.conf /etc/resolv.conf.backup
    
    # Create new resolv.conf
    {
        echo "# Generated by network configuration script"
        echo "nameserver $dns1"
        [[ -n "$dns2" ]] && echo "nameserver $dns2"
    } > /etc/resolv.conf
    
    echo -e "${GREEN}DNS servers configured successfully${NC}"
    show_dns
}

# Bring interface up
interface_up() {
    check_root_for_config
    local interface="$1"
    
    echo -e "${BLUE}Bringing up interface: $interface${NC}"
    
    if command -v ip >/dev/null 2>&1; then
        ip link set "$interface" up
    else
        ifconfig "$interface" up
    fi
    
    echo -e "${GREEN}Interface $interface is now up${NC}"
}

# Bring interface down
interface_down() {
    check_root_for_config
    local interface="$1"
    
    echo -e "${BLUE}Bringing down interface: $interface${NC}"
    
    if command -v ip >/dev/null 2>&1; then
        ip link set "$interface" down
    else
        ifconfig "$interface" down
    fi
    
    echo -e "${GREEN}Interface $interface is now down${NC}"
}

# Restart interface
restart_interface() {
    local interface="$1"
    
    interface_down "$interface"
    sleep 2
    interface_up "$interface"
}

# Scan for WiFi networks
scan_wifi() {
    echo -e "${BLUE}Scanning for WiFi networks...${NC}"
    
    if command -v iwlist >/dev/null 2>&1; then
        # Find wireless interfaces
        local wifi_interfaces
        wifi_interfaces=$(iwconfig 2>/dev/null | grep "IEEE 802.11" | cut -d' ' -f1 || echo "")
        
        if [[ -z "$wifi_interfaces" ]]; then
            echo -e "${YELLOW}No wireless interfaces found${NC}"
            return 1
        fi
        
        for interface in $wifi_interfaces; do
            echo -e "${GREEN}Scanning on $interface:${NC}"
            iwlist "$interface" scan | grep -E "(ESSID|Signal|Encryption)" || true
        done
    else
        echo -e "${RED}iwlist command not found - install wireless-tools${NC}"
        return 1
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
        "interfaces")
            list_interfaces
            ;;
        "status")
            show_status
            ;;
        "routes")
            show_routes
            ;;
        "dns")
            show_dns
            ;;
        "connections")
            show_connections
            ;;
        "set-ip")
            [[ $# -ge 3 ]] || { echo -e "${RED}Interface, IP, and netmask required${NC}"; exit 1; }
            set_static_ip "$1" "$2" "$3"
            ;;
        "set-dhcp")
            [[ $# -ge 1 ]] || { echo -e "${RED}Interface required${NC}"; exit 1; }
            set_dhcp "$1"
            ;;
        "add-route")
            [[ $# -ge 2 ]] || { echo -e "${RED}Destination and gateway required${NC}"; exit 1; }
            add_route "$1" "$2"
            ;;
        "del-route")
            [[ $# -ge 1 ]] || { echo -e "${RED}Destination required${NC}"; exit 1; }
            delete_route "$1"
            ;;
        "set-dns")
            [[ $# -ge 1 ]] || { echo -e "${RED}At least one DNS server required${NC}"; exit 1; }
            set_dns "$@"
            ;;
        "up")
            [[ $# -ge 1 ]] || { echo -e "${RED}Interface required${NC}"; exit 1; }
            interface_up "$1"
            ;;
        "down")
            [[ $# -ge 1 ]] || { echo -e "${RED}Interface required${NC}"; exit 1; }
            interface_down "$1"
            ;;
        "restart")
            [[ $# -ge 1 ]] || { echo -e "${RED}Interface required${NC}"; exit 1; }
            restart_interface "$1"
            ;;
        "scan-wifi")
            scan_wifi
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"