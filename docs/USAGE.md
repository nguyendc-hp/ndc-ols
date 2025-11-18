# NDC OLS Usage Guide

## Getting Started

### Run NDC OLS

```bash
ndc
```

This opens the main menu with 30 options.

## Common Tasks

### 1. Deploy a React App

```bash
ndc
# Select: 6) Deploy New App
# Choose: 1) React (Vite)
# Enter app name: myapp
# Enter domain: myapp.com
```

### 2. Deploy a Node.js API

```bash
ndc
# Select: 6) Deploy New App
# Choose: 4) Express.js API
# Enter app name: api
# Enter domain: api.myapp.com
# Enter port: 3000
```

### 3. Setup SSL

```bash
ndc
# Select: 3) Quản lý SSL
# Select: 1) Install SSL for domain
# Enter domain: myapp.com
# Enter email: you@email.com
```

### 4. Create Database

#### PostgreSQL:
```bash
ndc
# Select: 4) Quản lý Database
# Select: 1) PostgreSQL Manager
# Select: 2) Create database
```

#### MongoDB:
```bash
ndc
# Select: 4) Quản lý Database
# Select: 2) MongoDB Manager
# Select: 2) Create database & user
```

### 5. Backup App

```bash
ndc
# Select: 5) Backup & Restore
# Select: 1) Backup app
# Enter app name
```

### 6. View Logs

```bash
ndc
# Select: 15) Logs Management
# Select: 1) View PM2 logs
```

### 7. Manage PM2 Processes

```bash
ndc
# Select: 7) Quản lý Services (PM2)
# Select: 1) PM2 list
```

## Tips & Tricks

### Quick Commands

```bash
# View all apps
pm2 list

# Restart all apps
pm2 restart all

# View logs
pm2 logs

# Monitor resources
pm2 monit
```

### Check System Info

```bash
ndc
# Select: 21) Thông tin Server
```

### Firewall Management

```bash
# Open custom port
ndc
# Select: 8) Firewall & IP Management
# Select: 7) Open port
# Enter port number
```

## Advanced Usage

### Custom Nginx Config

```bash
# Edit domain config
nano /etc/nginx/sites-available/yourdomain.com

# Test config
nginx -t

# Reload nginx
systemctl reload nginx
```

### Custom PM2 Config

Create `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'myapp',
    script: './server.js',
    instances: 2,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
```

Start with:
```bash
pm2 start ecosystem.config.js
pm2 save
```

### Auto Backup Setup

```bash
ndc
# Select: 5) Backup & Restore
# Select: 5) Setup auto backup schedule
# Choose schedule (daily/weekly)
```

### Cloud Backup

```bash
ndc
# Select: 5) Backup & Restore
# Select: 6) Cloud backup setup (Rclone)
# Configure your cloud storage
```

## Troubleshooting

### App not starting?

```bash
# Check PM2 logs
pm2 logs appname

# Check PM2 status
pm2 status
```

### Domain not working?

```bash
# Test Nginx config
nginx -t

# Check Nginx logs
tail -f /var/log/nginx/error.log
```

### Database connection issues?

```bash
# Check database status
systemctl status postgresql
systemctl status mongod
systemctl status mariadb
```

## Best Practices

1. **Always backup before major changes**
2. **Use SSL for all domains**
3. **Keep system updated**
4. **Monitor logs regularly**
5. **Setup auto backups**
6. **Use environment variables for secrets**
7. **Enable firewall**
8. **Change default SSH port**

## More Help

- Documentation: https://docs.ndc-ols.com
- GitHub: https://github.com/ndc-ols
- Discord: https://discord.gg/ndc-ols
