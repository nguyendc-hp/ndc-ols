#!/bin/bash
#######################################
# Module: SSL Manager
# Quản lý SSL/TLS certificates
#######################################

source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"
source "$NDC_INSTALL_DIR/utils/validators.sh"

ssl_manager_menu() {
    while true; do
        print_header "QUẢN LÝ SSL (LET'S ENCRYPT)"
        
        echo -e " ${GREEN}1)${NC} Install SSL for domain"
        echo -e " ${GREEN}2)${NC} Renew SSL certificates"
        echo -e " ${GREEN}3)${NC} List all SSL certificates"
        echo -e " ${GREEN}4)${NC} Remove SSL for domain"
        echo -e " ${GREEN}5)${NC} Force HTTPS redirect"
        echo -e " ${GREEN}6)${NC} Check SSL status"
        echo ""
        echo -e " ${RED}0)${NC} Back to main menu"
        echo ""
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case $choice in
            1) install_ssl ;;
            2) renew_ssl ;;
            3) list_ssl ;;
            4) remove_ssl ;;
            5) force_https ;;
            6) check_ssl ;;
            0) return ;;
            *) print_error "Invalid option"; sleep 2 ;;
        esac
    done
}

install_ssl() {
    print_header "INSTALL SSL CERTIFICATE"
    
    read_input "Enter domain name" "" domain
    read_input "Enter email for Let's Encrypt" "" email
    
    if ! validate_domain_format "$domain" || ! validate_email_format "$email"; then
        press_any_key
        return
    fi
    
    print_step "Installing SSL for $domain..."
    
    if certbot --nginx -d "$domain" -d "www.$domain" --email "$email" --agree-tos --no-eff-email --redirect; then
        print_success "SSL installed successfully!"
        print_info "Auto-renewal is configured"
    else
        print_error "Failed to install SSL"
    fi
    
    press_any_key
}

renew_ssl() {
    print_header "RENEW SSL CERTIFICATES"
    
    print_step "Renewing all SSL certificates..."
    
    if certbot renew; then
        print_success "Certificates renewed"
        systemctl reload nginx
    else
        print_error "Failed to renew"
    fi
    
    press_any_key
}

list_ssl() {
    print_header "SSL CERTIFICATES"
    
    certbot certificates
    
    echo ""
    press_any_key
}

remove_ssl() {
    print_header "REMOVE SSL"
    
    read_input "Enter domain name" "" domain
    
    if confirm_action "Remove SSL for $domain?"; then
        certbot delete --cert-name "$domain"
        print_success "SSL removed"
    fi
    
    press_any_key
}

force_https() {
    print_header "FORCE HTTPS REDIRECT"
    
    read_input "Enter domain name" "" domain
    
    local conf="/etc/nginx/sites-available/$domain"
    [ ! -f "$conf" ] && conf="/etc/nginx/conf.d/$domain.conf"
    
    if [ -f "$conf" ]; then
        if ! grep -q "return 301 https" "$conf"; then
            sed -i '/listen 80;/a\    return 301 https://$server_name$request_uri;' "$conf"
            nginx -t && systemctl reload nginx
            print_success "HTTPS redirect enabled"
        else
            print_warning "HTTPS redirect already enabled"
        fi
    else
        print_error "Domain config not found"
    fi
    
    press_any_key
}

check_ssl() {
    print_header "CHECK SSL STATUS"
    
    read_input "Enter domain name" "" domain
    
    print_step "Checking SSL for $domain..."
    
    if command -v openssl >/dev/null; then
        echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates
    else
        certbot certificates | grep -A 10 "$domain"
    fi
    
    echo ""
    press_any_key
}
