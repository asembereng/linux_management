#!/bin/bash
# Example usage scenarios for Linux management scripts

echo "=== Linux Management Scripts - Usage Examples ==="

# 1. System Information and Monitoring
echo "1. Get comprehensive system information:"
echo "./scripts/system/system_info.sh"
echo ""

echo "2. Monitor system resources with custom thresholds:"
echo "./scripts/system/system_monitor.sh 75 80 85"
echo ""

# 2. Package Management
echo "3. Update all packages:"
echo "./scripts/packages/package_manager.sh update"
echo "./scripts/packages/package_manager.sh upgrade"
echo ""

echo "4. Install multiple packages:"
echo "./scripts/packages/package_manager.sh install nginx"
echo "./scripts/packages/package_manager.sh install mysql-server"
echo ""

# 3. Service Management
echo "5. Manage services:"
echo "./scripts/services/service_manager.sh status nginx"
echo "./scripts/services/service_manager.sh restart apache2"
echo "./scripts/services/service_manager.sh enable mysql"
echo ""

# 4. Backup Operations
echo "6. Backup system directories:"
echo "./scripts/backup/backup_system.sh -s -c"
echo ""

echo "7. Backup specific directory with compression:"
echo "./scripts/backup/backup_system.sh -c -d /backup/custom /home/user"
echo ""

# 5. Log Analysis
echo "8. Analyze logs for errors in the last 24 hours:"
echo "./scripts/logs/log_analyzer.sh -e -d $(date +%Y-%m-%d)"
echo ""

echo "9. Search for specific patterns in logs:"
echo "./scripts/logs/log_analyzer.sh -p 'ssh' -t 100"
echo ""

# 6. User Management
echo "10. User and group management:"
echo "./scripts/users/user_manager.sh add-user newuser"
echo "./scripts/users/user_manager.sh add-group developers"
echo "./scripts/users/user_manager.sh add-to-group newuser developers"
echo ""

# 7. Network Configuration
echo "11. Network status and configuration:"
echo "./scripts/network/network_config.sh status"
echo "./scripts/network/network_config.sh interfaces"
echo ""

echo "12. Set static IP (requires root):"
echo "sudo ./scripts/network/network_config.sh set-ip eth0 192.168.1.100 255.255.255.0"
echo ""

# 8. Security Hardening
echo "13. Security audit and hardening:"
echo "./scripts/security/security_hardening.sh audit"
echo "sudo ./scripts/security/security_hardening.sh harden"
echo ""

echo "14. SSH hardening (requires root):"
echo "sudo ./scripts/security/security_hardening.sh ssh-harden"
echo ""

echo "=== End of Examples ==="