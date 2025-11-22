# 🔍 How to Test Database GUI Access (Correct Way)

## ❌ WRONG - Cannot Ping HTTP URLs

**DON'T DO THIS:**
```powershell
❌ ping http://103.221.223.164:8081
❌ ping https://yoursite.com
```

**Why it fails:**
- `ping` command only works with IP addresses or hostnames
- `ping` uses ICMP protocol, NOT HTTP/HTTPS
- `ping` cannot test web services on specific ports

---

## ✅ CORRECT - How to Test Web Services

### Method 1: Browser Test (Easiest)

**Just open your browser:**
```
http://103.221.223.164:8081  (Mongo Express)
http://103.221.223.164:5050  (pgAdmin 4)
```

**What to expect:**
- ✅ Login page appears → Service is working
- ❌ "Site can't be reached" → Service not accessible
- ❌ "Connection refused" → Port not open or service not running
- ❌ "Connection timeout" → Firewall blocking

---

### Method 2: curl Command

**Windows PowerShell:**
```powershell
# Test Mongo Express
curl http://103.221.223.164:8081

# Test pgAdmin
curl http://103.221.223.164:5050
```

**Linux/macOS:**
```bash
curl -I http://103.221.223.164:8081
curl -I http://103.221.223.164:5050
```

**Expected output:**
```
HTTP/1.1 200 OK
or
HTTP/1.1 401 Unauthorized (means service is running, needs login)
```

**Error output:**
```
curl: (7) Failed to connect → Service not accessible
curl: (28) Connection timed out → Firewall blocking
```

---

### Method 3: Test-NetConnection (PowerShell)

**Windows PowerShell (Best for Windows):**
```powershell
# Test port 8081 (Mongo Express)
Test-NetConnection -ComputerName 103.221.223.164 -Port 8081

# Test port 5050 (pgAdmin)
Test-NetConnection -ComputerName 103.221.223.164 -Port 5050
```

**Expected output:**
```
TcpTestSucceeded : True  ← Port is open ✅
TcpTestSucceeded : False ← Port is closed ❌
```

---

### Method 4: telnet (Any OS)

```bash
# Test Mongo Express
telnet 103.221.223.164 8081

# Test pgAdmin
telnet 103.221.223.164 5050
```

**Success:** Black screen or gibberish text = Connected ✅  
**Failure:** "Connection refused" = Port closed ❌

---

## 🐛 Debugging - Check on VPS

### Step 1: Check if Services are Running

```bash
# SSH to VPS
ssh root@103.221.223.164

# Check Mongo Express (PM2)
pm2 list
pm2 logs mongo-express --lines 50

# Check pgAdmin (systemd)
systemctl status pgadmin4
journalctl -u pgadmin4 -n 50

# Check if processes are listening
netstat -tlnp | grep -E '8081|5050'
# or
ss -tlnp | grep -E '8081|5050'
```

**Expected output:**
```bash
# Mongo Express should show:
tcp  0  0  0.0.0.0:8081  0.0.0.0:*  LISTEN  1234/node

# pgAdmin should show:
tcp  0  0  0.0.0.0:5050  0.0.0.0:*  LISTEN  5678/python
```

**If showing 127.0.0.1 instead of 0.0.0.0:**
→ Service is in localhost mode, need to enable web access

---

### Step 2: Check Firewall

```bash
# Ubuntu/Debian
sudo ufw status | grep -E '8081|5050'

# AlmaLinux/Rocky
sudo firewall-cmd --list-ports | grep -E '8081|5050'
```

**Expected output:**
```
8081/tcp                   ALLOW       Anywhere
5050/tcp                   ALLOW       Anywhere
```

**If not shown:**
→ Firewall is blocking, need to enable web access

---

### Step 3: Test from VPS (Localhost)

```bash
# Test Mongo Express
curl http://localhost:8081
# Should return HTML

# Test pgAdmin
curl http://localhost:5050
# Should return HTML

# If localhost works but external IP doesn't:
# → Firewall issue or binding issue
```

---

### Step 4: Check Configuration

```bash
# Mongo Express config
cat /etc/ndc-ols/mongo-express.config.js | grep VCAP_APP_HOST
# Should show: VCAP_APP_HOST: '0.0.0.0' (for web access)
# or: VCAP_APP_HOST: 'localhost' (for SSH tunnel only)

# pgAdmin config
cat /etc/pgadmin/config_local.py | grep LISTEN_ADDRESS
# Should show: PGADMIN_LISTEN_ADDRESS = '0.0.0.0' (for web access)
# or: PGADMIN_LISTEN_ADDRESS = 'localhost' (for SSH tunnel)

# Access mode configs
cat /etc/ndc-ols/mongo-express-access.conf
cat /etc/ndc-ols/pgadmin-access.conf
```

---

## 🔧 Common Issues & Fixes

### Issue 1: "sed: can't read /etc/ndc-ols/mongo-express-access.conf"

**Fix on VPS:**
```bash
# Create missing config file
mkdir -p /etc/ndc-ols
cat > /etc/ndc-ols/mongo-express-access.conf <<EOF
MONGO_EXPRESS_ACCESS_MODE="SSH Tunnel Only"
MONGO_EXPRESS_PORT="8081"
EOF
```

---

### Issue 2: pgAdmin service not found

