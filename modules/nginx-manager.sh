#!/bin/bash
source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

nginx_manager_menu() {
    print_header "NGINX CONFIGURATION"
    echo " 1) Edit Nginx Config"
    echo " 2) Test Configuration"
    echo " 3) Reload Nginx"
    echo " 4) Restart Nginx"
    echo " 5) View Error Logs"
    echo " 6) Restore App Config (Fix Overwritten Config)"
    echo " 0) Back"
    
    read -p "$(echo -e "${CYAN}Enter choice:${NC} ")" choice
    case $choice in
        1) 
            read_input "Domain to edit" "" domain
            ${EDITOR:-nano} "/etc/nginx/sites-available/$domain"
            ;;
        2) nginx -t; press_any_key ;;
        3) systemctl reload nginx; print_success "Nginx reloaded"; press_any_key ;;
        4) systemctl restart nginx; print_success "Nginx restarted"; press_any_key ;;
        5) tail -f /var/log/nginx/error.log ;;
        6) restore_app_config ;;
        *) return ;;
    esac
}

restore_app_config() {
    print_header "RESTORE APP CONFIGURATION"
    print_info "Use this if you accidentally overwrote your app's Nginx config."
    
    read_input "Domain to restore" "" domain
    read_input "App Name (folder in /var/www)" "" app_name
    read_input "Backend Port" "8080" backend_port
    
    local app_root="/var/www/$app_name"
    local frontend_dir="frontend"
    local build_dir="dist"
    
    # Check directories
    if [ ! -d "$app_root" ]; then
        print_error "App directory not found: $app_root"
        return
    fi
    
    if [ ! -d "$app_root/frontend/dist" ] && [ -d "$app_root/frontend/build" ]; then
        build_dir="build"
    fi
    
    print_step "Restoring Nginx config for $domain..."
    
    cat > "/etc/nginx/sites-available/$domain" <<EOF
server {
    listen 80;
    server_name $domain www.$domain;

    root $app_root/$frontend_dir/$build_dir;
    index index.html;

    # Frontend
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API Proxy
    location /api/ {
        proxy_pass http://localhost:$backend_port/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    # Enable site
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    
    # Test and reload
    if nginx -t; then
        systemctl reload nginx
        print_success "Configuration restored!"
        
        if ask_yes_no "Reinstall SSL (HTTPS)?" "y"; then
            certbot --nginx -d "$domain" --non-interactive --agree-tos --email "admin@$domain" --redirect
        fi
    else
        print_error "Nginx configuration failed test!"
    fi
    
    press_any_key
}
