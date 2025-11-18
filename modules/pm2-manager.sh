#!/bin/bash
# Module: PM2 Manager
source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

pm2_manager_menu() {
    while true; do
        print_header "PM2 PROCESS MANAGER"
        
        echo -e " ${GREEN}1)${NC} PM2 list"
        echo -e " ${GREEN}2)${NC} PM2 monit"
        echo -e " ${GREEN}3)${NC} PM2 logs"
        echo -e " ${GREEN}4)${NC} PM2 restart all"
        echo -e " ${GREEN}5)${NC} PM2 stop all"
        echo -e " ${GREEN}6)${NC} PM2 delete all"
        echo -e " ${GREEN}7)${NC} PM2 save"
        echo -e " ${GREEN}8)${NC} PM2 startup"
        echo ""
        echo -e " ${RED}0)${NC} Back"
        echo ""
        
        read -p "$(echo -e "${CYAN}Choice:${NC} ")" choice
        
        case $choice in
            1) pm2 list; press_any_key ;;
            2) pm2 monit ;;
            3) pm2 logs ;;
            4) pm2 restart all; press_any_key ;;
            5) pm2 stop all; press_any_key ;;
            6) confirm_action "Delete all PM2 processes?" && pm2 delete all; press_any_key ;;
            7) pm2 save; print_success "Saved"; press_any_key ;;
            8) pm2 startup; press_any_key ;;
            0) return ;;
        esac
    done
}
