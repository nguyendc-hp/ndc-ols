#!/bin/bash
#######################################
# Module: App Manager
# Quản lý Node.js & React Apps
#######################################

source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"
source "$NDC_INSTALL_DIR/utils/validators.sh"

#######################################
# App Manager Menu
#######################################
app_manager_menu() {
    while true; do
        print_header "QUẢN LÝ APPS (NODE.JS & REACT)"
        
        echo -e " ${GREEN}1)${NC} List all apps"
        echo -e " ${GREEN}2)${NC} Start app"
        echo -e " ${GREEN}3)${NC} Stop app"
        echo -e " ${GREEN}4)${NC} Restart app"
        echo -e " ${GREEN}5)${NC} Delete app"
        echo -e " ${GREEN}6)${NC} View app logs (realtime)"
        echo -e " ${GREEN}7)${NC} View app info"
        echo -e " ${GREEN}8)${NC} Update app from Git"
        echo -e " ${GREEN}9)${NC} Rebuild app (npm install)"
        echo ""
        echo -e " ${RED}0)${NC} Back to main menu"
        echo ""
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case $choice in
            1) list_apps ;;
            2) start_app ;;
            3) stop_app ;;
            4) restart_app ;;
            5) delete_app ;;
            6) view_app_logs ;;
            7) view_app_info ;;
            8) update_app_from_git ;;
            9) rebuild_app ;;
            0) return ;;
            *) print_error "Invalid option"; sleep 2 ;;
        esac
    done
}

#######################################
# List all apps
#######################################
list_apps() {
    print_header "ALL APPS"
    
    if ! command_exists pm2; then
        print_error "PM2 not installed!"
        press_any_key
        return
    fi
    
    pm2 list
    
    echo ""
    press_any_key
}

#######################################
# Start app
#######################################
start_app() {
    print_header "START APP"
    
    read_input "Enter app name" "" app_name
    
    if [ -z "$app_name" ]; then
        print_error "App name required!"
        press_any_key
        return
    fi
    
    print_step "Starting $app_name..."
    
    if pm2 start "$app_name" 2>/dev/null; then
        print_success "App $app_name started"
        pm2 save >/dev/null 2>&1
    else
        print_error "Failed to start app"
    fi
    
    press_any_key
}

#######################################
# Stop app
#######################################
stop_app() {
    print_header "STOP APP"
    
    read_input "Enter app name" "" app_name
    
    if [ -z "$app_name" ]; then
        print_error "App name required!"
        press_any_key
        return
    fi
    
    print_step "Stopping $app_name..."
    
    if pm2 stop "$app_name" 2>/dev/null; then
        print_success "App $app_name stopped"
        pm2 save >/dev/null 2>&1
    else
        print_error "Failed to stop app"
    fi
    
    press_any_key
}

#######################################
# Restart app
#######################################
restart_app() {
    print_header "RESTART APP"
    
    read_input "Enter app name" "" app_name
    
    if [ -z "$app_name" ]; then
        print_error "App name required!"
        press_any_key
        return
    fi
    
    print_step "Restarting $app_name..."
    
    if pm2 restart "$app_name" 2>/dev/null; then
        print_success "App $app_name restarted"
        pm2 save >/dev/null 2>&1
    else
        print_error "Failed to restart app"
    fi
    
    press_any_key
}

#######################################
# Delete app
#######################################
delete_app() {
    print_header "DELETE APP"
    
    read_input "Enter app name" "" app_name
    
    if [ -z "$app_name" ]; then
        print_error "App name required!"
        press_any_key
        return
    fi
    
    if ! confirm_action "This will delete the app from PM2 (source code will NOT be deleted)"; then
        print_warning "Cancelled"
        press_any_key
        return
    fi
    
    print_step "Deleting $app_name from PM2..."
    
    if pm2 delete "$app_name" 2>/dev/null; then
        print_success "App $app_name deleted from PM2"
        pm2 save >/dev/null 2>&1
    else
        print_error "Failed to delete app"
    fi
    
    press_any_key
}

#######################################
# View app logs
#######################################
view_app_logs() {
    print_header "VIEW APP LOGS (REALTIME)"
    
    read_input "Enter app name" "" app_name
    
    if [ -z "$app_name" ]; then
        print_error "App name required!"
        press_any_key
        return
    fi
    
    print_info "Viewing logs for $app_name (Press Ctrl+C to exit)"
    sleep 2
    
    pm2 logs "$app_name"
}

#######################################
# View app info
#######################################
view_app_info() {
    print_header "APP INFO"
    
    read_input "Enter app name" "" app_name
    
    if [ -z "$app_name" ]; then
        print_error "App name required!"
        press_any_key
        return
    fi
    
    pm2 info "$app_name"
    
    echo ""
    press_any_key
}

#######################################
# Update app from Git
#######################################
update_app_from_git() {
    print_header "UPDATE APP FROM GIT"
    
    read_input "Enter app name" "" app_name
    read_input "Enter app directory path" "/var/www" app_dir
    
    if [ ! -d "$app_dir/$app_name" ]; then
        print_error "App directory not found: $app_dir/$app_name"
        press_any_key
        return
    fi
    
    cd "$app_dir/$app_name" || return
    
    print_step "Pulling latest changes from Git..."
    
    if git pull; then
        print_success "Code updated"
        
        if ask_yes_no "Install dependencies (npm install)?" "y"; then
            print_step "Installing dependencies..."
            npm install
        fi
        
        if ask_yes_no "Rebuild app (npm run build)?" "y"; then
            print_step "Building app..."
            npm run build
        fi
        
        if ask_yes_no "Restart app in PM2?" "y"; then
            pm2 restart "$app_name"
            print_success "App restarted"
        fi
    else
        print_error "Failed to pull changes"
    fi
    
    press_any_key
}

#######################################
# Rebuild app
#######################################
rebuild_app() {
    print_header "REBUILD APP"
    
    read_input "Enter app name" "" app_name
    read_input "Enter app directory path" "/var/www" app_dir
    
    if [ ! -d "$app_dir/$app_name" ]; then
        print_error "App directory not found: $app_dir/$app_name"
        press_any_key
        return
    fi
    
    cd "$app_dir/$app_name" || return
    
    print_step "Installing dependencies..."
    npm install
    
    print_step "Building app..."
    npm run build
    
    print_success "App rebuilt successfully"
    
    if ask_yes_no "Restart app in PM2?" "y"; then
        pm2 restart "$app_name"
        print_success "App restarted"
    fi
    
    press_any_key
}
