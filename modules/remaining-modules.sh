# GUI Manager
gui_manager_menu() {
    print_header "ADMIN DATABASE GUI"
    echo " 1) Install Mongo Express (MongoDB GUI)"
    echo " 2) Secure Mongo Express with Domain (Nginx Proxy)"
    echo " 3) Revert to IP Access (Open Port)"
    echo " 4) Secure MongoDB for Compass (Recommended)"
    echo " 0) Back"
    
    read -p "$(echo -e "${CYAN}Enter choice:${NC} ")" choice
    case $choice in
        1) install_mongo_express ;;
        2) secure_mongo_express ;;
        3) revert_mongo_express_to_ip ;;
        4) secure_mongodb_compass ;;
        *) return ;;
    esac
}

secure_mongodb_compass() {
    print_header "SECURE MONGODB FOR COMPASS"
    print_step "Tự động hóa bảo mật MongoDB cho Compass..."
    bash "$NDC_INSTALL_DIR/modules/mongodb-secure-setup.sh"
    press_any_key
}
#!/bin/bash
# Remaining simple modules stubs
source "$NDC_INSTALL_DIR/utils/colors.sh"

# Cache Manager
cache_manager_menu() { print_header "CACHE MANAGER"; print_info "Use Redis Manager (option 19)"; press_any_key; }

# Nginx Manager
nginx_manager_menu() { print_header "NGINX CONFIG"; print_info "Use Domain Manager (option 2)"; press_any_key; }

# Env Manager
env_manager_menu() {
    print_header "ENVIRONMENT VARIABLES"
    read_input "App name" "" app
    ${EDITOR:-nano} "/var/www/$app/.env"
}

# Clone Manager
clone_manager_menu() { print_header "CLONE PROJECT"; print_info "Coming soon"; press_any_key; }

# Redis Manager
redis_manager_menu() {
    print_header "REDIS CACHE"
    echo " 1) Redis status"
    echo " 2) Flush cache"
    echo " 3) Redis CLI"
    echo " 0) Back"
    read -p "Choice: " c
    case $c in
        1) systemctl status redis; press_any_key ;;
        2) redis-cli FLUSHALL; print_success "Cache flushed"; press_any_key ;;
        3) redis-cli ;;
    esac
}

# Security Manager
security_manager_menu() {
    print_header "SECURITY & FIREWALL"
    print_info "Use Firewall Manager (option 8) and SSH Manager (option 9)"
    press_any_key
}

# Self Update
self_update_menu() {
    print_header "UPDATE NDC OLS"
    if ask_yes_no "Update NDC OLS to latest version?" "y"; then
        print_step "Updating from GitHub..."
        cd "$NDC_INSTALL_DIR" || return
        
        # Reset local changes to ensure clean pull
        git reset --hard HEAD
        git pull origin main
        
        # Update permissions
        chmod +x "$NDC_INSTALL_DIR/ndc-ols.sh"
        chmod +x "$NDC_INSTALL_DIR/modules/"*.sh
        chmod +x "$NDC_INSTALL_DIR/utils/"*.sh
        
        print_success "NDC OLS updated successfully!"
        print_info "Please restart the script to see changes."
    fi
    press_any_key
}



