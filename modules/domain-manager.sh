#!/bin/bash
#######################################
# Module: Domain Manager
# Quản lý domains và Nginx vhosts
#######################################

source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"
source "$NDC_INSTALL_DIR/utils/validators.sh"

#######################################
# Domain Manager Menu
#######################################
domain_manager_menu() {
    while true; do
        print_header "QUẢN LÝ DOMAIN"
        
        echo -e " ${GREEN}1)${NC} List all domains"
        echo -e " ${GREEN}2)${NC} Add new domain"
        echo -e " ${GREEN}3)${NC} Remove domain"
        echo -e " ${GREEN}4)${NC} View domain config"
        echo -e " ${GREEN}5)${NC} Edit domain config"
        echo -e " ${GREEN}6)${NC} Test Nginx config"
        echo -e " ${GREEN}7)${NC} Reload Nginx"
        echo ""
        echo -e " ${RED}0)${NC} Back to main menu"
        echo ""
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case $choice in
            1) list_domains ;;
            2) add_domain ;;
            3) remove_domain ;;
            4) view_domain_config ;;
            5) edit_domain_config ;;
            6) test_nginx_config ;;
            7) reload_nginx ;;
            0) return ;;
            *) print_error "Invalid option"; sleep 2 ;;
        esac
    done
}

