# Installation and Setup Guide

## Prerequisites

Before using these scripts, ensure you have:

1. **Root/sudo access** for system-level operations
2. **Basic command-line tools** installed:
   - bash (version 4.0+)
   - common utilities: grep, awk, sed, find
   - bc (for calculations) - will be auto-installed if missing

## Installation

1. **Clone or download** the repository:
   ```bash
   git clone <repository-url>
   cd linux_management
   ```

2. **Make scripts executable** (if not already):
   ```bash
   chmod +x scripts/**/*.sh
   ```

3. **Create log directories** (optional):
   ```bash
   sudo mkdir -p /var/log
   sudo mkdir -p /backup
   ```

## Script Categories

### System Scripts (`scripts/system/`)
- `system_info.sh` - Display comprehensive system information
- `system_monitor.sh` - Monitor system resources with alerts

### Package Management (`scripts/packages/`)
- `package_manager.sh` - Unified package management interface

### Service Management (`scripts/services/`)
- `service_manager.sh` - Manage system services

### Backup Tools (`scripts/backup/`)
- `backup_system.sh` - System backup with compression

### Log Management (`scripts/logs/`)
- `log_analyzer.sh` - Analyze system logs

### User Management (`scripts/users/`)
- `user_manager.sh` - Manage users, groups, and permissions

### Network Tools (`scripts/network/`)
- `network_config.sh` - Network configuration and monitoring

### Security Tools (`scripts/security/`)
- `security_hardening.sh` - Security audit and hardening

## Configuration

Edit configuration files in the `config/` directory:
- `system_monitor.conf` - Monitoring thresholds
- `backup.conf` - Backup settings

## Automation

See `examples/cron_examples.sh` for automated scheduling examples.

## Safety Notes

- **Always test in a non-production environment first**
- **Backup important configurations before making changes**
- **Review scripts before running with root privileges**
- **Check logs in `/var/log/` for operation details**