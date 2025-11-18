# NDC OLS Installation Guide

## Quick Install

### Method 1: One-line installation (Recommended):
```bash
curl -sL https://raw.githubusercontent.com/ndcviet/ndc-ols/main/install.sh | bash
```

### Method 2: Download and run:
```bash
curl -sO https://raw.githubusercontent.com/ndcviet/ndc-ols/main/install.sh
chmod +x install.sh
bash install.sh
```

### Method 3: Clone from GitHub:
```bash
git clone https://github.com/ndcviet/ndc-ols.git
cd ndc-ols
chmod +x install.sh
bash install.sh
```

## Requirements

- **Operating System**: Ubuntu 22.04/24.04, AlmaLinux 8/9, Rocky Linux 8/9
- **RAM**: Minimum 1GB (recommended 2GB+)
- **Disk Space**: Minimum 10GB free
- **Root Access**: Required

## What Gets Installed?

The installation script will automatically install:

1. **Web Server**: Nginx
2. **Runtime**: Node.js (LTS) via NVM
3. **Process Manager**: PM2
4. **Databases**:
   - PostgreSQL
   - MongoDB
   - MariaDB (MySQL)
   - Redis
5. **Security**:
   - UFW/Firewalld (Firewall)
   - Fail2ban
   - SSL (Let's Encrypt/Certbot)
6. **Tools**: Git, curl, wget, and other essentials

## Installation Steps

1. **Update System** (automatic)
2. **Install Dependencies** (automatic)
3. **Install Stack** (automatic - ~10-15 minutes)
4. **Configure Services** (automatic)
5. **Setup NDC OLS** (automatic)

## Post-Installation

After installation completes:

```bash
# Run NDC OLS
ndc

# Or
ndc-ols
```

## First Steps

1. Change SSH port (recommended)
2. Setup firewall rules
3. Configure databases
4. Deploy your first app

## Troubleshooting

### Installation failed?

```bash
# Check logs
cat /var/log/ndc-ols/install.log

# Retry installation
bash install.sh
```

### Permission issues?

```bash
# Ensure you're running as root
sudo bash install.sh
```

### Network issues?

```bash
# Check internet connection
ping -c 4 8.8.8.8

# Check DNS
nslookup google.com
```

## Manual Installation

If automatic installation fails, follow manual steps at:
https://docs.ndc-ols.com/manual-installation

## Support

- GitHub Issues: https://github.com/ndc-ols/issues
- Discord: https://discord.gg/ndc-ols
- Docs: https://docs.ndc-ols.com
