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
    echo " 0) Back"
    
    read -p "$(echo -e "${CYAN}Enter choice:${NC} ")" choice
    case $choice in
        1) install_mongo_express ;;
        *) return ;;
    esac
}

install_mongo_express() {
    print_step "Installing Mongo Express..."
    
    # Check if MongoDB is installed
    if ! command_exists mongod; then
        print_error "MongoDB is not installed!"
        return
    fi
    
    # Get config
    read_input "GUI Username" "admin" gui_user
    read_input "GUI Password" "$(generate_password)" gui_pass
    read_input "Port" "8081" port
    
    # Install
    npm install -g mongo-express
    
    # Get mongo-express path for CWD
    MONGO_EXPRESS_HOME="$(npm root -g)/mongo-express"
    
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
      PORT: '$port',
      VCAP_APP_PORT: '$port'
    }
  }]
};
EOF

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
