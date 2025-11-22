#!/bin/bash
#######################################
# NDC-OLS System Test Script
# Tests all major components
#######################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Functions
print_test_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Testing: $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

test_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

test_fail() {
    echo -e "${RED}[✗]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

test_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Test NDC-OLS Installation
test_ndc_installation() {
    print_test_header "NDC-OLS Installation"
    
    if [ -d "/usr/local/ndc-ols" ]; then
        test_pass "NDC-OLS directory exists"
    else
        test_fail "NDC-OLS directory not found"
    fi
    
    if [ -f "/usr/local/bin/ndc" ]; then
        test_pass "ndc command is available"
    else
        test_fail "ndc command not found"
    fi
    
    if [ -d "/etc/ndc-ols" ]; then
        test_pass "Configuration directory exists"
    else
        test_fail "Configuration directory not found"
    fi
    
    if [ -f "/etc/ndc-ols/auth.conf" ]; then
        test_pass "Authentication config exists"
        
        # Check if credentials are set
        source /etc/ndc-ols/auth.conf
        if [ -n "$MONGODB_USER" ] && [ -n "$MONGODB_PASS" ]; then
            test_pass "MongoDB credentials configured"
        else
            test_fail "MongoDB credentials not set"
        fi
    else
        test_fail "Authentication config not found"
    fi
}

# Test System Services
test_system_services() {
    print_test_header "System Services"
    
    # Test Nginx
    if systemctl is-active --quiet nginx; then
        test_pass "Nginx is running"
        
        # Test nginx config
        if nginx -t 2>&1 | grep -q "successful"; then
            test_pass "Nginx configuration is valid"
        else
            test_fail "Nginx configuration has errors"
        fi
    else
        test_fail "Nginx is not running"
    fi
    
    # Test Firewall
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            test_pass "UFW firewall is active"
        else
            test_warn "UFW firewall is inactive"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --state 2>&1 | grep -q "running"; then
            test_pass "Firewalld is active"
        else
            test_warn "Firewalld is inactive"
        fi
    else
        test_warn "No firewall detected"
    fi
    
    # Test Fail2ban
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        test_pass "Fail2ban is running"
    else
        test_warn "Fail2ban is not running"
    fi
}

# Test Node.js & PM2
test_nodejs() {
    print_test_header "Node.js & PM2"
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node -v)
        test_pass "Node.js is installed: $node_version"
        
        # Check if version is 18+
        local major_version=$(echo "$node_version" | sed 's/^v\([0-9]*\).*/\1/')
        if [ "$major_version" -ge 18 ]; then
            test_pass "Node.js version is >= 18"
        else
            test_warn "Node.js version is < 18 (current: $node_version)"
        fi
    else
        test_fail "Node.js is not installed"
    fi
    
    if command -v npm >/dev/null 2>&1; then
        local npm_version=$(npm -v)
        test_pass "npm is installed: v$npm_version"
    else
        test_fail "npm is not installed"
    fi
    
    if command -v pm2 >/dev/null 2>&1; then
        test_pass "PM2 is installed"
        
        # Check PM2 processes
        local pm2_apps=$(pm2 list | grep -c "online" || echo "0")
        if [ "$pm2_apps" -gt 0 ]; then
            test_pass "PM2 has $pm2_apps running app(s)"
        else
            test_warn "PM2 has no running apps"
        fi
    else
        test_fail "PM2 is not installed"
    fi
}

# Test MongoDB
test_mongodb() {
    print_test_header "MongoDB"
    
    if systemctl is-active --quiet mongod; then
        test_pass "MongoDB is running"
        
        # Test connection
        if [ -f "/etc/ndc-ols/auth.conf" ]; then
            source /etc/ndc-ols/auth.conf
            
            if mongosh --quiet "mongodb://admin:${MONGODB_PASS}@localhost:27017/admin" --eval "db.runCommand({ ping: 1 })" >/dev/null 2>&1; then
                test_pass "MongoDB connection successful"
                
                # Get MongoDB version
                local mongo_version=$(mongosh --quiet "mongodb://admin:${MONGODB_PASS}@localhost:27017/admin" --eval "db.version()" 2>/dev/null | tail -1)
                test_pass "MongoDB version: $mongo_version"
                
                # Test database operations
                if mongosh --quiet "mongodb://admin:${MONGODB_PASS}@localhost:27017/admin" --eval "db.adminCommand({ listDatabases: 1 })" >/dev/null 2>&1; then
                    test_pass "MongoDB database operations working"
                else
                    test_fail "MongoDB database operations failed"
                fi
            else
                test_fail "MongoDB connection failed"
            fi
        else
            test_warn "MongoDB credentials not found, skipping connection test"
        fi
    else
        test_fail "MongoDB is not running"
    fi
}

