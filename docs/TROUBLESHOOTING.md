# NDC OLS Troubleshooting Guide

## Installation Issues

### 1. Installation Script Fails

**Problem:** `install.sh` exits with error

**Solutions:**

```bash
# Check if running as root
whoami  # Should output: root

# If not root
sudo su

# Check internet connection
ping -c 4 8.8.8.8

# Check disk space
df -h  # Need at least 10GB free

# View installation log
cat /var/log/ndc-ols/install.log
```

### 2. Permission Denied

**Problem:** Permission denied errors

**Solutions:**

```bash
# Ensure install.sh is executable
chmod +x install.sh

# Run with sudo
sudo bash install.sh
```

### 3. Package Manager Issues

**Ubuntu:**
```bash
apt update
apt upgrade -y
```

**AlmaLinux/Rocky:**
```bash
dnf update -y
dnf clean all
```

## App Deployment Issues

### 1. App Won't Start

**Problem:** PM2 app shows error status

**Solutions:**

```bash
# View detailed logs
pm2 logs appname --lines 100

# Check if port is in use
netstat -tulpn | grep :3000

# Kill process on port
kill -9 $(lsof -t -i:3000)

# Restart app
pm2 restart appname
```

### 2. "Module not found" Error

**Problem:** App crashes with missing modules

**Solutions:**

```bash
# Navigate to app directory
cd /var/www/appname

# Reinstall dependencies
npm install

# Clear npm cache
npm cache clean --force

# Restart
pm2 restart appname
```

### 3. Build Errors

**Problem:** `npm run build` fails

**Solutions:**

```bash
# Check Node version
node -v

# Switch Node version
nvm use 18  # or 20

# Clear cache and rebuild
rm -rf node_modules package-lock.json
npm install
npm run build
```

## Domain & SSL Issues

### 1. Domain Not Working

**Problem:** Domain shows 502/404 error

**Solutions:**

```bash
# Test Nginx config
nginx -t

# Check if Nginx is running
systemctl status nginx

# View Nginx error log
tail -f /var/log/nginx/error.log

# Check domain config
cat /etc/nginx/sites-available/yourdomain.com

# Reload Nginx
systemctl reload nginx
```

### 2. SSL Installation Fails

**Problem:** Certbot fails to issue certificate

**Solutions:**

```bash
# Ensure domain points to VPS IP
dig yourdomain.com +short

# Check port 80 is open
netstat -tulpn | grep :80

# Try manual certbot
certbot --nginx -d yourdomain.com

# Check certbot logs
cat /var/log/letsencrypt/letsencrypt.log
```

### 3. SSL Expired

**Problem:** SSL certificate expired

**Solutions:**

```bash
# Renew all certificates
certbot renew

# Force renewal
certbot renew --force-renewal

# Setup auto-renewal (cron)
crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Database Issues

### 1. Can't Connect to PostgreSQL

**Problem:** Connection refused

**Solutions:**

```bash
# Check if PostgreSQL is running
systemctl status postgresql

# Start PostgreSQL
systemctl start postgresql

# Check logs
tail -f /var/log/postgresql/postgresql-*.log

# Test connection
psql -U postgres
```

### 2. MongoDB Won't Start

**Problem:** MongoDB service fails

**Solutions:**

```bash
# Check status
systemctl status mongod

# View logs
tail -f /var/log/mongodb/mongod.log

# Fix permissions
chown -R mongodb:mongodb /var/lib/mongodb
chown mongodb:mongodb /tmp/mongodb-27017.sock

# Restart
systemctl restart mongod
```

### 3. MySQL/MariaDB Issues

**Problem:** Access denied

**Solutions:**

```bash
# Reset root password
systemctl stop mariadb
mysqld_safe --skip-grant-tables &
mysql -u root
# In MySQL:
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'newpassword';
FLUSH PRIVILEGES;
exit;
# Kill mysqld_safe and restart
systemctl restart mariadb
```

## PM2 Issues

### 1. PM2 Apps Lost After Reboot

**Problem:** Apps don't auto-start

**Solutions:**

```bash
# Save current PM2 list
pm2 save

# Setup startup script
pm2 startup

# Execute command shown by PM2

# Verify
pm2 list
```

### 2. Memory Issues

**Problem:** Apps consuming too much memory

**Solutions:**

```bash
# Check memory usage
pm2 monit

# Set memory limit in ecosystem.config.js
max_memory_restart: '500M'

# Restart with new config
pm2 restart ecosystem.config.js
```

## Firewall Issues

### 1. Can't Access Port

**Problem:** Port blocked by firewall

**Solutions:**

```bash
# Ubuntu (UFW)
ufw allow 3000
ufw status

# AlmaLinux/Rocky (Firewalld)
firewall-cmd --add-port=3000/tcp --permanent
firewall-cmd --reload
```

### 2. Fail2ban Blocking Your IP

**Problem:** Can't access server

**Solutions:**

```bash
# Check if IP is banned
fail2ban-client status sshd

# Unban your IP
fail2ban-client set sshd unbanip YOUR_IP

# Whitelist your IP
nano /etc/fail2ban/jail.local
# Add: ignoreip = 127.0.0.1/8 YOUR_IP
```

## Performance Issues

### 1. Server Running Slow

**Solutions:**

```bash
# Check CPU/Memory
top
htop

# Check disk usage
df -h
du -sh /var/* | sort -rh | head -10

# Check running processes
ps aux | grep node

# Clean old logs
find /var/log -type f -name "*.log" -mtime +30 -delete
```

### 2. Nginx Performance

**Solutions:**

```bash
# Enable gzip in /etc/nginx/nginx.conf
gzip on;
gzip_types text/plain text/css application/json;

# Increase worker_connections
worker_connections 1024;

# Reload Nginx
systemctl reload nginx
```

## Backup Issues

### 1. Backup Fails

**Problem:** Backup script errors

**Solutions:**

```bash
# Check disk space
df -h /var/backups

# Check permissions
ls -la /var/backups

# Fix permissions
chown -R root:root /var/backups
chmod 755 /var/backups

# Manual backup
ndc
# → 5) Backup & Restore
# → 1) Backup app
```

### 2. Can't Restore Backup

**Problem:** Restore fails

**Solutions:**

```bash
# List backups
ls -lh /var/backups/

# Check backup integrity
tar -tzf /var/backups/appname-*.tar.gz

# Manual restore
cd /var/www
tar -xzf /var/backups/appname-YYYYMMDD-HHMMSS.tar.gz
```

## Getting Help

If issues persist:

1. **Check logs:** `/var/log/ndc-ols/`
2. **GitHub Issues:** https://github.com/ndc-ols/issues
3. **Discord:** https://discord.gg/ndc-ols
4. **Email:** support@ndc-ols.com

When reporting issues, include:
- OS version: `cat /etc/os-release`
- NDC OLS version
- Error messages
- Relevant logs
