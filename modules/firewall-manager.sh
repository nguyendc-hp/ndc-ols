#!/bin/bash
# Module: Firewall Manager
source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

firewall_manager_menu() {
    while true; do
        print_header "FIREWALL & IP MANAGEMENT"
        
        echo -e " ${GREEN}1)${NC} Firewall status"
        echo -e " ${GREEN}2)${NC} Enable firewall"
        echo -e " ${GREEN}3)${NC} Disable firewall"
        echo -e " ${GREEN}4)${NC} Block IP address"
        echo -e " ${GREEN}5)${NC} Unblock IP address"
        echo -e " ${GREEN}6)${NC} List blocked IPs"
        echo -e " ${GREEN}7)${NC} Open port"
        echo -e " ${GREEN}8)${NC} Close port"
        echo -e " ${GREEN}9)${NC} List rules"
        echo ""
        echo -e " ${RED}0)${NC} Back"
        echo ""
        
        read -p "$(echo -e "${CYAN}Choice:${NC} ")" choice
        
        case $choice in
            1) check_firewall_status ;;
            2) enable_firewall ;;
            3) disable_firewall ;;
            4) block_ip ;;
            5) unblock_ip ;;
            6) list_blocked_ips ;;
            7) open_port ;;
            8) close_port ;;
            9) list_rules ;;
            0) return ;;
        esac
    done
}

check_firewall_status() {
    if command_exists ufw; then
        ufw status
    elif command_exists firewall-cmd; then
        firewall-cmd --state
    fi
    press_any_key
}

enable_firewall() {
    if command_exists ufw; then
        ufw --force enable
    elif command_exists firewall-cmd; then
        systemctl start firewalld
        systemctl enable firewalld
    fi
    print_success "Firewall enabled"
    press_any_key
}

disable_firewall() {
    if confirm_action "Disable firewall? Server will be exposed!"; then
        if command_exists ufw; then
            ufw disable
        elif command_exists firewall-cmd; then
            systemctl stop firewalld
        fi
        print_success "Firewall disabled"
    fi
    press_any_key
}

block_ip() {
    read_input "Enter IP to block" "" ip
    if validate_ipv4 "$ip"; then
        if command_exists ufw; then
            ufw deny from "$ip"
        elif command_exists firewall-cmd; then
            firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip' reject"
            firewall-cmd --reload
        fi
        print_success "IP $ip blocked"
    fi
    press_any_key
}

unblock_ip() {
    read_input "Enter IP to unblock" "" ip
    if command_exists ufw; then
        ufw delete deny from "$ip"
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$ip' reject"
        firewall-cmd --reload
    fi
    print_success "IP $ip unblocked"
    press_any_key
}

list_blocked_ips() {
    if command_exists ufw; then
        ufw status numbered
    elif command_exists firewall-cmd; then
        firewall-cmd --list-all
    fi
    press_any_key
}

open_port() {
    read_input "Enter port to open" "" port
    if validate_port_format "$port"; then
        if command_exists ufw; then
            ufw allow "$port"/tcp
        elif command_exists firewall-cmd; then
            firewall-cmd --permanent --add-port="$port"/tcp
            firewall-cmd --reload
        fi
        print_success "Port $port opened"
    fi
    press_any_key
}

close_port() {
    read_input "Enter port to close" "" port
    if command_exists ufw; then
        ufw delete allow "$port"/tcp
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --remove-port="$port"/tcp
        firewall-cmd --reload
    fi
    print_success "Port $port closed"
    press_any_key
}

list_rules() {
    if command_exists ufw; then
        ufw status verbose
    elif command_exists firewall-cmd; then
        firewall-cmd --list-all
    fi
    press_any_key
}