install_mongo_express() {
    print_step "Installing Mongo Express..."
    
    # Check if MongoDB is running
    if ! systemctl is-active --quiet mongod; then
        print_warning "MongoDB is not running. Attempting to start..."
        systemctl start mongod
        sleep 2
    fi

    print_header "MongoDB Authentication Setup"
    print_info "Mongo Express requires MongoDB to be secured with user/password."
    print_info ""
    
    # Check if MongoDB is already secured
    if echo "db.adminCommand('ping')" | mongosh "mongodb://localhost:27017/admin" &>/dev/null 2>&1; then
        # MongoDB is NOT secured (no auth required)
        print_warning "⚠️  MongoDB is NOT secured yet (no authentication enabled)"
        print_info ""
        
        if ask_yes_no "Would you like to secure MongoDB NOW before installing Mongo Express?" "y"; then
            print_step "Securing MongoDB..."
            bash "$NDC_INSTALL_DIR/modules/mongodb-secure-setup.sh"
            print_info ""
            print_info "MongoDB has been secured. Please provide the credentials below:"
            read_input "MongoDB Admin Username (from security setup)" "admin_823b82" mongo_user
            read_input "MongoDB Admin Password (from security setup)" "" mongo_pass
            
            if [ -z "$mongo_pass" ]; then
                print_error "MongoDB password cannot be empty!"
                return
            fi
        else
            print_error "Mongo Express requires secured MongoDB. Aborted."
            return
        fi
    else
        # MongoDB is already secured
        print_success "✅ MongoDB is already secured"
        print_info ""
        read_input "MongoDB Admin Username" "admin_823b82" mongo_user
        read_input "MongoDB Admin Password" "" mongo_pass
        
        if [ -z "$mongo_pass" ]; then
            print_error "MongoDB password cannot be empty!"
            return
        fi
    fi

    # Verify MongoDB connection with credentials
    print_step "Verifying MongoDB connection with provided credentials..."
    if ! echo "db.adminCommand('ping')" | mongosh "mongodb://$mongo_user:$mongo_pass@localhost:27017/admin?authSource=admin" &>/dev/null; then
        print_error "Failed to connect to MongoDB with provided credentials!"
        print_info "Please ensure credentials are correct."
        print_info "Troubleshooting:"
        print_info "  1. Check MongoDB is running: systemctl status mongod"
        print_info "  2. Verify user exists: mongosh > use admin > db.getUser('$mongo_user')"
        print_info "  3. Check mongod.conf has: security.authorization: enabled"
        return
    fi
    print_success "✅ MongoDB connection verified!"

    # Get Mongo Express GUI credentials
    print_info ""
    read_input "Mongo Express GUI Username" "admin" gui_user
    read_input "Mongo Express GUI Password" "$(generate_password)" gui_pass
    read_input "Port" "8081" port
    
    # Uninstall previous version to ensure clean slate
    npm uninstall -g mongo-express 2>/dev/null || true
    
    # Install latest version (compatible with MongoDB 7.x)
    print_step "Installing Mongo Express (latest version for MongoDB 7.x compatibility)..."
    if ! npm install -g mongo-express; then
        print_error "Mongo Express installation failed. Please check npm logs."
        return
    fi
    
    # Get mongo-express path for CWD
    MONGO_EXPRESS_HOME="$(npm root -g)/mongo-express"
    
    # Verify installation
    if [ ! -d "$MONGO_EXPRESS_HOME" ]; then
        print_error "Mongo Express installation failed. Please check npm logs."
        return
    fi
    
    # Start with PM2
    print_step "Configuring Mongo Express with MongoDB authentication..."
    
    # Create ecosystem file with full MongoDB authentication
    cat > "/etc/ndc-ols/mongo-express.config.js" <<'EOFCONFIG'
module.exports = {
  apps: [{
    name: 'mongo-express',
    script: 'app.js',
    cwd: 'MONGO_EXPRESS_HOME',
    env: {
      ME_CONFIG_MONGODB_ENABLE_ADMIN: 'false',
      ME_CONFIG_MONGODB_SERVER: 'localhost',
      ME_CONFIG_MONGODB_PORT: '27017',
      ME_CONFIG_MONGODB_AUTH_DATABASE: 'admin',
      ME_CONFIG_MONGODB_AUTH_USERNAME: 'MONGO_USER',
      ME_CONFIG_MONGODB_AUTH_PASSWORD: 'MONGO_PASS',
      ME_CONFIG_BASICAUTH_USERNAME: 'GUI_USER',
      ME_CONFIG_BASICAUTH_PASSWORD: 'GUI_PASS',
      ME_CONFIG_SITE_HOST: '0.0.0.0',
      ME_CONFIG_SITE_BASEURL: '/',
      VCAP_APP_HOST: '0.0.0.0',
      HOST: '0.0.0.0',
      PORT: 'PORT_NUM',
      VCAP_APP_PORT: 'PORT_NUM',
      NODE_ENV: 'production'
    }
  }]
};
EOFCONFIG

    # Replace placeholders with actual values
    sed -i "s|MONGO_EXPRESS_HOME|$MONGO_EXPRESS_HOME|g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s|MONGO_USER|$mongo_user|g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s|MONGO_PASS|$mongo_pass|g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s|GUI_USER|$gui_user|g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s|GUI_PASS|$gui_pass|g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s|PORT_NUM|$port|g" /etc/ndc-ols/mongo-express.config.js

    # Stop and delete existing process if it exists to ensure config update
    pm2 delete mongo-express 2>/dev/null || true
    sleep 1

    # Start Mongo Express with new config
    print_step "Starting Mongo Express..."
    if ! pm2 start "/etc/ndc-ols/mongo-express.config.js"; then
        print_error "Failed to start Mongo Express with PM2!"
        return
    fi
    
    pm2 save
    sleep 2
    
    # Verify Mongo Express started successfully
    if ! pm2 list | grep -q "mongo-express"; then
        print_error "Mongo Express failed to start!"
        print_info "Run: pm2 logs mongo-express"
        return
    fi
    
    # Open firewall
    if command_exists ufw; then
        ufw allow $port/tcp 2>/dev/null || true
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-port=$port/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    print_success "Mongo Express installed and started successfully!"
    print_info "======================================"
    print_info "Access: http://YOUR_IP:$port"
    print_info "GUI Username: $gui_user"
    print_info "GUI Password: $gui_pass"
    print_info "MongoDB User: $mongo_user"
    print_info "======================================"
    print_info "To view logs: pm2 logs mongo-express"
    print_info "To restart: pm2 restart mongo-express"
    
    if ask_yes_no "Do you want to secure it with a domain now?" "y"; then
        secure_mongo_express
    else
        press_any_key
    fi
}

