# Quick Start Guide - NDC OLS

## 5-Minute Setup

### 1. SSH to Your VPS

```bash
ssh root@your-vps-ip
```

### 2. Install NDC OLS (One Command!)

```bash
curl -sL https://raw.githubusercontent.com/nguyendc-hp/ndc-ols/main/install.sh | bash
```

**That's it!** Installation takes 10-15 minutes automatically.

### 3. Run NDC OLS

```bash
ndc
```

## Quick Deploy Example

### Deploy React App:

```bash
ndc
# → 6) Deploy New App
# → 1) React (Vite)
# → App name: myapp
# → Domain: myapp.com
```

### Add SSL:

```bash
ndc
# → 3) Quản lý SSL
# → 1) Install SSL
# → Domain: myapp.com
# → Email: you@email.com
```

**Done!** Your app is live at https://myapp.com

## What You Got:

✅ Nginx web server  
✅ Node.js (LTS)  
✅ PM2 process manager  
✅ PostgreSQL + MongoDB + MySQL + Redis  
✅ Free SSL (Let's Encrypt)  
✅ Firewall configured  
✅ Auto backup system  

## Common Commands:

```bash
ndc               # Open menu
pm2 list          # List apps
pm2 logs myapp    # View logs
nginx -t          # Test nginx config
```

## Need Help?

📖 [Full Installation Guide](docs/INSTALLATION.md)  
📘 [Usage Guide](docs/USAGE.md)  
🐛 [Report Issues](https://github.com/ndc-ols/issues)
