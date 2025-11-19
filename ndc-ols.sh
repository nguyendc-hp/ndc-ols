#!/bin/bash
#######################################
# NDC OLS - Main Script
# Node & React VPS Management Tool
# Version: 1.0.0
# Author: NDC OLS Team
#######################################

# Global variables
export NDC_VERSION="1.0.0"
export NDC_INSTALL_DIR="/usr/local/ndc-ols"
export NDC_CONFIG_DIR="/etc/ndc-ols"
export NDC_APPS_DIR="/var/www"
export NDC_LOG_DIR="/var/log/ndc-ols"
export NDC_BACKUP_DIR="/var/backups/ndc-ols"
export NDC_LOG_FILE="$NDC_LOG_DIR/ndc-ols.log"

# Source utilities
source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"
source "$NDC_INSTALL_DIR/utils/validators.sh"

#######################################
# Show banner
#######################################
show_banner() {
    clear
    printf "%b" "${CYAN}"
    printf "%b" "+-----------------------------------------------------------------------+\n"
    printf "%b" "|                                                                       |\n"
    printf "%b" "|                       ${BOLD}NDC OLS${CYAN} phiên bản: ${BOLD}$NDC_VERSION${CYAN}                        |\n"
    printf "%b" "|                  Công cụ quản lý VPS Node.js & React                  |\n"
    printf "%b" "|                                                                       |\n"
    printf "%b" "+-----------------------------------------------------------------------+\n"
    printf "%b" "Chúc bạn có buổi chiều tuyệt vời - Chào mừng bạn đến với NDC OLS\n"
    printf "%b" "-------------------------------------------------------------------------\n"
    printf "%b" "${NC}"
}

#######################################
# Show system info bar
#######################################
show_system_info() {
    local cpu_cores=$(get_cpu_cores)
    local total_ram=$(get_total_ram)
    local free_disk=$(get_free_disk)
    local public_ip=$(get_public_ip)
    local uptime=$(uptime -p | sed 's/up //;s/days/ngày/;s/hours/giờ/;s/minutes/phút/')
    local ram_usage=$(free -m | awk '/Mem:/ { printf("%d/%dMB (%.2f%%)", $3, $2, $3*100/$2) }')
    local disk_usage=$(df -h / | awk 'NR==2 { printf("%d/%dGB (%s)", $3, $2, $5) }' | sed 's/G//g')
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')

    printf "%b" "CPU : ${GREEN}${cpu_usage}${NC} | Ram : ${GREEN}${ram_usage}${NC} | Disk: ${GREEN}${disk_usage}${NC}\n"
    printf "%b" "${CYAN}-------------------------------------------------------------------------${NC}\n"
    printf "%b" "Webserver Nginx         : ${GREEN}Hoạt động tốt${NC}\n"
    printf "%b" "MongoDB                 : ${GREEN}Hoạt động tốt${NC}\n"
    printf "%b" "Tình trạng máy chủ      : ${GREEN}Hoạt động tốt${NC}\n"
    printf "%b" "System uptime           : ${GREEN}${uptime}${NC}\n"
    printf "%b" "${CYAN}-------------------------------------------------------------------------${NC}\n"
    printf "%b" "Tài liệu hướng dẫn      : ${CYAN}https://github.com/nguyendc-hp/ndc-ols${NC}\n"
    printf "%b" "Nhà phát triển          : ${CYAN}Nguyen DC${NC}\n"
    printf "%b" "Phiên bản hiện tại      : ${CYAN}${NDC_VERSION}${NC}\n"
    printf "%b" "${CYAN}-------------------------------------------------------------------------${NC}\n"
    printf "%b" "Nhập lệnh phím ${GREEN}1${NC} để vào menu quản trị Apps\n"
    printf "%b" "Nhập lệnh phím ${GREEN}0${NC} để thoát chương trình\n"
    printf "%b" "${CYAN}-------------------------------------------------------------------------${NC}\n"
    printf "%b" "${CYAN}=========================================================================${NC}\n"
    printf "%b" "Thông báo Cập nhật - Bạn đang sử dụng NDC OLS phiên bản:  ${BOLD}${NDC_VERSION}${NC}\n"
    printf "%b" "${CYAN}=========================================================================${NC}\n"
    printf "%b" "Phát triển bởi: Nguyen DC (nguyendc-hp)\n"
    printf "%b" "Tài trợ dự án: https://github.com/sponsors/nguyendc-hp\n"
    printf "%b" "${CYAN}=========================================================================${NC}\n"
    echo ""
}

