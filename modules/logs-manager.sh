#!/bin/bash
# Logs Manager
source "$NDC_INSTALL_DIR/utils/colors.sh"

logs_manager_menu() {
    while true; do
        print_header "LOGS MANAGEMENT"
        echo -e " ${GREEN}1)${NC} View PM2 logs"
        echo -e " ${GREEN}2)${NC} View Nginx access log"
        echo -e " ${GREEN}3)${NC} View Nginx error log"
        echo -e " ${GREEN}4)${NC} View system log"
        echo -e " ${GREEN}5)${NC} View SSH log"
        echo -e " ${GREEN}6)${NC} Clear PM2 logs"
        echo -e " ${GREEN}7)${NC} Clear Nginx logs"
        echo -e " ${RED}0)${NC} Back"
        echo ""
        read -p "$(echo -e "${CYAN}Choice:${NC} ")" choice
        
        case $choice in
            1) pm2 logs ;;
            2) tail -100 /var/log/nginx/access.log; press_any_key ;;
            3) tail -100 /var/log/nginx/error.log; press_any_key ;;
            4) tail -100 /var/log/syslog 2>/dev/null || tail -100 /var/log/messages; press_any_key ;;
            5) tail -100 /var/log/auth.log 2>/dev/null || tail -100 /var/log/secure; press_any_key ;;
            6) pm2 flush; print_success "PM2 logs cleared"; press_any_key ;;
            7) confirm_action "Clear Nginx logs?" && > /var/log/nginx/access.log && > /var/log/nginx/error.log; press_any_key ;;
            0) return ;;
        esac
    done
}
