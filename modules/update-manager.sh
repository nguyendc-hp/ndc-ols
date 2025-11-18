#!/bin/bash
# Update Manager
source "$NDC_INSTALL_DIR/utils/colors.sh"

update_manager_menu() {
    while true; do
        print_header "SYSTEM UPDATE"
        echo -e " ${GREEN}1)${NC} Update package list"
        echo -e " ${GREEN}2)${NC} Upgrade all packages"
        echo -e " ${GREEN}3)${NC} Update Node.js"
        echo -e " ${GREEN}4)${NC} Update Nginx"
        echo -e " ${GREEN}5)${NC} Update PM2"
        echo -e " ${GREEN}6)${NC} Security updates only"
        echo -e " ${RED}0)${NC} Back"
        echo ""
        read -p "$(echo -e "${CYAN}Choice:${NC} ")" choice
        
        case $choice in
            1) apt-get update || dnf check-update; press_any_key ;;
            2) apt-get upgrade -y || dnf upgrade -y; press_any_key ;;
            3) export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; nvm install --lts; press_any_key ;;
            4) apt-get install --only-upgrade nginx -y || dnf upgrade nginx -y; press_any_key ;;
            5) npm install -g pm2@latest; press_any_key ;;
            6) apt-get upgrade -y --security || dnf upgrade -y --security; press_any_key ;;
            0) return ;;
        esac
    done
}
