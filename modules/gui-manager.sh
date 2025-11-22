#!/bin/bash
#######################################
# Module: GUI Database Manager
# MongoDB Express & pgAdmin Management
#######################################

source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

# Load NVM for npm and node commands
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use

#######################################
# Main GUI Manager Menu
#######################################
gui_manager_menu() {
    while true; do
        print_header "ADMIN DATABASE GUI"
        
        # Check status
        local mongo_status="❌ Not installed"
        local pgadmin_status="❌ Not installed"
        local mongo_access="N/A"
        local pgadmin_access="N/A"
        
        if pm2 list | grep -q "mongo-express"; then
            mongo_status="✅ Running"
            if [ -f "/etc/ndc-ols/mongo-express-access.conf" ]; then
                source "/etc/ndc-ols/mongo-express-access.conf"
                mongo_access="$MONGO_EXPRESS_ACCESS_MODE"
            fi
        fi
        
        if systemctl is-active --quiet pgadmin4; then
            pgadmin_status="✅ Running"
            if [ -f "/etc/ndc-ols/pgadmin-access.conf" ]; then
                source "/etc/ndc-ols/pgadmin-access.conf"
                pgadmin_access="$PGADMIN_ACCESS_MODE"
            fi
        fi
        
        echo -e "${CYAN}Current Status:${NC}"
        echo -e "  Mongo Express : $mongo_status (Access: $mongo_access)"
        echo -e "  pgAdmin 4     : $pgadmin_status (Access: $pgadmin_access)"
        echo ""
        
        echo -e " ${GREEN}MongoDB Express:${NC}"
        echo -e " ${GREEN}1)${NC}  Install/Reinstall Mongo Express"
        echo -e " ${GREEN}2)${NC}  Enable Web Access (Port 8081)"
        echo -e " ${GREEN}3)${NC}  Disable Web Access (SSH Tunnel Only)"
        echo -e " ${GREEN}4)${NC}  Secure with Domain + SSL"
        echo -e " ${GREEN}5)${NC}  Show SSH Tunnel Command"
        echo -e " ${GREEN}6)${NC}  Uninstall Mongo Express"
        echo ""
        echo -e " ${GREEN}pgAdmin 4:${NC}"
        echo -e " ${GREEN}11)${NC} Install/Reinstall pgAdmin 4"
        echo -e " ${GREEN}12)${NC} Enable Web Access (Port 5050)"
        echo -e " ${GREEN}13)${NC} Disable Web Access (SSH Tunnel Only)"
        echo -e " ${GREEN}14)${NC} Secure with Domain + SSL"
        echo -e " ${GREEN}15)${NC} Show SSH Tunnel Command"
        echo -e " ${GREEN}16)${NC} Uninstall pgAdmin 4"
        echo ""
        echo -e " ${GREEN}phpMyAdmin:${NC}"
        echo -e " ${GREEN}21)${NC} Install phpMyAdmin"
        echo ""
        echo -e " ${GREEN}22)${NC} Show All Database GUI Credentials"
        echo ""
        echo -e " ${RED}0)${NC}  Back to main menu"
        echo ""
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case $choice in
            1) install_mongo_express ;;
            2) enable_mongo_express_web ;;
            3) disable_mongo_express_web ;;
            4) secure_mongo_express_domain ;;
            5) show_mongo_express_tunnel ;;
            6) uninstall_mongo_express ;;
            11) install_pgadmin ;;
            12) enable_pgadmin_web ;;
            13) disable_pgadmin_web ;;
            14) secure_pgadmin_domain ;;
            15) show_pgadmin_tunnel ;;
            16) uninstall_pgadmin ;;
            21) install_phpmyadmin ;;
            22) show_all_gui_credentials ;;
            0) return ;;
            *) print_error "Invalid option"; sleep 2 ;;
        esac
    done
}

#######################################
# MongoDB Express Functions
#######################################

