#!/bin/bash
# Node Manager
source "$NDC_INSTALL_DIR/utils/colors.sh"

node_manager_menu() {
    while true; do
        print_header "NODE.JS VERSION MANAGER"
        echo -e " ${GREEN}1)${NC} List installed versions"
        echo -e " ${GREEN}2)${NC} Install new version"
        echo -e " ${GREEN}3)${NC} Uninstall version"
        echo -e " ${GREEN}4)${NC} Set default version"
        echo -e " ${GREEN}5)${NC} Current version"
        echo -e " ${GREEN}6)${NC} Update npm"
        echo -e " ${RED}0)${NC} Back"
        echo ""
        read -p "$(echo -e "${CYAN}Choice:${NC} ")" choice
        
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        case $choice in
            1) nvm list; press_any_key ;;
            2) read_input "Version (e.g., 18, lts)" "lts" ver; nvm install "$ver"; press_any_key ;;
            3) read_input "Version to uninstall" "" ver; nvm uninstall "$ver"; press_any_key ;;
            4) read_input "Set default version" "lts/*" ver; nvm alias default "$ver"; press_any_key ;;
            5) node -v; npm -v; press_any_key ;;
            6) npm install -g npm@latest; press_any_key ;;
            0) return ;;
        esac
    done
}