revert_mongo_express_to_ip() {
    print_header "REVERT TO IP ACCESS"
    
    if ! pm2 list | grep -q "mongo-express"; then
        print_error "Mongo Express is not running!"
        return
    fi
    
    read_input "Port" "8081" port
    
    print_step "Reverting configuration..."
    
    # Update config to bind to 0.0.0.0
    sed -i "s/ME_CONFIG_SITE_HOST: 'localhost'/ME_CONFIG_SITE_HOST: '0.0.0.0'/g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s/VCAP_APP_HOST: 'localhost'/VCAP_APP_HOST: '0.0.0.0'/g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s/HOST: 'localhost'/HOST: '0.0.0.0'/g" /etc/ndc-ols/mongo-express.config.js
    
    # Restart Mongo Express
    pm2 restart mongo-express
    pm2 save
    
    # Open firewall
    if command_exists ufw; then
        ufw allow $port/tcp
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-port=$port/tcp
        firewall-cmd --reload
    fi
    
    print_success "Mongo Express is now accessible via IP!"
    print_info "Access: http://YOUR_IP:$port"
    
    if ask_yes_no "Do you want to remove the Nginx config for the domain?" "n"; then
        read_input "Enter Domain to remove" "" domain
        if [ -f "/etc/nginx/sites-available/$domain" ]; then
            rm "/etc/nginx/sites-available/$domain"
            rm "/etc/nginx/sites-enabled/$domain"
            systemctl reload nginx
            print_success "Nginx config removed."
        fi
    fi
    
    press_any_key
}

