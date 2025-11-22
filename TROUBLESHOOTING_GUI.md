# 🔧 Troubleshooting Database GUI Access

## ❌ Cannot Access Mongo Express (Port 8081) or pgAdmin (Port 5050)

### Problem
```powershell
PS C:\> ping http://103.221.223.164:8081
Ping request could not find host http://103.221.223.164:8081
```

### ⚠️ Common Mistakes

#### 1. Wrong Command - Cannot Ping HTTP URLs
**DON'T DO THIS:**
```powershell
❌ ping http://103.221.223.164:8081
❌ ping https://yourdomain.com
```

**DO THIS INSTEAD:**
```powershell
✅ Test with browser: http://103.221.223.164:8081
✅ Test with curl: curl http://103.221.223.164:8081
✅ Ping IP only: ping 103.221.223.164
```

---

## 🔍 Root Cause Analysis

### Default Security Configuration
By default, NDC-OLS installs database GUIs in **SECURE MODE**:

| Service | Default Binding | Default Port | External Access |
|---------|----------------|--------------|-----------------|
| Mongo Express | `localhost` (127.0.0.1) | 8081 | ❌ NO |
| pgAdmin 4 | `localhost` (127.0.0.1) | 5050 | ❌ NO |

**Why?** 
- Security best practice: Don't expose database admin tools to internet
- Encourages use of SSH tunnels (encrypted)
- Protects against unauthorized access

---

## ✅ Solutions (3 Methods)

### Method 1: SSH Tunnel (RECOMMENDED ⭐⭐⭐⭐⭐)

**Most Secure - Use this for production!**

#### Windows PowerShell/CMD:
```powershell
# Mongo Express (Port 8081)
ssh -L 8081:localhost:8081 root@103.221.223.164

# pgAdmin 4 (Port 5050)
ssh -L 5050:localhost:5050 root@103.221.223.164
```

**Then open browser:**
- Mongo Express: http://localhost:8081
- pgAdmin 4: http://localhost:5050

#### Windows PuTTY:
1. Open PuTTY
2. Session → Host: `103.221.223.164`
3. Connection → SSH → Tunnels
4. Source port: `8081` (for Mongo Express) or `5050` (for pgAdmin)
5. Destination: `localhost:8081` or `localhost:5050`
6. Click "Add"
7. Click "Open" and login
8. Browser: http://localhost:8081 or http://localhost:5050

#### macOS/Linux:
```bash
# Mongo Express
ssh -L 8081:localhost:8081 root@103.221.223.164

# pgAdmin 4
ssh -L 5050:localhost:5050 root@103.221.223.164
```

**Advantages:**
- ✅ Fully encrypted (SSH)
- ✅ No ports exposed to internet
- ✅ No firewall changes needed
- ✅ Most secure option

**Disadvantages:**
- ⚠️ Requires SSH access
- ⚠️ Must keep terminal open

---

### Method 2: Enable Web Access (QUICK TEST ⭐⭐⭐)

**Only for testing or internal networks!**

#### Steps:
```bash
# SSH to your VPS
ssh root@103.221.223.164

# Run NDC-OLS
ndc

# Select option: 3) GUI Database Admin

# For Mongo Express:
# → 2) Enable Web Access (Port 8081)

# For pgAdmin 4:
# → 12) Enable Web Access (Port 5050)
```

**What it does:**
- Changes binding from `localhost` → `0.0.0.0`
- Opens firewall ports (8081/5050)
- Allows external access

**Then access:**
- Mongo Express: http://103.221.223.164:8081
- pgAdmin 4: http://103.221.223.164:5050

**Advantages:**
- ✅ Easy to access
- ✅ No SSH tunnel needed
- ✅ Works from anywhere

**Disadvantages:**
- ⚠️ Port exposed to internet
- ⚠️ HTTP only (not encrypted)
- ⚠️ Vulnerable to attacks
- ⚠️ **NOT recommended for production**

---

### Method 3: Domain + SSL (PRODUCTION ⭐⭐⭐⭐⭐)

**Best for production with custom domain**