install_mongo_express() {
    print_header "INSTALL MONGO EXPRESS"
    
    # Load NVM for npm and pm2
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
    
    # Check if Node.js is available
    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js is not installed! Please run main installation first."
        press_any_key
        return
    fi
    
    # Check if npm is available
    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm is not installed! Please run main installation first."
        press_any_key
        return
    fi
    
    # Check if PM2 is available
    if ! command -v pm2 >/dev/null 2>&1; then
        print_error "PM2 is not installed! Please run main installation first."
        press_any_key
        return
    fi
    
    # Check if MongoDB is installed
    if ! systemctl is-active --quiet mongod; then
        print_error "MongoDB is not running! Please install MongoDB first."
        press_any_key
        return
    fi
    
    # Load credentials
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
    else
        print_warning "No auth.conf found. Creating credentials..."
        MONGODB_USER="admin"
        MONGODB_PASS=$(openssl rand -base64 16)
        MONGO_EXPRESS_USER="admin"
        MONGO_EXPRESS_PASS=$(openssl rand -base64 16)
        
        mkdir -p "$NDC_CONFIG_DIR"
        cat > "$NDC_CONFIG_DIR/auth.conf" <<EOF
MONGODB_USER="$MONGODB_USER"
MONGODB_PASS="$MONGODB_PASS"
MONGO_EXPRESS_USER="$MONGO_EXPRESS_USER"
MONGO_EXPRESS_PASS="$MONGO_EXPRESS_PASS"
EOF
        chmod 600 "$NDC_CONFIG_DIR/auth.conf"
    fi
    
    print_step "Installing Mongo Express globally..."
    npm install -g mongo-express 2>&1 | grep -v "npm WARN" || true
    
    local MONGO_EXPRESS_HOME="$(npm root -g)/mongo-express"
    
    if [ ! -d "$MONGO_EXPRESS_HOME" ]; then
        print_error "Mongo Express installation failed!"
        press_any_key
        return
    fi
    
    print_step "Creating PM2 configuration..."
    
    # Generate secure secrets
    COOKIE_SECRET=$(openssl rand -hex 32)
    SESSION_SECRET=$(openssl rand -hex 32)
    
    cat > "$NDC_CONFIG_DIR/mongo-express.config.js" <<EOF
module.exports = {
  apps: [{
    name: 'mongo-express',
    script: '$MONGO_EXPRESS_HOME/app.js',
    cwd: '$MONGO_EXPRESS_HOME',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '200M',
    env: {
      NODE_ENV: 'production',
      ME_CONFIG_MONGODB_ENABLE_ADMIN: 'true',
      ME_CONFIG_MONGODB_SERVER: 'localhost',
      ME_CONFIG_MONGODB_PORT: '27017',
      ME_CONFIG_MONGODB_ADMINUSERNAME: '$MONGODB_USER',
      ME_CONFIG_MONGODB_ADMINPASSWORD: '$MONGODB_PASS',
      ME_CONFIG_MONGODB_AUTH_DATABASE: 'admin',
      ME_CONFIG_MONGODB_AUTH_USERNAME: '$MONGODB_USER',
      ME_CONFIG_MONGODB_AUTH_PASSWORD: '$MONGODB_PASS',
      ME_CONFIG_BASICAUTH_USERNAME: '$MONGO_EXPRESS_USER',
      ME_CONFIG_BASICAUTH_PASSWORD: '$MONGO_EXPRESS_PASS',
      ME_CONFIG_SITE_BASEURL: '/',
      ME_CONFIG_SITE_COOKIESECRET: '$COOKIE_SECRET',
      ME_CONFIG_SITE_SESSIONSECRET: '$SESSION_SECRET',
      VCAP_APP_HOST: 'localhost',
      VCAP_APP_PORT: '8081',
      PORT: '8081'
    }
  }]
};
EOF

    # Stop if already running
    pm2 delete mongo-express 2>/dev/null || true
    
    print_step "Starting Mongo Express with PM2..."
    pm2 start "$NDC_CONFIG_DIR/mongo-express.config.js"
    pm2 save
    
    # Save access mode config
    mkdir -p /etc/ndc-ols
    cat > "/etc/ndc-ols/mongo-express-access.conf" <<EOF
MONGO_EXPRESS_ACCESS_MODE="SSH Tunnel Only"
MONGO_EXPRESS_PORT="8081"
EOF
    
    print_success "Mongo Express installed successfully!"
    echo ""
    print_info "Default Access: SSH Tunnel Only (Secure)"
    print_info "Username: $MONGO_EXPRESS_USER"
    print_info "Password: $MONGO_EXPRESS_PASS"
    echo ""
    print_warning "To enable web access, use option 2 from menu"
    echo ""
    
    press_any_key
}

