#!/bin/bash
#######################################
# Database GUI Diagnostic Script
# Run this on your VPS to check GUI status
#######################################

echo "════════════════════════════════════════════════════════════"
echo "           DATABASE GUI DIAGNOSTIC TOOL"
echo "════════════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Check PM2 Mongo Express
echo "1. MONGO EXPRESS STATUS (PM2)"
echo "────────────────────────────────────────────────────────────"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use

if command -v pm2 >/dev/null 2>&1; then
    pm2 list | grep -E "mongo-express|pgadmin"
    echo ""
    echo "Mongo Express Logs (last 20 lines):"
    pm2 logs mongo-express --lines 20 --nostream 2>/dev/null || echo "No logs available"
else
    echo -e "${RED}PM2 not found!${NC}"
fi
echo ""

# 2. Check systemd pgAdmin
echo "2. PGADMIN 4 STATUS (systemd)"
echo "────────────────────────────────────────────────────────────"
if systemctl list-units --full --all | grep -q pgadmin4; then
    systemctl status pgadmin4 --no-pager
else
    echo -e "${RED}pgAdmin4 systemd service not found${NC}"
fi
echo ""

# 3. Check listening ports
echo "3. LISTENING PORTS"
echo "────────────────────────────────────────────────────────────"
echo "Looking for ports 8081 (Mongo Express) and 5050 (pgAdmin)..."
if command -v netstat >/dev/null 2>&1; then
    netstat -tlnp | grep -E '8081|5050' || echo -e "${RED}No processes listening on 8081 or 5050${NC}"
elif command -v ss >/dev/null 2>&1; then
    ss -tlnp | grep -E '8081|5050' || echo -e "${RED}No processes listening on 8081 or 5050${NC}"
fi
echo ""

# 4. Check firewall rules
echo "4. FIREWALL STATUS"
echo "────────────────────────────────────────────────────────────"
if command -v ufw >/dev/null 2>&1; then
    echo "UFW Status:"
    ufw status | grep -E '8081|5050|Status' || echo "No rules for 8081/5050"
elif command -v firewall-cmd >/dev/null 2>&1; then
    echo "Firewalld Status:"
    firewall-cmd --list-ports | grep -E '8081|5050' || echo "No rules for 8081/5050"
fi
echo ""

# 5. Test localhost access
echo "5. LOCALHOST ACCESS TEST"
echo "────────────────────────────────────────────────────────────"
echo -n "Mongo Express (port 8081): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -qE "200|401|302"; then
    echo -e "${GREEN}✓ Accessible (HTTP $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8081))${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

echo -n "pgAdmin (port 5050): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5050 | grep -qE "200|401|302"; then
    echo -e "${GREEN}✓ Accessible (HTTP $(curl -s -o /dev/null -w '%{http_code}' http://localhost:5050))${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi
echo ""

# 6. Check configuration files
echo "6. CONFIGURATION CHECK"
echo "────────────────────────────────────────────────────────────"
echo "Mongo Express config:"
if [ -f /etc/ndc-ols/mongo-express.config.js ]; then
    echo -n "  Binding: "
    grep "VCAP_APP_HOST" /etc/ndc-ols/mongo-express.config.js | grep -oE "'[^']+'" || echo "Not found"
    echo -n "  Port: "
    grep "PORT:" /etc/ndc-ols/mongo-express.config.js | grep -oE "'[^']+'" || echo "8081"
else
    echo -e "  ${RED}Config file not found${NC}"
fi

echo ""
echo "pgAdmin config:"
if [ -f /etc/pgadmin/config_local.py ]; then
    echo -n "  Listen Address: "
    grep "PGADMIN_LISTEN_ADDRESS" /etc/pgadmin/config_local.py || echo "Not found"
    echo -n "  Listen Port: "
    grep "PGADMIN_LISTEN_PORT" /etc/pgadmin/config_local.py || echo "Not found"
else
    echo -e "  ${RED}Config file not found${NC}"
fi
echo ""

# 7. Check access mode configs
echo "7. ACCESS MODE CONFIGURATION"
echo "────────────────────────────────────────────────────────────"
if [ -f /etc/ndc-ols/mongo-express-access.conf ]; then
    cat /etc/ndc-ols/mongo-express-access.conf
else
    echo -e "${RED}mongo-express-access.conf not found${NC}"
fi
echo ""
if [ -f /etc/ndc-ols/pgadmin-access.conf ]; then
    cat /etc/ndc-ols/pgadmin-access.conf
else
    echo -e "${RED}pgadmin-access.conf not found${NC}"
fi
echo ""

# 8. Check public IP
echo "8. NETWORK INFORMATION"
echo "────────────────────────────────────────────────────────────"
echo -n "Public IP: "
curl -s ifconfig.me || curl -s icanhazip.com || echo "Unable to determine"
echo ""
echo -n "Hostname: "
hostname
echo ""

# 9. Get credentials
echo "9. CREDENTIALS"
echo "────────────────────────────────────────────────────────────"
if [ -f /etc/ndc-ols/auth.conf ]; then
    cat /etc/ndc-ols/auth.conf
else
    echo -e "${RED}Credentials file not found${NC}"
fi
echo ""

# 10. Summary and recommendations
echo "════════════════════════════════════════════════════════════"
echo "           DIAGNOSTIC SUMMARY"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check if Mongo Express is accessible
if curl -s http://localhost:8081 >/dev/null 2>&1; then
    if netstat -tlnp 2>/dev/null | grep 8081 | grep -q "0.0.0.0"; then
        echo -e "${GREEN}✓ Mongo Express: Running and accessible externally${NC}"
    elif netstat -tlnp 2>/dev/null | grep 8081 | grep -q "127.0.0.1"; then
        echo -e "${YELLOW}⚠ Mongo Express: Running but bound to localhost only${NC}"
        echo "  Fix: Need to bind to 0.0.0.0"
        echo "  Config: /etc/ndc-ols/mongo-express.config.js"
        echo "  Change: VCAP_APP_HOST: 'localhost' → VCAP_APP_HOST: '0.0.0.0'"
        echo "  Then: pm2 restart mongo-express"
    fi
else
    echo -e "${RED}✗ Mongo Express: Not accessible${NC}"
    echo "  Check PM2 logs: pm2 logs mongo-express"
fi
echo ""

# Check if pgAdmin is accessible
if curl -s http://localhost:5050 >/dev/null 2>&1; then
    if netstat -tlnp 2>/dev/null | grep 5050 | grep -q "0.0.0.0"; then
        echo -e "${GREEN}✓ pgAdmin: Running and accessible externally${NC}"
    elif netstat -tlnp 2>/dev/null | grep 5050 | grep -q "127.0.0.1"; then
        echo -e "${YELLOW}⚠ pgAdmin: Running but bound to localhost only${NC}"
        echo "  Fix: Need to bind to 0.0.0.0"
        echo "  Config: /etc/pgadmin/config_local.py"
        echo "  Change: PGADMIN_LISTEN_ADDRESS = 'localhost' → '0.0.0.0'"
        echo "  Then: systemctl restart pgadmin4"
    fi
else
    echo -e "${RED}✗ pgAdmin: Not accessible${NC}"
    echo "  Check service: systemctl status pgadmin4"
fi
echo ""

echo "════════════════════════════════════════════════════════════"
echo "For detailed troubleshooting, see: /usr/local/ndc-ols/TESTING_GUI.md"
echo "════════════════════════════════════════════════════════════"
