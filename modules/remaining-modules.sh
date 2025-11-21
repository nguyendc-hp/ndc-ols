# GUI Manager
gui_manager_menu() {
    print_header "ADMIN DATABASE GUI"
    echo " 1) Install/Reinstall Mongo Express"
    echo " 2) Secure Mongo Express with Domain"
    echo " 3) Revert Mongo Express to IP"
    echo " 4) Install/Reinstall phpMyAdmin"
    echo " 0) Back"
    
    read -p "$(echo -e "${CYAN}Enter choice:${NC} ")" choice
    case $choice in
        1) install_mongo_express ;;
        2) secure_mongo_express ;;
        3) revert_mongo_express_to_ip ;;
        4) install_phpmyadmin ;;
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
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
    else
        print_error "Credentials not found! Please check $NDC_CONFIG_DIR/auth.conf"
        return
    fi

    # Install
    npm install -g mongo-express >/dev/null 2>&1
    
    MONGO_EXPRESS_HOME="$(npm root -g)/mongo-express"
    
    if [ ! -d "$MONGO_EXPRESS_HOME" ]; then
        print_error "Mongo Express install failed"
        return
    fi
    
    # Configure
    cat > "$NDC_CONFIG_DIR/mongo-express.config.js" <<EOF
module.exports = {
  apps: [{
    name: 'mongo-express',
    script: 'app.js',
    cwd: '$MONGO_EXPRESS_HOME',
    instances: 1,
    autorestart: true,
    watch: false,
    env: {
      NODE_ENV: 'production',
      ME_CONFIG_MONGODB_ENABLE_ADMIN: 'true',
      ME_CONFIG_MONGODB_SERVER: '127.0.0.1',
      ME_CONFIG_MONGODB_PORT: '27017',
      ME_CONFIG_MONGODB_AUTH_DATABASE: 'admin',
      ME_CONFIG_MONGODB_AUTH_USERNAME: '$MONGODB_USER',
      ME_CONFIG_MONGODB_AUTH_PASSWORD: '$MONGODB_PASS',
      ME_CONFIG_BASICAUTH_USERNAME: '$MONGO_EXPRESS_USER',
      ME_CONFIG_BASICAUTH_PASSWORD: '$MONGO_EXPRESS_PASS',
      ME_CONFIG_SITE_HOST: '0.0.0.0',
      ME_CONFIG_SITE_BASEURL: '/',
      ME_CONFIG_SITE_COOKIE_SECRET: 'secret_$(date +%s)',
      ME_CONFIG_SITE_SESSION_SECRET: 'secret_$(date +%s)',
      VCAP_APP_HOST: '0.0.0.0',
      PORT: '8081'
    }
  }]
};
EOF

    # Start
    pm2 start "$NDC_CONFIG_DIR/mongo-express.config.js"
    pm2 save
    
    # Open firewall
    if command_exists ufw; then
        ufw allow 8081/tcp >/dev/null 2>&1
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-port=8081/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
    fi
    
    print_success "Mongo Express installed (Port 8081)"
    print_info "User: $MONGO_EXPRESS_USER"
    print_info "Pass: $MONGO_EXPRESS_PASS"
    press_any_key
}

install_phpmyadmin() {
    print_step "Installing phpMyAdmin..."
    
    if [ -d "/usr/share/phpmyadmin" ]; then
        print_warning "phpMyAdmin already installed."
        if ! ask_yes_no "Reinstall phpMyAdmin?" "n"; then
            return
        fi
    fi
    
    # Install PHP and extensions first
    print_step "Installing PHP dependencies..."
    if command_exists apt-get; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y -qq php-fpm php-mysql php-mbstring php-zip php-gd php-json php-curl php-xml >/dev/null 2>&1
        
        # Pre-configure debconf for phpmyadmin
        echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect " | debconf-set-selections
        
        apt-get install -y -qq phpmyadmin >/dev/null 2>&1
    elif command_exists dnf; then
        dnf install -y -q php php-fpm php-mysqlnd php-mbstring php-zip php-gd php-json php-xml >/dev/null 2>&1
        if dnf list phpmyadmin >/dev/null 2>&1; then
            dnf install -y -q phpmyadmin >/dev/null 2>&1
        else
            print_warning "phpMyAdmin package not found in default repos. Skipping..."
            return
        fi
    fi
    
    # Configure Nginx for phpMyAdmin
    print_step "Configuring Nginx for phpMyAdmin..."
    
    # Create a symlink to web root
    ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin
    
    # Create config
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
        fastcgi_pass unix:/run/php/php$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')-fpm.sock;
    }
}
EOF

    # Open port 8080
    if command_exists ufw; then
        ufw allow 8080/tcp >/dev/null 2>&1
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-port=8080/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
    fi
    
    systemctl restart nginx
    
    print_success "phpMyAdmin installed (Port 8080)"
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
        print_info "User: root"
        print_info "Pass: $MYSQL_ROOT_PASS"
    fi
    
    press_any_key
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
    
    print_step "Creating Nginx Proxy config..."
    
    # Create Nginx config (HTTP first, let Certbot handle SSL upgrade)
    cat > "/etc/nginx/sites-available/$domain" <<EOFNGINX
server {
    listen 80;
    listen [::]:80;
    server_name $domain;

    location / {
        proxy_pass http://127.0.0.1:$CURRENT_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOFNGINX

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

    # Use certbot --nginx to automatically configure SSL and Redirect
    if ! certbot --nginx -d "$domain" --non-interactive --agree-tos --email "admin@$domain" --redirect; then
        print_error "Failed to obtain SSL certificate for $domain"
        print_info "Please check domain DNS and try again."
        return
    fi

    print_success "SSL certificate obtained and Nginx configured!"

    # Update Mongo Express config to bind to localhost only
    print_step "Securing Mongo Express (binding to localhost only)..."
    
    # Update the PM2 config to bind to localhost
    sed -i "s/ME_CONFIG_SITE_HOST: '0.0.0.0'/ME_CONFIG_SITE_HOST: 'localhost'/g" /etc/ndc-ols/mongo-express.config.js
    
    # Restart Mongo Express
    pm2 restart mongo-express --update-env
    pm2 save
    sleep 2
    
    # Close firewall port
    if command_exists ufw; then
        ufw delete allow $CURRENT_PORT/tcp 2>/dev/null || true
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-port=$CURRENT_PORT/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    print_success "Mongo Express is now fully secured with HTTPS!"
    print_info "======================================"
    print_info "✅ Access: https://$domain"
    print_info "✅ Public port $CURRENT_PORT is closed"
    print_info "✅ Only accessible via domain"
    print_info "======================================"
    
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