enable_mongo_express_web() {
    print_header "ENABLE WEB ACCESS - MONGO EXPRESS"
    
    # Load NVM to ensure pm2 is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
    
    # Check if PM2 is available
    if ! command -v pm2 >/dev/null 2>&1; then
        print_error "PM2 is not installed! Please install Node.js and PM2 first."
        press_any_key
        return
    fi
    
    # Check if Mongo Express is running
    if ! pm2 list 2>/dev/null | grep -q "mongo-express"; then
        print_error "Mongo Express is not installed! Please install it first (option 1)"
        press_any_key
        return
    fi
    
    print_warning "This will open port 8081 to public internet!"
    echo ""
    if ! ask_yes_no "Are you sure you want to enable web access?" "n"; then
        return
    fi
    
    print_step "Updating Mongo Express configuration..."
    
    # Update config to bind to 0.0.0.0 (try multiple patterns)
    if [ -f "$NDC_CONFIG_DIR/mongo-express.config.js" ]; then
        # Try with single quotes
        sed -i "s/VCAP_APP_HOST: 'localhost'/VCAP_APP_HOST: '0.0.0.0'/g" "$NDC_CONFIG_DIR/mongo-express.config.js"
        # Try with double quotes
        sed -i 's/VCAP_APP_HOST: "localhost"/VCAP_APP_HOST: "0.0.0.0"/g' "$NDC_CONFIG_DIR/mongo-express.config.js"
        # Try without quotes
        sed -i 's/VCAP_APP_HOST: localhost/VCAP_APP_HOST: 0.0.0.0/g' "$NDC_CONFIG_DIR/mongo-express.config.js"
        
        # Verify the change
        if grep -q "VCAP_APP_HOST.*0\\.0\\.0\\.0" "$NDC_CONFIG_DIR/mongo-express.config.js"; then
            print_success "Configuration updated to bind to 0.0.0.0"
        else
            print_warning "Could not verify config change. Manually updating..."
            # Force update by replacing the entire env section
            sed -i "/VCAP_APP_HOST/c\\      VCAP_APP_HOST: '0.0.0.0'," "$NDC_CONFIG_DIR/mongo-express.config.js"
        fi
    else
        print_error "Config file not found: $NDC_CONFIG_DIR/mongo-express.config.js"
        press_any_key
        return
    fi
    
    # Restart Mongo Express
    print_step "Restarting Mongo Express..."
    pm2 restart mongo-express --update-env
    pm2 save
    sleep 3
    
    # Verify service is running and binding correctly
    print_step "Verifying service..."
    if pm2 list 2>/dev/null | grep -q "mongo-express.*online"; then
        print_success "Mongo Express is running"
        
        # Check if port is listening
        if netstat -tlnp 2>/dev/null | grep 8081 | grep -q "0.0.0.0" || ss -tlnp 2>/dev/null | grep 8081 | grep -q "0.0.0.0"; then
            print_success "Port 8081 is open and listening on 0.0.0.0"
        else
            print_warning "Port 8081 may not be accessible externally"
            print_info "Checking binding..."
            netstat -tlnp 2>/dev/null | grep 8081 || ss -tlnp 2>/dev/null | grep 8081 || true
        fi
    else
        print_error "Mongo Express failed to start!"
        print_info "Check logs with: pm2 logs mongo-express"
        press_any_key
        return
    fi
    
    # Open firewall
    print_step "Opening firewall port 8081..."
    if command_exists ufw; then
        ufw allow 8081/tcp 2>/dev/null || true
        ufw reload 2>/dev/null || true
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-port=8081/tcp
        firewall-cmd --reload
    fi
    
    # Update access mode (create file if not exists)
    mkdir -p /etc/ndc-ols
    if [ -f /etc/ndc-ols/mongo-express-access.conf ]; then
        sed -i 's/MONGO_EXPRESS_ACCESS_MODE=.*/MONGO_EXPRESS_ACCESS_MODE="Web (Port 8081)"/' /etc/ndc-ols/mongo-express-access.conf
    else
        cat > /etc/ndc-ols/mongo-express-access.conf <<EOF
MONGO_EXPRESS_ACCESS_MODE="Web (Port 8081)"
MONGO_EXPRESS_PORT="8081"
EOF
    fi
    
    print_success "Web access enabled!"
    echo ""
    print_info "Access URL: http://$(get_public_ip):8081"
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
        print_info "Username: $MONGO_EXPRESS_USER"
        print_info "Password: $MONGO_EXPRESS_PASS"
    fi
    echo ""
    print_warning "For better security, use option 4 to setup domain + SSL"
    echo ""
    
    press_any_key
}

disable_mongo_express_web() {
    print_header "DISABLE WEB ACCESS - MONGO EXPRESS"
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
    
    if ! command -v pm2 >/dev/null 2>&1 || ! pm2 list 2>/dev/null | grep -q "mongo-express"; then
        print_error "Mongo Express is not installed!"
        press_any_key
        return
    fi
    
    print_step "Binding to localhost only..."
    
    # Update config to bind to localhost
    sed -i "s/VCAP_APP_HOST: '0.0.0.0'/VCAP_APP_HOST: 'localhost'/g" "$NDC_CONFIG_DIR/mongo-express.config.js"
    
    # Restart Mongo Express
    pm2 restart mongo-express --update-env
    pm2 save
    sleep 2
    
    # Close firewall
    print_step "Closing firewall port 8081..."
    if command_exists ufw; then
        ufw delete allow 8081/tcp 2>/dev/null || true
        ufw reload 2>/dev/null || true
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-port=8081/tcp 2>/dev/null || true
        firewall-cmd --reload
    fi
    
    # Update access mode
    sed -i 's/MONGO_EXPRESS_ACCESS_MODE=.*/MONGO_EXPRESS_ACCESS_MODE="SSH Tunnel Only"/' /etc/ndc-ols/mongo-express-access.conf
    
    print_success "Web access disabled!"
    echo ""
    print_info "Mongo Express is now only accessible via SSH tunnel"
    echo ""
    show_mongo_express_tunnel
    
    press_any_key
}