#######################################
# Show system info bar
#######################################
show_system_info() {
    local cpu_cores=$(get_cpu_cores)
    local total_ram=$(get_total_ram)
    local free_disk=$(get_free_disk)
    local public_ip=$(get_public_ip)
    
    printf "%b" "${CYAN}-----------------------------------------------------------------------\n${NC}"
    printf "%b" "${GREEN}Tình trạng máy chủ: Hoạt động tốt${NC}\n"
    printf "%b" "${CYAN}-----------------------------------------------------------------------\n${NC}"
    printf "%b" "Server IP: ${GREEN}$public_ip${NC} | CPU: ${GREEN}${cpu_cores} cores${NC} | RAM: ${GREEN}${total_ram}GB${NC} | Disk: ${GREEN}${free_disk}GB${NC}\n"
    echo ""
}

#######################################
# Main menu
#######################################
show_main_menu() {
    show_banner
    show_system_info
    
    echo ""
    echo -e " ${GREEN}1)${NC}  Quản lý Apps (Node/React)     ${GREEN}16)${NC} Nhân bản dự án"
    echo -e " ${GREEN}2)${NC}  Quản lý Domain                ${GREEN}17)${NC} Quản lý mã nguồn"
    echo -e " ${GREEN}3)${NC}  Quản lý SSL                   ${GREEN}18)${NC} Phân quyền files/folder"
    echo -e " ${GREEN}4)${NC}  Quản lý Database              ${GREEN}19)${NC} Quản lý Cache (Redis)"
    echo -e " ${GREEN}5)${NC}  Sao lưu & Khôi phục           ${GREEN}20)${NC} Thông tin Credentials"
    echo -e " ${GREEN}6)${NC}  Tải mã nguồn ứng dụng         ${GREEN}21)${NC} Thông tin Server"
    echo -e " ${GREEN}7)${NC}  Quản lý Service (PM2)         ${GREEN}22)${NC} Bảo mật & Tường lửa"
    echo -e " ${GREEN}8)${NC}  Quản lý Mở/Khóa IP            ${GREEN}23)${NC} Cập nhật NDC OLS"
    echo -e " ${GREEN}9)${NC}  Quản lý SSH/SFTP              ${GREEN}24)${NC} Quản lý PhpMyAdmin"
    echo -e " ${GREEN}10)${NC} Cập nhật Webserver            ${GREEN}25)${NC} Báo lỗi"
    echo -e " ${GREEN}11)${NC} Cấu hình Cache                ${GREEN}26)${NC} Quản lý Swap/Memory"
    echo -e " ${GREEN}12)${NC} Cấu hình Nginx                ${GREEN}27)${NC} Chuyển website"
    echo -e " ${GREEN}13)${NC} Biến môi trường               ${GREEN}28)${NC} Quản lý File Manager"
    echo -e " ${GREEN}14)${NC} Quản lý Node.js               ${GREEN}29)${NC} Quản lý tài nguyên server"
    echo -e " ${GREEN}15)${NC} Quản lý Logs                  ${GREEN}30)${NC} Tài trợ dự án"
    echo ""
    echo -e " ${RED}0)${NC}  Thoát"
    echo ""
}

