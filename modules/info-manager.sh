#!/bin/bash
# Info Manager
source "$NDC_INSTALL_DIR/utils/colors.sh"

show_server_info() {
    print_header "SERVER INFORMATION"
    
    echo -e "${BOLD}System:${NC}"
    echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "  Kernel: $(uname -r)"
    echo "  Uptime: $(uptime -p)"
    echo ""
    
    echo -e "${BOLD}Hardware:${NC}"
    echo "  CPU: $(nproc) cores"
    echo "  RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "  Disk: $(df -h / | awk 'NR==2 {print $4}') free"
    echo ""
    
    echo -e "${BOLD}Network:${NC}"
    echo "  Public IP: $(get_public_ip)"
    echo ""
    
    echo -e "${BOLD}Software:${NC}"
    command -v nginx >/dev/null && echo "  Nginx: $(nginx -v 2>&1 | cut -d'/' -f2)"
    command -v node >/dev/null && echo "  Node.js: $(node -v)"
    command -v npm >/dev/null && echo "  npm: $(npm -v)"
    command -v pm2 >/dev/null && echo "  PM2: $(pm2 -v)"
    command -v psql >/dev/null && echo "  PostgreSQL: $(psql --version | cut -d' ' -f3)"
    command -v mongod >/dev/null && echo "  MongoDB: $(mongod --version | head -1 | cut -d' ' -f3)"
    command -v mysql >/dev/null && echo "  MySQL: $(mysql --version | cut -d' ' -f6 | cut -d',' -f1)"
    command -v redis-cli >/dev/null && echo "  Redis: $(redis-cli --version | cut -d' ' -f2)"
    
    echo ""
    press_any_key
}

show_credentials_info() {
    print_header "CREDENTIALS INFORMATION"
    
    echo -e "${YELLOW}Database credentials are stored in:${NC}"
    echo "  PostgreSQL: check with 'sudo -u postgres psql'"
    echo "  MongoDB: check /etc/mongod.conf"
    echo "  MySQL: check /etc/mysql/debian.cnf"
    echo ""
    
    echo -e "${YELLOW}App directories:${NC}"
    echo "  /var/www/*"
    echo ""
    
    echo -e "${YELLOW}Logs:${NC}"
    echo "  NDC OLS: $NDC_LOG_DIR"
    echo "  Nginx: /var/log/nginx"
    echo "  PM2: ~/.pm2/logs"
    echo ""
    
    press_any_key
}