show_mongo_express_tunnel() {
    print_header "SSH TUNNEL FOR MONGO EXPRESS"
    
    local server_ip=$(get_public_ip)
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
    fi
    
    echo -e "${CYAN}SSH Tunnel Command:${NC}"
    echo ""
    echo -e "${YELLOW}ssh -L 8081:localhost:8081 root@$server_ip${NC}"
    echo ""
    echo -e "${CYAN}After connecting:${NC}"
    echo -e "  1. Open browser: ${GREEN}http://localhost:8081${NC}"
    echo -e "  2. Username: ${GREEN}$MONGO_EXPRESS_USER${NC}"
    echo -e "  3. Password: ${GREEN}$MONGO_EXPRESS_PASS${NC}"
    echo ""
    echo -e "${CYAN}For Windows (PowerShell/CMD):${NC}"
    echo -e "${YELLOW}ssh -L 8081:localhost:8081 root@$server_ip${NC}"
    echo ""
    echo -e "${CYAN}For PuTTY:${NC}"
    echo -e "  Connection → SSH → Tunnels"
    echo -e "  Source port: 8081"
    echo -e "  Destination: localhost:8081"
    echo -e "  Click 'Add' then 'Open'"
    echo ""
    
    press_any_key
}

secure_mongo_express_domain() {
    print_header "SECURE WITH DOMAIN + SSL"
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
    
    if ! command -v pm2 >/dev/null 2>&1 || ! pm2 list 2>/dev/null | grep -q "mongo-express"; then
        print_error "Mongo Express is not installed!"
        press_any_key
        return
    fi
    
    read_input "Enter domain (e.g., db.yourdomain.com)" "" domain
    if [ -z "$domain" ]; then
        print_error "Domain is required!"
        press_any_key
        return
    fi
    
    read_input "Enter email for SSL certificate" "" email
    if [ -z "$email" ]; then
        print_error "Email is required!"
        press_any_key
        return
    fi
    
    # Ensure Mongo Express is on localhost
    sed -i "s/VCAP_APP_HOST: '0.0.0.0'/VCAP_APP_HOST: 'localhost'/g" "$NDC_CONFIG_DIR/mongo-express.config.js"
    pm2 restart mongo-express --update-env
    sleep 2
    
    print_step "Creating Nginx reverse proxy configuration..."
    
    cat > "/etc/nginx/sites-available/$domain" <<'EOFNGINX'
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Basic auth bypass (Mongo Express has its own auth)
        proxy_set_header Authorization "";
    }
}
EOFNGINX

    sed -i "s/DOMAIN_PLACEHOLDER/$domain/g" "/etc/nginx/sites-available/$domain"
    
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    
    if ! nginx -t 2>&1 | grep -q "successful"; then
        print_error "Nginx configuration test failed!"
        rm "/etc/nginx/sites-available/$domain" 2>/dev/null || true
        rm "/etc/nginx/sites-enabled/$domain" 2>/dev/null || true
        press_any_key
        return
    fi
    
    systemctl reload nginx
    
    print_step "Installing SSL certificate..."
    
    if ! command_exists certbot; then
        print_warning "Installing Certbot..."
        if command_exists apt-get; then
            apt-get update -qq
            apt-get install -y certbot python3-certbot-nginx
        elif command_exists dnf; then
            dnf install -y certbot python3-certbot-nginx
        fi
    fi
    
    certbot --nginx -d "$domain" --non-interactive --agree-tos --email "$email" --redirect
    
    if [ $? -eq 0 ]; then
        # Close public port
        if command_exists ufw; then
            ufw delete allow 8081/tcp 2>/dev/null || true
        elif command_exists firewall-cmd; then
            firewall-cmd --permanent --remove-port=8081/tcp 2>/dev/null || true
            firewall-cmd --reload
        fi
        
        # Update access mode
        sed -i "s|MONGO_EXPRESS_ACCESS_MODE=.*|MONGO_EXPRESS_ACCESS_MODE=\"Domain: https://$domain\"|" /etc/ndc-ols/mongo-express-access.conf
        
        print_success "SSL certificate installed successfully!"
        echo ""
        print_info "Access URL: https://$domain"
        
        if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
            source "$NDC_CONFIG_DIR/auth.conf"
            print_info "Username: $MONGO_EXPRESS_USER"
            print_info "Password: $MONGO_EXPRESS_PASS"
        fi
        echo ""
    else
        print_error "Failed to obtain SSL certificate!"
        print_info "Please check domain DNS configuration and try again"
    fi
    
    press_any_key
}

uninstall_mongo_express() {
    print_header "UNINSTALL MONGO EXPRESS"
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use
    
    if ! command -v pm2 >/dev/null 2>&1 || ! pm2 list 2>/dev/null | grep -q "mongo-express"; then
        print_warning "Mongo Express is not installed"
        press_any_key
        return
    fi
    
    if ! confirm_action "Uninstall Mongo Express?"; then
        return
    fi
    
    print_step "Stopping Mongo Express..."
    pm2 delete mongo-express 2>/dev/null || true
    pm2 save
    
    print_step "Removing configuration..."
    rm -f "$NDC_CONFIG_DIR/mongo-express.config.js"
    rm -f "/etc/ndc-ols/mongo-express-access.conf"
    
    print_step "Closing firewall..."
    if command_exists ufw; then
        ufw delete allow 8081/tcp 2>/dev/null || true
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-port=8081/tcp 2>/dev/null || true
        firewall-cmd --reload
    fi
    
    print_success "Mongo Express uninstalled!"
    press_any_key
}