#######################################
# Handle menu choice
#######################################
handle_menu_choice() {
    local choice=$1
    
    case $choice in
        1)  source "$NDC_INSTALL_DIR/modules/app-manager.sh" && app_manager_menu ;;
        2)  source "$NDC_INSTALL_DIR/modules/domain-manager.sh" && domain_manager_menu ;;
        3)  source "$NDC_INSTALL_DIR/modules/ssl-manager.sh" && ssl_manager_menu ;;
        4)  source "$NDC_INSTALL_DIR/modules/db-manager.sh" && db_manager_menu ;;
        5)  source "$NDC_INSTALL_DIR/modules/backup-manager.sh" && backup_manager_menu ;;
        6)  source "$NDC_INSTALL_DIR/modules/deploy-manager.sh" && deploy_manager_menu ;;
        7)  source "$NDC_INSTALL_DIR/modules/pm2-manager.sh" && pm2_manager_menu ;;
        8)  source "$NDC_INSTALL_DIR/modules/firewall-manager.sh" && firewall_manager_menu ;;
        9)  source "$NDC_INSTALL_DIR/modules/ssh-manager.sh" && ssh_manager_menu ;;
        10) source "$NDC_INSTALL_DIR/modules/update-manager.sh" && update_manager_menu ;;
        11) source "$NDC_INSTALL_DIR/modules/cache-manager.sh" && cache_manager_menu ;;
        12) source "$NDC_INSTALL_DIR/modules/nginx-manager.sh" && nginx_manager_menu ;;
        13) source "$NDC_INSTALL_DIR/modules/env-manager.sh" && env_manager_menu ;;
        14) source "$NDC_INSTALL_DIR/modules/node-manager.sh" && node_manager_menu ;;
        15) source "$NDC_INSTALL_DIR/modules/logs-manager.sh" && logs_manager_menu ;;
        16) source "$NDC_INSTALL_DIR/modules/clone-manager.sh" && clone_manager_menu ;;
        17) source "$NDC_INSTALL_DIR/modules/source-manager.sh" && source_manager_menu ;;
        18) source "$NDC_INSTALL_DIR/modules/permission-manager.sh" && permission_manager_menu ;;
        19) source "$NDC_INSTALL_DIR/modules/redis-manager.sh" && redis_manager_menu ;;
        20) source "$NDC_INSTALL_DIR/modules/info-manager.sh" && show_credentials_info ;;
        21) source "$NDC_INSTALL_DIR/modules/info-manager.sh" && show_server_info ;;
        22) source "$NDC_INSTALL_DIR/modules/security-manager.sh" && security_manager_menu ;;
        23) source "$NDC_INSTALL_DIR/modules/self-update.sh" && self_update_menu ;;
        24) source "$NDC_INSTALL_DIR/modules/gui-manager.sh" && gui_manager_menu ;;
        25) source "$NDC_INSTALL_DIR/modules/support-manager.sh" && support_manager_menu ;;
        26) source "$NDC_INSTALL_DIR/modules/swap-manager.sh" && swap_manager_menu ;;
        27) source "$NDC_INSTALL_DIR/modules/migration-manager.sh" && migration_manager_menu ;;
        28) source "$NDC_INSTALL_DIR/modules/filemanager.sh" && filemanager_menu ;;
        29) source "$NDC_INSTALL_DIR/modules/monitor-manager.sh" && monitor_manager_menu ;;
        30) source "$NDC_INSTALL_DIR/modules/donate.sh" && donate_menu ;;
        0)  exit_program ;;
        *)  print_error "Invalid option. Please choose 0-30."
            sleep 2
            ;;
    esac
}

#######################################
# Exit program
#######################################
exit_program() {
    clear
    echo ""
    print_success "Thank you for using NDC OLS!"
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Support the project:${NC} ${UCYAN}https://github.com/ndc-ols${NC}     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Star us on GitHub${NC} ⭐  |  ${BOLD}Report issues${NC} 🐛           ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
}

#######################################
# Check if NDC OLS is installed
#######################################
check_installation() {
    if [ ! -d "$NDC_INSTALL_DIR" ]; then
        print_error "NDC OLS is not installed!"
        print_info "Please run the installation script first:"
        echo ""
        echo "  curl -sO https://raw.githubusercontent.com/nguyendc-hp/ndc-ols/main/install.sh && bash install.sh"
        echo ""
        exit 1
    fi
}

#######################################
# Initialize
#######################################
initialize() {
    # Create log directory if not exists
    create_dir "$NDC_LOG_DIR"
    
    # Create log file if not exists
    touch "$NDC_LOG_FILE" 2>/dev/null || true
    
    # Log startup
    log_info "NDC OLS started (version $NDC_VERSION)"
}

#######################################
# Main loop
#######################################
main() {
    # Check root
    check_root
    
    # Check installation
    check_installation
    
    # Initialize
    initialize
    
    # Check for arguments
    if [[ "$1" == "--info" ]]; then
        show_banner
        show_system_info
        exit 0
    fi
    
    # Main loop
    while true; do
        show_main_menu
        read -p "$(echo -e "${CYAN}Nhập lựa chọn của bạn (1-30) [0=Thoát]:${NC} ")" choice
        echo ""
        handle_menu_choice "$choice"
    done
}

# Run main
main "$@"