#######################################
# List all domains
#######################################
list_domains() {
    print_header "ALL DOMAINS"
    
    if [ ! -d "/etc/nginx/sites-enabled" ] && [ ! -d "/etc/nginx/conf.d" ]; then
        print_error "Nginx not installed or configured!"
        press_any_key
        return
    fi
    
    echo -e "${BOLD}Enabled domains:${NC}"
    echo ""
    
    local count=0
    if [ -d "/etc/nginx/sites-enabled" ]; then
        for conf in /etc/nginx/sites-enabled/*; do
            if [ -f "$conf" ] && [ ! -L "$conf" ] || [ -L "$conf" ]; then
                local domain=$(basename "$conf")
                if [ "$domain" != "default" ]; then
                    count=$((count + 1))
                    echo -e "  ${GREEN}$count)${NC} $domain"
                fi
            fi
        done
    fi
    
    if [ -d "/etc/nginx/conf.d" ]; then
        for conf in /etc/nginx/conf.d/*.conf; do
            if [ -f "$conf" ]; then
                local domain=$(basename "$conf" .conf)
                if [ "$domain" != "default" ]; then
                    count=$((count + 1))
                    echo -e "  ${GREEN}$count)${NC} $domain"
                fi
            fi
        done
    fi
    
    if [ $count -eq 0 ]; then
        print_warning "No domains configured yet"
    fi
    
    echo ""
    press_any_key
}

#######################################
# Add domain
#######################################
add_domain() {
    print_header "ADD NEW DOMAIN"
    
    # Get domain name
    while true; do
        read_input "Enter domain name (e.g., example.com)" "" domain
        if validate_domain_format "$domain"; then
            break
        fi
    done
    
    # Get app type
    echo ""
    echo "Select app type:"
    echo "  1) Node.js API (Express, Fastify, etc.)"
    echo "  2) React App (Static build)"
    echo "  3) Next.js (SSR)"
    echo "  4) Static website"
    echo ""
    read_input "Enter choice [1-4]" "1" app_type
    
    case $app_type in
        1) add_nodejs_domain "$domain" ;;
        2) add_react_domain "$domain" ;;
        3) add_nextjs_domain "$domain" ;;
        4) add_static_domain "$domain" ;;
        *) print_error "Invalid choice"; press_any_key; return ;;
    esac
}

#######################################
# Add Node.js domain
#######################################
add_nodejs_domain() {
    local domain=$1
    
    read_input "Enter app port" "3000" port
    
    if ! validate_port_format "$port"; then
        press_any_key
        return
    fi
    
    local nginx_conf="/etc/nginx/sites-available/$domain"
    local www_dir="/var/www/$domain"
    
    # Create directory
    mkdir -p "$www_dir"
    
    # Create Nginx config
    cat > "$nginx_conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    location / {
        proxy_pass http://localhost:$port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
    
    # Enable site
    ln -sf "$nginx_conf" "/etc/nginx/sites-enabled/$domain" 2>/dev/null || \
    ln -sf "$nginx_conf" "/etc/nginx/conf.d/$domain.conf"
    
    # Test and reload
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Domain $domain added successfully!"
        print_info "Remember to:"
        echo "  - Point DNS A record to your server IP"
        echo "  - Run SSL setup (option 3 in main menu)"
        echo "  - Start your Node.js app on port $port"
    else
        print_error "Nginx config test failed!"
        rm -f "$nginx_conf"
        rm -f "/etc/nginx/sites-enabled/$domain"
    fi
    
    press_any_key
}

#######################################
# Add React domain
#######################################
add_react_domain() {
    local domain=$1
    local www_dir="/var/www/$domain"
    local nginx_conf="/etc/nginx/sites-available/$domain"
    
    # Create directory
    mkdir -p "$www_dir/public"
    
    # Create Nginx config
    cat > "$nginx_conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $www_dir/public;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
    
    # Enable site
    ln -sf "$nginx_conf" "/etc/nginx/sites-enabled/$domain" 2>/dev/null || \
    ln -sf "$nginx_conf" "/etc/nginx/conf.d/$domain.conf"
    
    # Test and reload
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Domain $domain added successfully!"
        print_info "Upload your React build files to: $www_dir/public"
        print_info "Remember to setup SSL (option 3 in main menu)"
    else
        print_error "Nginx config test failed!"
        rm -f "$nginx_conf"
    fi
    
    press_any_key
}

#######################################
# Add Next.js domain
#######################################
add_nextjs_domain() {
    local domain=$1
    
    read_input "Enter Next.js port" "3000" port
    
    local nginx_conf="/etc/nginx/sites-available/$domain"
    
    cat > "$nginx_conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    location / {
        proxy_pass http://localhost:$port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    location /_next/static {
        proxy_pass http://localhost:$port;
        proxy_cache STATIC;
        proxy_cache_valid 60m;
    }
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
    
    ln -sf "$nginx_conf" "/etc/nginx/sites-enabled/$domain" 2>/dev/null || \
    ln -sf "$nginx_conf" "/etc/nginx/conf.d/$domain.conf"
    
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Domain $domain added for Next.js!"
    else
        print_error "Nginx config test failed!"
    fi
    
    press_any_key
}

#######################################
# Add static domain
#######################################
add_static_domain() {
    local domain=$1
    local www_dir="/var/www/$domain"
    local nginx_conf="/etc/nginx/sites-available/$domain"
    
    mkdir -p "$www_dir/public"
    
    cat > "$nginx_conf" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    root $www_dir/public;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    access_log /var/log/nginx/${domain}_access.log;
    error_log /var/log/nginx/${domain}_error.log;
}
EOF
    
    ln -sf "$nginx_conf" "/etc/nginx/sites-enabled/$domain" 2>/dev/null || \
    ln -sf "$nginx_conf" "/etc/nginx/conf.d/$domain.conf"
    
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Domain $domain added!"
        print_info "Upload files to: $www_dir/public"
    else
        print_error "Nginx config test failed!"
    fi
    
    press_any_key
}

#######################################
# Remove domain
#######################################
remove_domain() {
    print_header "REMOVE DOMAIN"
    
    read_input "Enter domain name" "" domain
    
    if [ -z "$domain" ]; then
        print_error "Domain required!"
        press_any_key
        return
    fi
    
    if ! confirm_action "Remove domain $domain?"; then
        press_any_key
        return
    fi
    
    # Remove configs
    rm -f "/etc/nginx/sites-available/$domain"
    rm -f "/etc/nginx/sites-enabled/$domain"
    rm -f "/etc/nginx/conf.d/$domain.conf"
    
    # Reload nginx
    nginx -t && systemctl reload nginx
    
    print_success "Domain $domain removed"
    
    if ask_yes_no "Remove website files in /var/www/$domain?" "n"; then
        rm -rf "/var/www/$domain"
        print_success "Files removed"
    fi
    
    press_any_key
}

#######################################
# View domain config
#######################################
view_domain_config() {
    print_header "VIEW DOMAIN CONFIG"
    
    read_input "Enter domain name" "" domain
    
    local conf="/etc/nginx/sites-available/$domain"
    [ ! -f "$conf" ] && conf="/etc/nginx/conf.d/$domain.conf"
    
    if [ -f "$conf" ]; then
        cat "$conf"
    else
        print_error "Config not found for domain: $domain"
    fi
    
    echo ""
    press_any_key
}

#######################################
# Edit domain config
#######################################
edit_domain_config() {
    print_header "EDIT DOMAIN CONFIG"
    
    read_input "Enter domain name" "" domain
    
    local conf="/etc/nginx/sites-available/$domain"
    [ ! -f "$conf" ] && conf="/etc/nginx/conf.d/$domain.conf"
    
    if [ -f "$conf" ]; then
        backup_file "$conf"
        ${EDITOR:-nano} "$conf"
        
        if nginx -t 2>/dev/null; then
            systemctl reload nginx
            print_success "Config updated and Nginx reloaded"
        else
            print_error "Config has errors! Please fix them."
        fi
    else
        print_error "Config not found for domain: $domain"
    fi
    
    press_any_key
}

#######################################
# Test nginx config
#######################################
test_nginx_config() {
    print_header "TEST NGINX CONFIG"
    
    nginx -t
    
    echo ""
    press_any_key
}

#######################################
# Reload nginx
#######################################
reload_nginx() {
    print_header "RELOAD NGINX"
    
    if nginx -t 2>/dev/null; then
        systemctl reload nginx
        print_success "Nginx reloaded successfully"
    else
        print_error "Nginx config has errors!"
    fi
    
    press_any_key
}