#######################################
# pgAdmin Functions
#######################################

install_pgadmin() {
    print_header "INSTALL PGADMIN 4"
    
    # Check if PostgreSQL is installed
    if ! systemctl is-active --quiet postgresql; then
        print_error "PostgreSQL is not running! Please install PostgreSQL first."
        press_any_key
        return
    fi
    
    print_step "Installing pgAdmin 4..."
    
    if command_exists apt-get; then
        # Add repository
        curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
        
        echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list
        
        apt-get update -qq
        
        # Install pgadmin4-web (web version)
        DEBIAN_FRONTEND=noninteractive apt-get install -y pgadmin4-web
        
    elif command_exists dnf; then
        # For RHEL/Rocky/Alma
        dnf install -y https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-redhat-repo-2-1.noarch.rpm
        dnf install -y pgadmin4-web
    fi
    
    # Setup pgAdmin
    print_step "Configuring pgAdmin 4..."
    
    # Generate password
    PGADMIN_EMAIL="admin@local.domain"
    PGADMIN_PASS=$(openssl rand -base64 16)
    
    # Save credentials
    mkdir -p "$NDC_CONFIG_DIR"
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        # Append to existing file
        cat >> "$NDC_CONFIG_DIR/auth.conf" <<EOF

# pgAdmin Credentials
PGADMIN_EMAIL="$PGADMIN_EMAIL"
PGADMIN_PASS="$PGADMIN_PASS"
EOF
    else
        # Create new file
        cat > "$NDC_CONFIG_DIR/auth.conf" <<EOF
# pgAdmin Credentials
PGADMIN_EMAIL="$PGADMIN_EMAIL"
PGADMIN_PASS="$PGADMIN_PASS"
EOF
    fi
    chmod 600 "$NDC_CONFIG_DIR/auth.conf"
    
    # Setup pgAdmin with credentials
    print_step "Setting up pgAdmin user..."
    
    # Create setup script
    cat > /tmp/pgadmin-setup.py <<'PYEOF'
import sys
sys.path.insert(0, '/usr/pgadmin4/web')
from pgadmin import create_app
from pgadmin.model import db, User
from pgadmin.setup import setup_db

app = create_app()
with app.app_context():
    setup_db()
    user = User(email='EMAIL_PLACEHOLDER', active=True)
    user.set_password('PASS_PLACEHOLDER')
    db.session.add(user)
    db.session.commit()
    print('User created successfully')
PYEOF

    sed -i "s/EMAIL_PLACEHOLDER/$PGADMIN_EMAIL/g" /tmp/pgadmin-setup.py
    sed -i "s/PASS_PLACEHOLDER/$PGADMIN_PASS/g" /tmp/pgadmin-setup.py
    
    python3 /tmp/pgadmin-setup.py 2>/dev/null || true
    rm /tmp/pgadmin-setup.py
    
    # Configure to run on port 5050
    mkdir -p /etc/pgadmin
    cat > /etc/pgadmin/config_local.py <<'EOF'
MASTER_PASSWORD_REQUIRED = False
SERVER_MODE = True
DEFAULT_SERVER = '127.0.0.1'
DEFAULT_SERVER_PORT = 5432
PGADMIN_LISTEN_ADDRESS = 'localhost'
PGADMIN_LISTEN_PORT = 5050
EOF

    # Create systemd service for pgAdmin
    print_step "Creating pgAdmin systemd service..."
    
    # Find pgAdmin4 executable path
    PGADMIN_BIN=""
    if [ -f /usr/pgadmin4/bin/pgadmin4 ]; then
        PGADMIN_BIN="/usr/pgadmin4/bin/pgadmin4"
    elif [ -f /usr/bin/pgadmin4 ]; then
        PGADMIN_BIN="/usr/bin/pgadmin4"
    elif [ -f /usr/local/bin/pgadmin4 ]; then
        PGADMIN_BIN="/usr/local/bin/pgadmin4"
    else
        # Try to find it
        PGADMIN_BIN=$(which pgadmin4 2>/dev/null || find /usr -name "pgadmin4" -type f 2>/dev/null | head -1)
    fi
    
    # If still not found, use web server approach
    if [ -z "$PGADMIN_BIN" ] || [ ! -f "$PGADMIN_BIN" ]; then
        print_warning "pgAdmin4 binary not found, using web server approach..."
        
        # Create a Python wrapper script to run pgAdmin
        cat > /usr/local/bin/pgadmin4-server <<'PYEOF'
#!/usr/bin/env python3
import sys
sys.path.insert(0, '/usr/pgadmin4/web')

from pgadmin import create_app

app = create_app()

if __name__ == '__main__':
    # Load config
    import os
    if os.path.exists('/etc/pgadmin/config_local.py'):
        app.config.from_pyfile('/etc/pgadmin/config_local.py')
    
    # Get host and port from config
    host = app.config.get('PGADMIN_LISTEN_ADDRESS', 'localhost')
    port = app.config.get('PGADMIN_LISTEN_PORT', 5050)
    
    app.run(host=host, port=port, debug=False)
PYEOF
        chmod +x /usr/local/bin/pgadmin4-server
        PGADMIN_BIN="/usr/local/bin/pgadmin4-server"
        print_info "Using wrapper script: $PGADMIN_BIN"
    else
        print_info "Found pgAdmin4 at: $PGADMIN_BIN"
    fi
    
    cat > /etc/systemd/system/pgadmin4.service <<SVCEOF
[Unit]
Description=pgAdmin 4
After=network.target

[Service]
Type=simple
User=root
ExecStart=$PGADMIN_BIN
Restart=on-failure
RestartSec=5s
Environment="PYTHONPATH=/usr/pgadmin4/web"

[Install]
WantedBy=multi-user.target
SVCEOF

    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable pgadmin4
    systemctl restart pgadmin4
    
    # Wait for service to start
    print_step "Waiting for pgAdmin to start..."
    sleep 5
    
    # Verify service is running
    if systemctl is-active --quiet pgadmin4; then
        print_success "pgAdmin 4 service is running"
        
        # Check if port is listening
        sleep 2
        if netstat -tlnp 2>/dev/null | grep 5050 >/dev/null || ss -tlnp 2>/dev/null | grep 5050 >/dev/null; then
            print_success "Port 5050 is listening"
        else
            print_warning "Port 5050 may not be ready yet"
            print_info "Check status with: systemctl status pgadmin4"
        fi
    else
        print_error "pgAdmin 4 service failed to start!"
        print_info "Checking logs..."
        journalctl -u pgadmin4 -n 20 --no-pager
        echo ""
        print_info "Try running: systemctl status pgadmin4"
    fi
    
    # Save access mode
    mkdir -p /etc/ndc-ols
    cat > "/etc/ndc-ols/pgadmin-access.conf" <<EOF
PGADMIN_ACCESS_MODE="SSH Tunnel Only"
PGADMIN_PORT="5050"
EOF
    
    print_success "pgAdmin 4 installed successfully!"
    echo ""
    print_info "Default Access: SSH Tunnel Only (Secure)"
    print_info "Email: $PGADMIN_EMAIL"
    print_info "Password: $PGADMIN_PASS"
    echo ""
    print_warning "To enable web access, use option 12 from menu"
    echo ""
    
    press_any_key
}

