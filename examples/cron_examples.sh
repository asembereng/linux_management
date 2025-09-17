#!/bin/bash
# Example cron job setup for Linux management scripts

# Add these entries to your crontab with: crontab -e

# System monitoring every 5 minutes
# */5 * * * * /path/to/linux_management/scripts/system/system_monitor.sh

# Daily system backup at 2 AM
# 0 2 * * * /path/to/linux_management/scripts/backup/backup_system.sh -s -c

# Weekly log analysis on Sundays at 3 AM  
# 0 3 * * 0 /path/to/linux_management/scripts/logs/log_analyzer.sh -s > /var/log/weekly_log_summary.txt

# Daily security audit at 1 AM
# 0 1 * * * /path/to/linux_management/scripts/security/security_hardening.sh audit

# Example: Monitor specific service every minute
# * * * * * /path/to/linux_management/scripts/services/service_manager.sh status nginx || /path/to/linux_management/scripts/services/service_manager.sh start nginx