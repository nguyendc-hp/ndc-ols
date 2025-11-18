#!/bin/bash
# SSH Manager
source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

ssh_manager_menu() {
    while true; do
        print_header "SSH/SFTP MANAGEMENT"
        echo -e " ${GREEN}1)${NC} Change SSH port"
        echo -e " ${GREEN}2)${NC} Change root password"
        echo -e " ${GREEN}3)${NC} Setup SSH key"
        echo -e " ${GREEN}4)${NC} Disable root login"
        echo -e " ${GREEN}5)${NC} Disable password login"
        echo -e " ${GREEN}6)${NC} View SSH logs"
        echo -e " ${RED}0)${NC} Back"
        echo ""
        read -p "$(echo -e "${CYAN}Choice:${NC} ")" choice
        
        case $choice in
            1) change_ssh_port ;;
            2) passwd root; press_any_key ;;
            3) setup_ssh_key ;;
            4) disable_root_login ;;
            5) disable_password_login ;;
            6) tail -50 /var/log/auth.log 2>/dev/null || tail -50 /var/log/secure; press_any_key ;;
            0) return ;;
        esac
    done
}

change_ssh_port() {
    read_input "New SSH port" "22" new_port
    if validate_port_format "$new_port"; then
        sed -i "s/^#*Port .*/Port $new_port/" /etc/ssh/sshd_config
        systemctl restart sshd
        print_success "SSH port changed to $new_port"
        print_warning "Remember to open this port in firewall!"
    fi
    press_any_key
}

setup_ssh_key() {
    print_info "Paste your public key:"
    read -r pubkey
    mkdir -p ~/.ssh
    echo "$pubkey" >> ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys
    print_success "SSH key added"
    press_any_key
}

disable_root_login() {
    if confirm_action "Disable root SSH login?"; then
        sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
        systemctl restart sshd
        print_success "Root login disabled"
    fi
    press_any_key
}

disable_password_login() {
    if confirm_action "Disable password login? (Key-based only)"; then
        sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
        systemctl restart sshd
        print_success "Password login disabled"
    fi
    press_any_key
}
