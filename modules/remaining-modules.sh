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

# Source Manager
source_manager_menu() {
    read_input "App name" "" app
    cd "/var/www/$app" && bash
}

# Permission Manager
permission_manager_menu() {
    read_input "App directory" "/var/www" dir
    chown -R www-data:www-data "$dir"
    find "$dir" -type d -exec chmod 755 {} \;
    find "$dir" -type f -exec chmod 644 {} \;
    print_success "Permissions fixed"
    press_any_key
}

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

# GUI Manager
gui_manager_menu() {
    print_header "DATABASE ADMIN GUI"
    echo " 1) Install Mongo Express (MongoDB GUI)"
    echo " 2) Secure Mongo Express with Domain (Nginx Proxy)"
    echo " 3) Revert to IP Access (Open Port)"
    echo " 0) Back"
    
    read -p "$(echo -e "${CYAN}Enter choice:${NC} ")" choice
    case $choice in
        1) install_mongo_express ;;
        2) secure_mongo_express ;;
        3) revert_mongo_express_to_ip ;;
        *) return ;;
    esac
}

install_mongo_express() {
    print_step "Installing Mongo Express..."
    
    # Check if MongoDB is running
    if ! systemctl is-active --quiet mongod; then
        print_warning "MongoDB is not running. Attempting to start..."
        systemctl start mongod
        sleep 2
    fi

    # Get config
    read_input "GUI Username" "admin" gui_user
    read_input "GUI Password" "$(generate_password)" gui_pass
    read_input "Port" "8081" port
    
    # Uninstall previous version to ensure clean slate
    npm uninstall -g mongo-express
    
    # Install stable version 0.54.0 (Most compatible)
    print_step "Installing Mongo Express (v0.54.0)..."
    if ! npm install -g mongo-express@0.54.0; then
        print_warning "v0.54.0 failed. Trying latest version..."
        npm install -g mongo-express
    fi
    
    # Get mongo-express path for CWD
    MONGO_EXPRESS_HOME="$(npm root -g)/mongo-express"
    
    # Verify installation
    if [ ! -d "$MONGO_EXPRESS_HOME" ]; then
        print_error "Mongo Express installation failed. Please check npm logs."
        return
    fi
    
    # Start with PM2
    print_step "Starting Mongo Express..."
    
    # Create ecosystem file
    cat > "/etc/ndc-ols/mongo-express.config.js" <<EOF
module.exports = {
  apps: [{
    name: 'mongo-express',
    script: 'app.js',
    cwd: '$MONGO_EXPRESS_HOME',
    env: {
      ME_CONFIG_MONGODB_ENABLE_ADMIN: 'true',
      ME_CONFIG_MONGODB_SERVER: 'localhost',
      ME_CONFIG_BASICAUTH_USERNAME: '$gui_user',
      ME_CONFIG_BASICAUTH_PASSWORD: '$gui_pass',
      ME_CONFIG_SITE_HOST: '0.0.0.0',
      VCAP_APP_HOST: '0.0.0.0',
      HOST: '0.0.0.0',
      PORT: '$port',
      VCAP_APP_PORT: '$port'
    }
  }]
};
EOF

    # Stop and delete existing process if it exists to ensure config update
    pm2 delete mongo-express 2>/dev/null || true

    pm2 start "/etc/ndc-ols/mongo-express.config.js"
    pm2 save
    
    # Open firewall
    if command_exists ufw; then
        ufw allow $port/tcp
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-port=$port/tcp
        firewall-cmd --reload
    fi
    
    print_success "Mongo Express installed!"
    print_info "Access: http://YOUR_IP:$port"
    print_info "User: $gui_user"
    print_info "Pass: $gui_pass"
    
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
    print_header "SECURE MONGO EXPRESS"
    
    # Check if Mongo Express is running
    if ! pm2 list | grep -q "mongo-express"; then
        print_error "Mongo Express is not running! Please install it first."
        return
    fi
    
    read_input "Enter Domain (e.g., db.yourdomain.com)" "" domain
    if [ -z "$domain" ]; then
        print_error "Domain is required!"
        return
    fi
    
    read_input "Mongo Express Port" "8081" port
    
    print_step "Configuring Nginx..."
    
    # Create Nginx config
    cat > "/etc/nginx/sites-available/$domain" <<EOF
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://localhost:$port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

    # Enable site
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    
    # Test and reload Nginx
    if nginx -t; then
        systemctl reload nginx
        print_success "Nginx configured!"
    else
        print_error "Nginx configuration failed!"
        return
    fi
    
    # SSL
    if ask_yes_no "Install SSL (HTTPS)?" "y"; then
        certbot --nginx -d "$domain" --non-interactive --agree-tos --email admin@$domain --redirect
    fi
    
    # Secure Mongo Express (Bind to localhost only)
    print_step "Securing Mongo Express (Closing public port)..."
    
    # Update config to bind only to localhost
    sed -i "s/ME_CONFIG_SITE_HOST: '0.0.0.0'/ME_CONFIG_SITE_HOST: 'localhost'/g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s/VCAP_APP_HOST: '0.0.0.0'/VCAP_APP_HOST: 'localhost'/g" /etc/ndc-ols/mongo-express.config.js
    sed -i "s/HOST: '0.0.0.0'/HOST: 'localhost'/g" /etc/ndc-ols/mongo-express.config.js
    
    # Restart Mongo Express
    pm2 restart mongo-express
    pm2 save
    
    # Close firewall port
    if command_exists ufw; then
        ufw delete allow $port/tcp
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-port=$port/tcp
        firewall-cmd --reload
    fi
    
    print_success "Mongo Express is now secured!"
    print_info "Access: https://$domain"
    print_info "Public port $port has been closed."
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