# Test Mongo Express
test_mongo_express() {
    print_test_header "Mongo Express"
    
    if pm2 list | grep -q "mongo-express.*online"; then
        test_pass "Mongo Express is running"
        
        # Test port 8081
        if ss -tuln 2>/dev/null | grep -q ":8081" || netstat -tuln 2>/dev/null | grep -q ":8081"; then
            test_pass "Mongo Express is listening on port 8081"
            
            # Test HTTP response
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 2>/dev/null | grep -q "200\|401"; then
                test_pass "Mongo Express HTTP response OK"
            else
                test_fail "Mongo Express not responding to HTTP requests"
            fi
        else
            test_fail "Mongo Express port 8081 not listening"
        fi
    else
        test_warn "Mongo Express is not running"
    fi
}

# Test MySQL/MariaDB
test_mysql() {
    print_test_header "MySQL/MariaDB"
    
    if systemctl is-active --quiet mariadb 2>/dev/null || systemctl is-active --quiet mysql 2>/dev/null; then
        test_pass "MySQL/MariaDB is running"
        
        # Test connection
        if [ -f "/etc/ndc-ols/auth.conf" ]; then
            source /etc/ndc-ols/auth.conf
            
            if [ -n "$MYSQL_ROOT_PASS" ]; then
                if mysql -u root -p"$MYSQL_ROOT_PASS" -e "SELECT 1" >/dev/null 2>&1; then
                    test_pass "MySQL connection successful"
                    
                    # Get MySQL version
                    local mysql_version=$(mysql -u root -p"$MYSQL_ROOT_PASS" -e "SELECT VERSION()" 2>/dev/null | tail -1)
                    test_pass "MySQL version: $mysql_version"
                else
                    test_fail "MySQL connection failed"
                fi
            else
                test_warn "MySQL password not found in auth.conf"
            fi
        fi
    else
        test_warn "MySQL/MariaDB is not running"
    fi
}

# Test PostgreSQL
test_postgresql() {
    print_test_header "PostgreSQL"
    
    if systemctl is-active --quiet postgresql; then
        test_pass "PostgreSQL is running"
        
        # Test connection
        if sudo -u postgres psql -c "SELECT 1" >/dev/null 2>&1; then
            test_pass "PostgreSQL connection successful"
            
            # Get version
            local pg_version=$(sudo -u postgres psql -t -c "SELECT version()" 2>/dev/null | head -1)
            test_pass "PostgreSQL version: ${pg_version:0:50}..."
        else
            test_fail "PostgreSQL connection failed"
        fi
    else
        test_warn "PostgreSQL is not running"
    fi
}

# Test pgAdmin
test_pgadmin() {
    print_test_header "pgAdmin 4"
    
    if systemctl is-active --quiet pgadmin4 2>/dev/null; then
        test_pass "pgAdmin 4 service is running"
        
        # Test port 5050
        if ss -tuln 2>/dev/null | grep -q ":5050" || netstat -tuln 2>/dev/null | grep -q ":5050"; then
            test_pass "pgAdmin 4 is listening on port 5050"
        else
            test_fail "pgAdmin 4 port 5050 not listening"
        fi
    else
        test_warn "pgAdmin 4 is not running"
    fi
}

