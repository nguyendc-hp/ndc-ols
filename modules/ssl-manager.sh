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
        print_header "QUẢN LÝ SSL - Cài đặt SSL FREE Let's Encrypt"
        
        echo -e " ${GREEN}1)${NC} Cài đặt SSL cho domain"
        echo -e " ${GREEN}2)${NC} Gia hạn chứng chỉ SSL"
        echo -e " ${GREEN}3)${NC} Danh sách chứng chỉ SSL"
        echo -e " ${GREEN}4)${NC} Xóa SSL cho domain"
        echo -e " ${GREEN}5)${NC} Bắt buộc HTTPS redirect"
        echo -e " ${GREEN}6)${NC} Kiểm tra trạng thái SSL"
        echo ""
        echo -e " ${RED}0)${NC} Quay lại menu chính"
        echo ""
        
        read -p "$(echo -e "${CYAN}Nhập lựa chọn của bạn [0-6]:${NC} ")" choice
        echo ""
        
        case $choice in
            1) install_ssl ;;
            2) renew_ssl ;;
            3) list_ssl ;;
            4) remove_ssl ;;
            5) force_https ;;
            6) check_ssl ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ"; sleep 2 ;;
        esac
    done
}

install_ssl() {
    print_header "CÀI ĐẶT CHỨNG CHỈ SSL"
    
    # List available domains from Nginx config
    print_info "Danh sách domain có sẵn:"
    local domains=()
    
    # Use nginx -T to get full config and parse server_name
    # This is more reliable than parsing files directly
    if command -v nginx >/dev/null; then
        # Get all server_names, remove duplicates, remove default/localhost/ip
        while read -r domain; do
            if [[ ! " ${domains[*]} " =~ " ${domain} " ]]; then
                domains+=("$domain")
            fi
        done < <(nginx -T 2>/dev/null | grep -E "^\s*server_name\s+" | sed 's/^\s*server_name\s*//;s/;//;s/\s/\n/g' | grep -vE "^_$" | grep -vE "^localhost$" | grep -vE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" | grep -vE "^www\." | sort -u)
    fi

    # Display domains
    if [ ${#domains[@]} -gt 0 ]; then
        for ((j=0; j<${#domains[@]}; j++)); do
            echo -e " ${GREEN}$((j+1)))${NC} ${domains[$j]}"
        done
    fi
    
    if [ ${#domains[@]} -eq 0 ]; then
        print_warning "Không tìm thấy domain nào được cấu hình trong Nginx."
        read_input "Nhập tên domain thủ công" "" domain
    else
        echo ""
        read -p "$(echo -e "${CYAN}Lựa chọn domain (1-${#domains[@]}) hoặc nhập thủ công [0=Thoát]:${NC} ")" selection
        
        if [[ "$selection" == "0" ]]; then
            print_warning "Đã hủy"
            press_any_key
            return
        elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#domains[@]}" ]; then
            domain="${domains[$((selection-1))]}"
            print_info "Đã chọn domain: $domain"
        else
            domain="$selection"
        fi
    fi
    
    read_input "Nhập email cho Let's Encrypt" "" email
    
    if ! validate_domain_format "$domain" || ! validate_email_format "$email"; then
        press_any_key
        return
    fi
    
    print_step "Đang cài đặt SSL cho $domain..."
    
    # Check if www subdomain exists in DNS
    local domain_args="-d $domain"
    if host "www.$domain" >/dev/null 2>&1; then
        domain_args="$domain_args -d www.$domain"
        print_info "Bao gồm www.$domain"
    fi
    
    if certbot --nginx $domain_args --email "$email" --agree-tos --no-eff-email --redirect; then
        print_success "SSL đã được cài đặt thành công!"
        print_info "Gia hạn tự động đã được cấu hình"
    else
        print_error "Không thể cài đặt SSL"
        print_info "Vui lòng kiểm tra xem domain có trỏ đến địa chỉ IP server không"
    fi
    
    press_any_key
}

renew_ssl() {
    print_header "GIA HẠN CHỨNG CHỈ SSL"
    
    print_step "Đang gia hạn tất cả chứng chỉ SSL..."
    
    if certbot renew; then
        print_success "Chứng chỉ đã được gia hạn"
        systemctl reload nginx
    else
        print_error "Không thể gia hạn"
    fi
    
    press_any_key
}

list_ssl() {
    print_header "DANH SÁCH CHỨNG CHỈ SSL"
    
    certbot certificates
    
    echo ""
    press_any_key
}

remove_ssl() {
    print_header "XÓA SSL"
    
    read_input "Nhập tên domain" "" domain
    
    if confirm_action "Xóa SSL cho $domain?"; then
        certbot delete --cert-name "$domain"
        print_success "SSL đã được xóa"
    fi
    
    press_any_key
}

force_https() {
    print_header "BẮT BUỘC HTTPS REDIRECT"
    
    read_input "Nhập tên domain" "" domain
    
    local conf="/etc/nginx/sites-available/$domain"
    [ ! -f "$conf" ] && conf="/etc/nginx/conf.d/$domain.conf"
    
    if [ -f "$conf" ]; then
        if ! grep -q "return 301 https" "$conf"; then
            sed -i '/listen 80;/a\    return 301 https://$server_name$request_uri;' "$conf"
            nginx -t && systemctl reload nginx
            print_success "HTTPS redirect đã được bật"
        else
            print_warning "HTTPS redirect đã được bật rồi"
        fi
    else
        print_error "Không tìm thấy cấu hình domain"
    fi
    
    press_any_key
}

check_ssl() {
    print_header "KIỂM TRA TRẠNG THÁI SSL"
    
    read_input "Nhập tên domain" "" domain
    
    print_step "Đang kiểm tra SSL cho $domain..."
    
    if command -v openssl >/dev/null; then
        echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates
    else
        certbot certificates | grep -A 10 "$domain"
    fi
    
    echo ""
    press_any_key
}