enable_pgadmin_web() {
    print_header "ENABLE WEB ACCESS - PGADMIN"
    
    # Check multiple possible service names
    local pgadmin_running=false
    if systemctl is-active --quiet pgadmin4 2>/dev/null; then
        pgadmin_running=true
    elif systemctl is-active --quiet pgadmin4-web 2>/dev/null; then
        pgadmin_running=true
    elif systemctl is-active --quiet apache-pgadmin4 2>/dev/null; then
        pgadmin_running=true
    fi
    
    if [ "$pgadmin_running" = false ]; then
        print_error "pgAdmin 4 is not installed or not running!"
        print_info "Please install it first (option 11)"
        echo ""
        print_info "Checking pgAdmin status..."
        systemctl status pgadmin4 2>/dev/null || systemctl status pgadmin4-web 2>/dev/null || echo "No pgAdmin service found"
        press_any_key
        return
    fi
    
    print_warning "This will open port 5050 to public internet!"
    echo ""
    if ! ask_yes_no "Are you sure you want to enable web access?" "n"; then
        return
    fi
    
    print_step "Updating pgAdmin configuration..."
    
    # Update config to bind to 0.0.0.0
    sed -i "s/PGADMIN_LISTEN_ADDRESS = 'localhost'/PGADMIN_LISTEN_ADDRESS = '0.0.0.0'/" /etc/pgadmin/config_local.py
    
    systemctl restart pgadmin4
    sleep 2
    
    # Open firewall
    print_step "Opening firewall port 5050..."
    if command_exists ufw; then
        ufw allow 5050/tcp
        ufw reload
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-port=5050/tcp
        firewall-cmd --reload
    fi
    
    # Update access mode
    sed -i 's/PGADMIN_ACCESS_MODE=.*/PGADMIN_ACCESS_MODE="Web (Port 5050)"/' /etc/ndc-ols/pgadmin-access.conf
    
    print_success "Web access enabled!"
    echo ""
    print_info "Access URL: http://$(get_public_ip):5050"
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
        print_info "Email: $PGADMIN_EMAIL"
        print_info "Password: $PGADMIN_PASS"
    fi
    echo ""
    
    press_any_key
}