secure_mongo_express() {
    print_header "SECURE MONGO EXPRESS WITH DOMAIN"
    
    # Check if Mongo Express is running
    if ! pm2 list | grep -q "mongo-express"; then
        print_error "Mongo Express is not running! Please install it first."
        return
    fi
    
    # Get current Mongo Express port from PM2 config
    if [ ! -f "/etc/ndc-ols/mongo-express.config.js" ]; then
        print_error "Mongo Express config not found!"
        return
    fi
    
    CURRENT_PORT=$(grep "PORT:" /etc/ndc-ols/mongo-express.config.js | grep -oP "'\K[0-9]+" | head -1)
    if [ -z "$CURRENT_PORT" ]; then
        CURRENT_PORT="8081"
    fi

    read_input "Enter Domain (e.g., db.yourdomain.com)" "" domain
    if [ -z "$domain" ]; then
        print_error "Domain is required!"
        return
    fi
    
    read_input "Mongo Express Port" "$CURRENT_PORT" port
    
    print_step "Creating Nginx HTTP config (for Let's Encrypt validation)..."
    
    # First create HTTP-only config for Let's Encrypt
    cat > "/etc/nginx/sites-available/$domain" <<'EOFNGINX_HTTP'
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_NAME;

    # Allow Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}
EOFNGINX_HTTP

    sed -i "s|DOMAIN_NAME|$domain|g" /etc/nginx/sites-available/$domain

    # Enable site
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/" || true
    
    # Test Nginx
    if ! nginx -t 2>/dev/null; then
        print_error "Nginx configuration test failed!"
        rm "/etc/nginx/sites-available/$domain"
        return
    fi
    
    systemctl reload nginx
    print_success "Nginx HTTP config created!"

    # Install SSL with Certbot
    print_step "Installing SSL Certificate with Let's Encrypt..."
    
    if ! command_exists certbot; then
        print_warning "Certbot not installed. Installing..."
        apt update -qq
        apt install -y certbot python3-certbot-nginx
    fi

    # Create certbot directories
    mkdir -p /var/www/certbot

    # Install SSL certificate
    if ! certbot certonly --webroot -w /var/www/certbot -d "$domain" --non-interactive --agree-tos --email "admin@$domain" --quiet 2>/dev/null; then
        print_error "Failed to obtain SSL certificate for $domain"
        print_info "Please check domain DNS and try again manually:"
        print_info "  certbot certonly --webroot -w /var/www/certbot -d $domain"
        rm "/etc/nginx/sites-available/$domain"
        return
    fi

    print_success "SSL certificate obtained!"
    
    print_step "Creating Nginx HTTPS config with proper proxy headers..."
    
    # Now create full HTTPS config with proxy
    cat > "/etc/nginx/sites-available/$domain" <<'EOFNGINX_HTTPS'
# HTTP redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_NAME;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server with Mongo Express proxy
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name DOMAIN_NAME;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_NAME/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Mongo Express
    location / {
        proxy_pass http://localhost:PORT_NUM;
        
        # HTTP version and upgrade
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Host and forwarding
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_set_header X-Forwarded-Port 443;
        
        # Cache and timeout
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 90;
        proxy_connect_timeout 90;
        proxy_send_timeout 90;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
}
EOFNGINX_HTTPS

    # Replace placeholders
    sed -i "s|DOMAIN_NAME|$domain|g" /etc/nginx/sites-available/$domain
    sed -i "s|PORT_NUM|$port|g" /etc/nginx/sites-available/$domain

    # Test and reload Nginx
    if ! nginx -t 2>/dev/null; then
        print_error "Nginx HTTPS configuration test failed!"
        rm "/etc/nginx/sites-available/$domain"
        return
    fi
    
    systemctl reload nginx
    print_success "Nginx HTTPS config applied!"

    # Update Mongo Express config to bind to localhost only
    print_step "Securing Mongo Express (binding to localhost only)..."
    
    # Update the PM2 config to bind to localhost
    sed -i "s/ME_CONFIG_SITE_HOST: '0.0.0.0'/ME_CONFIG_SITE_HOST: 'localhost'/g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s/VCAP_APP_HOST: '0.0.0.0'/VCAP_APP_HOST: 'localhost'/g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s/HOST: '0.0.0.0'/HOST: 'localhost'/g" /etc/ndc-ols/mongo-express.config.js
    
    # Restart Mongo Express
    pm2 restart mongo-express --update-env
    pm2 save
    sleep 2
    
    # Close firewall port
    if command_exists ufw; then
        ufw delete allow $port/tcp 2>/dev/null || true
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-port=$port/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    print_success "Mongo Express is now fully secured with HTTPS!"
    print_info "======================================"
    print_info "✅ Access: https://$domain"
    print_info "✅ SSL Certificate: Let's Encrypt (auto-renew)"
    print_info "✅ HTTP redirects to HTTPS"
    print_info "✅ Public port $port is closed"
    print_info "✅ Only accessible via domain"
    print_info "======================================"
    print_info "To restart: pm2 restart mongo-express"
    print_info "To view logs: pm2 logs mongo-express"
    print_info "SSL renewal: certbot renew (auto)"
    
    press_any_key
}

# Support Manager
support_manager_menu() {
    print_header "SUPPORT"
    echo "GitHub: https://github.com/ndc-ols"
    echo "Discord: https://discord.gg/ndc-ols"
    echo "Docs: https://docs.ndc-ols.com"
    press_any_key
}

# Swap Manager
swap_manager_menu() {
    print_header "SWAP MANAGEMENT"
    read_input "Swap size (GB)" "2" size
    if confirm_action "Create ${size}GB swap?"; then
        fallocate -l "${size}G" /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        print_success "Swap created"
    fi
    press_any_key
}

# Migration Manager
migration_manager_menu() { print_header "MIGRATION TOOL"; print_info "Coming soon"; press_any_key; }

# File Manager
filemanager_menu() {
    print_header "FILE MANAGER"
    print_info "Install: curl -fsSL https://filebrowser.org/get.sh | bash"
    press_any_key
}

# Monitor Manager
monitor_manager_menu() {
    print_header "MONITOR RESOURCES"
    echo " 1) htop"
    echo " 2) PM2 monit"
    echo " 3) Install Netdata"
    echo " 0) Back"
    read -p "Choice: " c
    case $c in
        1) htop ;;
        2) pm2 monit ;;
        3) bash <(curl -Ss https://my-netdata.io/kickstart.sh); press_any_key ;;
    esac
}

# Donate
donate_menu() {
    print_header "DONATE & SUPPORT"
    echo "Support NDC OLS development:"
    echo ""
    echo "  ⭐ Star on GitHub"
    echo "  💖 GitHub Sponsors: https://github.com/sponsors/ndc-ols"
    echo "  ☕ Buy me a coffee: https://buymeacoffee.com/ndc-ols"
    echo ""
    press_any_key
}