# Test Redis
test_redis() {
    print_test_header "Redis"
    
    if systemctl is-active --quiet redis 2>/dev/null || systemctl is-active --quiet redis-server 2>/dev/null; then
        test_pass "Redis is running"
        
        # Test connection
        if redis-cli ping 2>/dev/null | grep -q "PONG"; then
            test_pass "Redis connection successful"
            
            # Get version
            local redis_version=$(redis-cli --version 2>/dev/null | awk '{print $2}')
            test_pass "Redis version: $redis_version"
        else
            test_fail "Redis connection failed"
        fi
    else
        test_warn "Redis is not running"
    fi
}

# Test SSL/Certbot
test_ssl() {
    print_test_header "SSL/Certbot"
    
    if command -v certbot >/dev/null 2>&1; then
        test_pass "Certbot is installed"
        
        # Check for certificates
        if [ -d "/etc/letsencrypt/live" ]; then
            local cert_count=$(find /etc/letsencrypt/live -maxdepth 1 -type d | wc -l)
            if [ "$cert_count" -gt 1 ]; then
                test_pass "SSL certificates found: $((cert_count - 1))"
            else
                test_warn "No SSL certificates found"
            fi
        fi
    else
        test_warn "Certbot is not installed"
    fi
}

# Test Network
test_network() {
    print_test_header "Network Configuration"
    
    # Get public IP
    local public_ip=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || echo "N/A")
    if [ "$public_ip" != "N/A" ]; then
        test_pass "Public IP: $public_ip"
    else
        test_warn "Could not determine public IP"
    fi
    
    # Test internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        test_pass "Internet connectivity OK"
    else
        test_fail "No internet connectivity"
    fi
    
    # Test DNS
    if ping -c 1 google.com >/dev/null 2>&1; then
        test_pass "DNS resolution OK"
    else
        test_fail "DNS resolution failed"
    fi
}

# Test Disk Space
test_disk_space() {
    print_test_header "Disk Space"
    
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -lt 80 ]; then
        test_pass "Disk usage OK: ${disk_usage}%"
    elif [ "$disk_usage" -lt 90 ]; then
        test_warn "Disk usage high: ${disk_usage}%"
    else
        test_fail "Disk usage critical: ${disk_usage}%"
    fi
    
    # Check important directories
    for dir in "/var/www" "/var/log" "/etc/ndc-ols" "/usr/local/ndc-ols"; do
        if [ -d "$dir" ]; then
            local dir_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
            echo -e "${CYAN}  - $dir: ${NC}$dir_size"
        fi
    done
}

# Test Memory
test_memory() {
    print_test_header "Memory Usage"
    
    local mem_total=$(free -m | awk 'NR==2 {print $2}')
    local mem_used=$(free -m | awk 'NR==2 {print $3}')
    local mem_percent=$((mem_used * 100 / mem_total))
    
    if [ "$mem_percent" -lt 80 ]; then
        test_pass "Memory usage OK: ${mem_percent}% (${mem_used}MB / ${mem_total}MB)"
    elif [ "$mem_percent" -lt 90 ]; then
        test_warn "Memory usage high: ${mem_percent}% (${mem_used}MB / ${mem_total}MB)"
    else
        test_fail "Memory usage critical: ${mem_percent}% (${mem_used}MB / ${mem_total}MB)"
    fi
}

# Show summary
show_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    TEST SUMMARY${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Total Tests: ${CYAN}$TESTS_TOTAL${NC}"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    local success_rate=0
    if [ "$TESTS_TOTAL" -gt 0 ]; then
        success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    fi
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed! System is healthy.${NC}"
    elif [ "$success_rate" -ge 80 ]; then
        echo -e "${YELLOW}⚠ Some tests failed, but system is mostly operational (${success_rate}% success rate)${NC}"
    else
        echo -e "${RED}✗ Multiple critical tests failed! System needs attention (${success_rate}% success rate)${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Return exit code based on results
    if [ "$TESTS_FAILED" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Main
main() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║          NDC-OLS System Test v1.0                    ║"
    echo "║          Testing all components...                    ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
    
    # Run all tests
    test_ndc_installation
    test_system_services
    test_nodejs
    test_mongodb
    test_mongo_express
    test_mysql
    test_postgresql
    test_pgadmin
    test_redis
    test_ssl
    test_network
    test_disk_space
    test_memory
    
    # Show summary
    show_summary
}

# Run
main "$@"