disable_pgadmin_web() {
    print_header "DISABLE WEB ACCESS - PGADMIN"
    
    if ! systemctl is-active --quiet pgadmin4; then
        print_error "pgAdmin 4 is not installed!"
        press_any_key
        return
    fi
    
    print_step "Binding to localhost only..."
    
    sed -i "s/PGADMIN_LISTEN_ADDRESS = '0.0.0.0'/PGADMIN_LISTEN_ADDRESS = 'localhost'/" /etc/pgadmin/config_local.py
    
    systemctl restart pgadmin4
    sleep 2
    
    # Close firewall
    print_step "Closing firewall port 5050..."
    if command_exists ufw; then
        ufw delete allow 5050/tcp 2>/dev/null || true
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-port=5050/tcp 2>/dev/null || true
        firewall-cmd --reload
    fi
    
    # Update access mode
    sed -i 's/PGADMIN_ACCESS_MODE=.*/PGADMIN_ACCESS_MODE="SSH Tunnel Only"/' /etc/ndc-ols/pgadmin-access.conf
    
    print_success "Web access disabled!"
    echo ""
    show_pgadmin_tunnel
    
    press_any_key
}

show_pgadmin_tunnel() {
    print_header "SSH TUNNEL FOR PGADMIN"
    
    local server_ip=$(get_public_ip)
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
    fi
    
    echo -e "${CYAN}SSH Tunnel Command:${NC}"
    echo ""
    echo -e "${YELLOW}ssh -L 5050:localhost:5050 root@$server_ip${NC}"
    echo ""
    echo -e "${CYAN}After connecting:${NC}"
    echo -e "  1. Open browser: ${GREEN}http://localhost:5050${NC}"
    echo -e "  2. Email: ${GREEN}$PGADMIN_EMAIL${NC}"
    echo -e "  3. Password: ${GREEN}$PGADMIN_PASS${NC}"
    echo ""
    echo -e "${CYAN}For PuTTY:${NC}"
    echo -e "  Connection → SSH → Tunnels"
    echo -e "  Source port: 5050"
    echo -e "  Destination: localhost:5050"
    echo -e "  Click 'Add' then 'Open'"
    echo ""
    
    press_any_key
}

secure_pgadmin_domain() {
    print_header "SECURE WITH DOMAIN + SSL"
    
    if ! systemctl is-active --quiet pgadmin4; then
        print_error "pgAdmin 4 is not installed!"
        press_any_key
        return
    fi
    
    read_input "Enter domain (e.g., pgadmin.yourdomain.com)" "" domain
    if [ -z "$domain" ]; then
        print_error "Domain is required!"
        press_any_key
        return
    fi
    
    read_input "Enter email for SSL certificate" "" email
    if [ -z "$email" ]; then
        print_error "Email is required!"
        press_any_key
        return
    fi
    
    # Ensure pgAdmin is on localhost
    sed -i "s/PGADMIN_LISTEN_ADDRESS = '0.0.0.0'/PGADMIN_LISTEN_ADDRESS = 'localhost'/" /etc/pgadmin/config_local.py
    systemctl restart pgadmin4
    sleep 2
    
    print_step "Creating Nginx reverse proxy..."
    
    cat > "/etc/nginx/sites-available/$domain" <<'EOFNGINX'
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    location / {
        proxy_pass http://127.0.0.1:5050;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # pgAdmin specific headers
        proxy_set_header X-Script-Name /;
    }
}
EOFNGINX

    sed -i "s/DOMAIN_PLACEHOLDER/$domain/g" "/etc/nginx/sites-available/$domain"
    
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    
    if ! nginx -t 2>&1 | grep -q "successful"; then
        print_error "Nginx configuration test failed!"
        rm "/etc/nginx/sites-available/$domain" 2>/dev/null || true
        rm "/etc/nginx/sites-enabled/$domain" 2>/dev/null || true
        press_any_key
        return
    fi
    
    systemctl reload nginx
    
    print_step "Installing SSL certificate..."
    
    if ! command_exists certbot; then
        print_warning "Installing Certbot..."
        if command_exists apt-get; then
            apt-get update -qq
            apt-get install -y certbot python3-certbot-nginx
        elif command_exists dnf; then
            dnf install -y certbot python3-certbot-nginx
        fi
    fi
    
    certbot --nginx -d "$domain" --non-interactive --agree-tos --email "$email" --redirect
    
    if [ $? -eq 0 ]; then
        # Close public port
        if command_exists ufw; then
            ufw delete allow 5050/tcp 2>/dev/null || true
        elif command_exists firewall-cmd; then
            firewall-cmd --permanent --remove-port=5050/tcp 2>/dev/null || true
            firewall-cmd --reload
        fi
        
        # Update access mode
        sed -i "s|PGADMIN_ACCESS_MODE=.*|PGADMIN_ACCESS_MODE=\"Domain: https://$domain\"|" /etc/ndc-ols/pgadmin-access.conf
        
        print_success "SSL certificate installed successfully!"
        echo ""
        print_info "Access URL: https://$domain"
        
        if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
            source "$NDC_CONFIG_DIR/auth.conf"
            print_info "Email: $PGADMIN_EMAIL"
            print_info "Password: $PGADMIN_PASS"
        fi
        echo ""
    else
        print_error "Failed to obtain SSL certificate!"
    fi
    
    press_any_key
}