**Fix on VPS:**
```bash
# Check if pgAdmin binary exists
ls -la /usr/pgadmin4/bin/pgadmin4

# If exists, create systemd service manually
cat > /etc/systemd/system/pgadmin4.service <<'EOF'
[Unit]
Description=pgAdmin 4
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/pgadmin4/bin/pgadmin4
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Reload and start
systemctl daemon-reload
systemctl enable pgadmin4
systemctl start pgadmin4
systemctl status pgadmin4
```

---

### Issue 3: PM2 shows "errored" for pgadmin

**You have two pgAdmin instances!**
```bash
# Check PM2 list
pm2 list
# You'll see "pgadmin" app with status "errored"

# This is WRONG - pgAdmin should run as systemd service, not PM2
# Delete from PM2:
pm2 delete pgadmin
pm2 save

# Use systemd instead:
systemctl status pgadmin4
```

---

### Issue 4: Port is open but still can't connect

**Possible causes:**

1. **VPS provider firewall** (external to your server)
   - Check your VPS control panel
   - Add security group rule for ports 8081, 5050

2. **IP whitelist**
   - Some VPS providers block ports by default
   - Contact support or check firewall settings

3. **Service crashed**
   ```bash
   # Check service status
   systemctl status pgadmin4
   pm2 logs mongo-express
   
   # Restart if needed
   systemctl restart pgadmin4
   pm2 restart mongo-express
   ```

---

## 📋 Complete Diagnostic Checklist

**Run this on your VPS:**

```bash
#!/bin/bash
echo "=== Database GUI Diagnostic ==="
echo ""

# 1. Check services
echo "1. Service Status:"
echo "   Mongo Express (PM2):"
pm2 list | grep mongo-express || echo "   Not running"
echo "   pgAdmin (systemd):"
systemctl is-active pgadmin4 && echo "   Running" || echo "   Not running"
echo ""

# 2. Check ports
echo "2. Listening Ports:"
netstat -tlnp 2>/dev/null | grep -E '8081|5050' || ss -tlnp | grep -E '8081|5050'
echo ""

# 3. Check firewall
echo "3. Firewall Rules:"
if command -v ufw >/dev/null 2>&1; then
    ufw status | grep -E '8081|5050'
elif command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --list-ports
fi
echo ""

# 4. Test localhost
echo "4. Localhost Test:"
echo "   Mongo Express:"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" http://localhost:8081
echo "   pgAdmin:"
curl -s -o /dev/null -w "   HTTP %{http_code}\n" http://localhost:5050
echo ""

# 5. Check configs
echo "5. Configuration:"
echo "   Mongo Express binding:"
grep VCAP_APP_HOST /etc/ndc-ols/mongo-express.config.js 2>/dev/null || echo "   Config not found"
echo "   pgAdmin binding:"
grep LISTEN_ADDRESS /etc/pgadmin/config_local.py 2>/dev/null || echo "   Config not found"
echo ""

# 6. Get credentials
echo "6. Credentials:"
cat /etc/ndc-ols/auth.conf 2>/dev/null || echo "   Not found"
echo ""

echo "=== End Diagnostic ==="
```

**Save as `test-gui.sh` and run:**
```bash
chmod +x test-gui.sh
./test-gui.sh
```

---

## 🚀 Quick Fix Commands

### Reinstall Everything (Fresh Start)

```bash
# SSH to VPS
ssh root@103.221.223.164

# Pull latest code
cd /usr/local/ndc-ols
git pull

# Run NDC-OLS
ndc

# Install Mongo Express
# → 3) GUI Database Admin
# → 1) Install/Reinstall Mongo Express

# Enable Web Access
# → 2) Enable Web Access (Port 8081)

# Install pgAdmin
# → 11) Install/Reinstall pgAdmin 4

# Enable Web Access
# → 12) Enable Web Access (Port 5050)

# Test in browser:
# http://103.221.223.164:8081
# http://103.221.223.164:5050
```

---

## 💡 Pro Tips

### Use SSH Tunnel Instead (More Secure)

**Windows PowerShell:**
```powershell
# One command for both services
ssh -L 8081:localhost:8081 -L 5050:localhost:5050 root@103.221.223.164

# Then access:
# http://localhost:8081 (Mongo Express)
# http://localhost:5050 (pgAdmin)
```

**Advantages:**
- ✅ Encrypted connection
- ✅ No firewall changes needed
- ✅ No exposed ports
- ✅ More secure

### Monitor Logs in Real-time

```bash
# Mongo Express
pm2 logs mongo-express --lines 100

# pgAdmin
journalctl -u pgadmin4 -f

# Both at once (separate terminals)
tmux new-session \; split-window -h \; send-keys 'pm2 logs mongo-express' C-m \; select-pane -L \; send-keys 'journalctl -u pgadmin4 -f' C-m
```

---

## 📞 Still Not Working?

1. **Run diagnostic script** (above)
2. **Check VPS provider firewall/security groups**
3. **Verify public IP** is correct: `curl ifconfig.me`
4. **Try SSH tunnel** instead of web access
5. **Check service logs** for errors
6. **Restart services**: `pm2 restart all && systemctl restart pgadmin4`

---

**Remember:** 
- ❌ Cannot use `ping` for HTTP services
- ✅ Use browser, curl, or Test-NetConnection
- 🔒 SSH tunnel is more secure than web access
- 📋 Always check logs when troubleshooting