#### Prerequisites:
- Domain name pointed to your VPS (A record)
- Example: `db.yourdomain.com` → `103.221.223.164`

#### Steps:
```bash
# SSH to VPS
ssh root@103.221.223.164

# Run NDC-OLS
ndc

# Select: 3) GUI Database Admin

# For Mongo Express:
# → 4) Secure with Domain + SSL
# Enter domain: db.yourdomain.com
# Enter email: your@email.com

# For pgAdmin:
# → 14) Secure with Domain + SSL
# Enter domain: pgadmin.yourdomain.com
# Enter email: your@email.com
```

**What it does:**
- Sets up Nginx reverse proxy
- Gets free SSL certificate (Let's Encrypt)
- Auto-renews certificate
- HTTPS encryption

**Access:**
- Mongo Express: https://db.yourdomain.com
- pgAdmin 4: https://pgadmin.yourdomain.com

**Advantages:**
- ✅ HTTPS encrypted
- ✅ Professional looking
- ✅ Auto SSL renewal
- ✅ Custom domain
- ✅ Production ready

**Disadvantages:**
- ⚠️ Requires domain name
- ⚠️ DNS setup needed
- ⚠️ Port still exposed (but encrypted)

---

## 🔍 Diagnostic Commands

### Check if Services are Running

```bash
# SSH to VPS first
ssh root@103.221.223.164

# Check Mongo Express
pm2 list | grep mongo-express
pm2 logs mongo-express --lines 20

# Check pgAdmin 4
systemctl status pgadmin4
journalctl -u pgadmin4 -n 20

# Check MongoDB
systemctl status mongod

# Check PostgreSQL
systemctl status postgresql
```

### Check Port Binding

```bash
# What ports are listening?
netstat -tlnp | grep -E '8081|5050'

# Expected output for SECURE mode (localhost only):
tcp  0  0  127.0.0.1:8081  0.0.0.0:*  LISTEN  12345/node
tcp  0  0  127.0.0.1:5050  0.0.0.0:*  LISTEN  67890/python

# Expected output for WEB mode (public access):
tcp  0  0  0.0.0.0:8081    0.0.0.0:*  LISTEN  12345/node
tcp  0  0  0.0.0.0:5050    0.0.0.0:*  LISTEN  67890/python
```

### Check Firewall

```bash
# Ubuntu/Debian
sudo ufw status | grep -E '8081|5050'

# AlmaLinux/Rocky
sudo firewall-cmd --list-ports | grep -E '8081|5050'
```

### Test from VPS Localhost

```bash
# Test Mongo Express
curl http://localhost:8081

# Test pgAdmin
curl http://localhost:5050

# If these work, services are running but not accessible externally
```

---

## 🛠️ Quick Fix Script

Save this as `test-gui-access.sh` on your VPS:

```bash
#!/bin/bash

echo "=== Database GUI Access Diagnostic ==="
echo ""

# Check Mongo Express
echo "1. Mongo Express Status:"
if pm2 list | grep -q "mongo-express"; then
    echo "   ✅ Running"
    pm2 info mongo-express | grep -E 'status|mode'
else
    echo "   ❌ Not running"
fi
echo ""

# Check pgAdmin 4
echo "2. pgAdmin 4 Status:"
if systemctl is-active --quiet pgadmin4; then
    echo "   ✅ Running"
    systemctl status pgadmin4 | grep Active
else
    echo "   ❌ Not running"
fi
echo ""

# Check port binding
echo "3. Port Binding:"
netstat -tlnp | grep -E '8081|5050' || echo "   No ports listening"
echo ""

# Check firewall
echo "4. Firewall Status:"
if command -v ufw >/dev/null 2>&1; then
    ufw status | grep -E '8081|5050' || echo "   Ports not open"
elif command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --list-ports | grep -E '8081|5050' || echo "   Ports not open"
fi
echo ""

# Check credentials
echo "5. Credentials:"
if [ -f /etc/ndc-ols/auth.conf ]; then
    source /etc/ndc-ols/auth.conf
    echo "   Mongo Express User: $MONGO_EXPRESS_USER"
    echo "   Mongo Express Pass: $MONGO_EXPRESS_PASS"
    echo "   pgAdmin Email: $PGADMIN_EMAIL"
    echo "   pgAdmin Pass: $PGADMIN_PASS"
else
    echo "   ❌ Credentials file not found"
fi
echo ""

# Test localhost access
echo "6. Localhost Access Test:"
if curl -s http://localhost:8081 >/dev/null 2>&1; then
    echo "   ✅ Mongo Express accessible on localhost"
else
    echo "   ❌ Mongo Express NOT accessible"
fi

if curl -s http://localhost:5050 >/dev/null 2>&1; then
    echo "   ✅ pgAdmin accessible on localhost"
else
    echo "   ❌ pgAdmin NOT accessible"
fi
echo ""

echo "=== Recommendation ==="
echo "If services are running but not accessible externally:"
echo "1. Use SSH tunnel (most secure)"
echo "2. Or enable web access: ndc → 3 → 2 (Mongo Express)"
echo "3. Or enable web access: ndc → 3 → 12 (pgAdmin)"
```

Run it:
```bash
chmod +x test-gui-access.sh
./test-gui-access.sh
```

---

## 📖 Step-by-Step Guide for Your Case

### Your VPS IP: `103.221.223.164`

#### Option A: SSH Tunnel (Recommended)

**Windows:**
```powershell
# Open PowerShell and run:
ssh -L 8081:localhost:8081 root@103.221.223.164

# Keep terminal open, then open browser:
# http://localhost:8081
```

**For pgAdmin:**
```powershell
ssh -L 5050:localhost:5050 root@103.221.223.164
# Browser: http://localhost:5050
```

#### Option B: Enable Web Access

**On your VPS:**
```bash
# SSH first
ssh root@103.221.223.164

# Run NDC-OLS
ndc

# Select: 3) GUI Database Admin
# Select: 2) Enable Web Access (Port 8081)  # For Mongo Express
# Select: 12) Enable Web Access (Port 5050) # For pgAdmin

# Then access from browser:
# http://103.221.223.164:8081  (Mongo Express)
# http://103.221.223.164:5050  (pgAdmin)
```

---

## 🔐 Get Your Login Credentials

```bash
# SSH to VPS
ssh root@103.221.223.164

# Show all credentials
ndc
# → 3) GUI Database Admin
# → 22) Show All Database GUI Credentials

# Or view file directly
cat /etc/ndc-ols/auth.conf
```

---

## 🎯 Summary

### Why can't you access the GUIs?

1. **Default = Secure Mode**
   - Binds to `localhost` (127.0.0.1)
   - Not accessible from internet
   - Firewall ports closed

2. **You need to choose access method:**
   - SSH Tunnel (secure, recommended)
   - Enable Web Access (quick, less secure)
   - Domain + SSL (production, secure)

### Quick Start (Right Now!)

**Fastest way to access:**
```powershell
# On your Windows PC:
ssh -L 8081:localhost:8081 -L 5050:localhost:5050 root@103.221.223.164

# Browser:
# Mongo Express: http://localhost:8081
# pgAdmin: http://localhost:5050
```

**Get credentials:**
```bash
# On VPS (in another terminal):
cat /etc/ndc-ols/auth.conf
```

---

## ❓ FAQ

**Q: Why can't I ping the URL?**
A: `ping` command doesn't support HTTP/HTTPS URLs. Use browser or `curl` instead.

**Q: Is it safe to enable web access?**
A: For testing on internal networks: Yes. For production: No. Use SSH tunnel or Domain+SSL.

**Q: Do I need to enable web access every time?**
A: No. Once enabled, it stays enabled until you disable it.

**Q: Can I use both SSH tunnel and web access?**
A: Yes! Web access just makes it available on both localhost and public IP.

**Q: How do I disable web access?**
A: `ndc → 3 → 3` (Mongo Express) or `ndc → 3 → 13` (pgAdmin)

---

**Need more help?**
- Run diagnostic script above
- Check service logs: `pm2 logs mongo-express` or `journalctl -u pgadmin4`
- Open GitHub issue: https://github.com/nguyendc-hp/ndc-ols/issues