uninstall_pgadmin() {
    print_header "UNINSTALL PGADMIN 4"
    
    if ! systemctl is-active --quiet pgadmin4 2>/dev/null; then
        print_warning "pgAdmin 4 is not installed"
        press_any_key
        return
    fi
    
    if ! confirm_action "Uninstall pgAdmin 4?"; then
        return
    fi
    
    print_step "Stopping pgAdmin 4..."
    systemctl stop pgadmin4
    systemctl disable pgadmin4
    
    print_step "Removing packages..."
    if command_exists apt-get; then
        apt-get remove -y pgadmin4-web
        apt-get autoremove -y
    elif command_exists dnf; then
        dnf remove -y pgadmin4-web
    fi
    
    print_step "Removing configuration..."
    rm -rf /etc/pgadmin
    rm -f "/etc/ndc-ols/pgadmin-access.conf"
    
    print_step "Closing firewall..."
    if command_exists ufw; then
        ufw delete allow 5050/tcp 2>/dev/null || true
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-port=5050/tcp 2>/dev/null || true
        firewall-cmd --reload
    fi
    
    print_success "pgAdmin 4 uninstalled!"
    press_any_key
}

#######################################
# phpMyAdmin
#######################################

install_phpmyadmin() {
    print_header "INSTALL PHPMYADMIN"
    
    if [ -d "/usr/share/phpmyadmin" ]; then
        print_warning "phpMyAdmin already installed."
        if ! ask_yes_no "Reinstall phpMyAdmin?" "n"; then
            press_any_key
            return
        fi
    fi
    
    print_step "Installing PHP and dependencies..."
    if command_exists apt-get; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y -qq php-fpm php-mysql php-mbstring php-zip php-gd php-json php-curl php-xml
        
        echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect " | debconf-set-selections
        
        apt-get install -y -qq phpmyadmin
    elif command_exists dnf; then
        dnf install -y -q php php-fpm php-mysqlnd php-mbstring php-zip php-gd php-json php-xml phpmyadmin
    fi
    
    print_step "Configuring Nginx..."
    
    ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin 2>/dev/null || true
    
    # Get PHP version
    local PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    
    cat > /etc/nginx/conf.d/phpmyadmin.conf <<EOF
server {
    listen 8080;
    server_name _;
    root /usr/share/phpmyadmin;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
    }
}
EOF

    # Open port
    if command_exists ufw; then
        ufw allow 8080/tcp
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --reload
    fi
    
    systemctl restart nginx
    
    print_success "phpMyAdmin installed!"
    print_info "Access: http://$(get_public_ip):8080"
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
        print_info "User: root"
        if [ -n "$MYSQL_ROOT_PASS" ]; then
            print_info "Password: $MYSQL_ROOT_PASS"
        else
            print_warning "MySQL password not found in auth.conf"
        fi
    fi
    
    press_any_key
}

#######################################
# Show All Credentials
#######################################

show_all_gui_credentials() {
    print_header "DATABASE GUI CREDENTIALS"
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
        
        echo -e "${CYAN}MongoDB Express:${NC}"
        if pm2 list | grep -q "mongo-express"; then
            echo -e "  Status: ${GREEN}Running${NC}"
            if [ -f "/etc/ndc-ols/mongo-express-access.conf" ]; then
                source "/etc/ndc-ols/mongo-express-access.conf"
                echo -e "  Access: $MONGO_EXPRESS_ACCESS_MODE"
            fi
            echo -e "  User: ${YELLOW}$MONGO_EXPRESS_USER${NC}"
            echo -e "  Pass: ${YELLOW}$MONGO_EXPRESS_PASS${NC}"
        else
            echo -e "  Status: ${RED}Not installed${NC}"
        fi
        echo ""
        
        echo -e "${CYAN}pgAdmin 4:${NC}"
        if systemctl is-active --quiet pgadmin4; then
            echo -e "  Status: ${GREEN}Running${NC}"
            if [ -f "/etc/ndc-ols/pgadmin-access.conf" ]; then
                source "/etc/ndc-ols/pgadmin-access.conf"
                echo -e "  Access: $PGADMIN_ACCESS_MODE"
            fi
            echo -e "  Email: ${YELLOW}$PGADMIN_EMAIL${NC}"
            echo -e "  Pass: ${YELLOW}$PGADMIN_PASS${NC}"
        else
            echo -e "  Status: ${RED}Not installed${NC}"
        fi
        echo ""
        
        echo -e "${CYAN}phpMyAdmin:${NC}"
        if [ -d "/usr/share/phpmyadmin" ]; then
            echo -e "  Status: ${GREEN}Installed${NC}"
            echo -e "  URL: http://$(get_public_ip):8080"
            echo -e "  User: ${YELLOW}root${NC}"
            if [ -n "$MYSQL_ROOT_PASS" ]; then
                echo -e "  Pass: ${YELLOW}$MYSQL_ROOT_PASS${NC}"
            else
                echo -e "  Pass: ${RED}(Check /root/.my.cnf)${NC}"
            fi
        else
            echo -e "  Status: ${RED}Not installed${NC}"
        fi
        echo ""
    else
        print_warning "No credentials file found!"
    fi
    
    press_any_key
}
