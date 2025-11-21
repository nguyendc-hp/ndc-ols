#!/bin/bash
#######################################
# Module: Database Manager
# Quản lý MongoDB, MySQL, Redis
#######################################

source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

db_manager_menu() {
    while true; do
        print_header "QUẢN LÝ DATABASE"
        
        echo -e " ${GREEN}1)${NC} MongoDB Manager"
        echo -e " ${GREEN}2)${NC} MySQL/MariaDB Manager"
        echo -e " ${GREEN}3)${NC} Redis Manager"
        echo -e " ${GREEN}4)${NC} Database Account Info"
        echo -e " ${GREEN}5)${NC} Backup all databases"
        echo -e " ${GREEN}6)${NC} Restore database"
        echo ""
        echo -e " ${RED}0)${NC} Back to main menu"
        echo ""
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case $choice in
            1) mongodb_menu ;;
            2) mysql_menu ;;
            3) redis_menu ;;
            4) show_db_credentials ;;
            5) backup_all_databases ;;
            6) restore_database ;;
            0) return ;;
            *) print_error "Invalid option"; sleep 2 ;;
        esac
    done
}

show_db_credentials() {
    print_header "DATABASE ACCOUNT INFO"
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
        
        echo -e "${CYAN}MongoDB Credentials:${NC}"
        echo -e "  User: ${YELLOW}$MONGODB_USER${NC}"
        echo -e "  Pass: ${YELLOW}$MONGODB_PASS${NC}"
        echo ""
        
        echo -e "${CYAN}Mongo Express GUI:${NC}"
        echo -e "  URL : ${YELLOW}http://$(get_public_ip):8081${NC}"
        echo -e "  User: ${YELLOW}$MONGO_EXPRESS_USER${NC}"
        echo -e "  Pass: ${YELLOW}$MONGO_EXPRESS_PASS${NC}"
        echo ""
        
        if [ -n "$MYSQL_ROOT_PASS" ]; then
            echo -e "${CYAN}phpMyAdmin GUI:${NC}"
            echo -e "  URL : ${YELLOW}http://$(get_public_ip):8080${NC}"
            echo -e "  User: ${YELLOW}root${NC}"
            echo -e "  Pass: ${YELLOW}$MYSQL_ROOT_PASS${NC}"
            echo ""
        fi
    else
        print_warning "No credentials file found at $NDC_CONFIG_DIR/auth.conf"
    fi
    
    # Check for phpMyAdmin if not in auth.conf
    if [ -z "$MYSQL_ROOT_PASS" ] && ([ -d "/usr/share/phpmyadmin" ] || [ -f "/etc/nginx/conf.d/phpmyadmin.conf" ]); then
        echo -e "${CYAN}phpMyAdmin GUI:${NC}"
        echo -e "  URL : ${YELLOW}http://$(get_public_ip):8080${NC}"
        echo -e "  User: ${YELLOW}root${NC}"
        echo -e "  Pass: ${RED}(Unknown - Check /root/.my.cnf or reset)${NC}"
        echo ""
    fi
    
    press_any_key
}

mongodb_menu() {
    while true; do
        print_header "MONGODB MANAGER"
        
        echo -e " ${GREEN}1)${NC} List databases"
        echo -e " ${GREEN}2)${NC} Create database & user"
        echo -e " ${GREEN}3)${NC} Drop database"
        echo -e " ${GREEN}4)${NC} Backup database"
        echo -e " ${GREEN}5)${NC} Restore database"
        echo -e " ${GREEN}6)${NC} MongoDB status"
        echo ""
        echo -e " ${RED}0)${NC} Back"
        echo ""
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case $choice in
            1) mongosh --eval "show dbs"; press_any_key ;;
            2) create_mongodb_db ;;
            3) drop_mongodb_db ;;
            4) backup_mongodb_db ;;
            5) restore_mongodb_db ;;
            6) systemctl status mongod; press_any_key ;;
            0) return ;;
        esac
    done
}

create_mongodb_db() {
    read_input "Enter database name" "" dbname
    read_input "Enter username" "" username
    read_password "Enter password" password
    
    mongosh <<EOF
use $dbname
db.createUser({
    user: "$username",
    pwd: "$password",
    roles: [{role: "readWrite", db: "$dbname"}]
})
EOF
    
    print_success "MongoDB database created: $dbname"
    press_any_key
}

drop_mongodb_db() {
    read_input "Enter database name to drop" "" dbname
    
    if confirm_action "Drop database $dbname?"; then
        mongosh --eval "use $dbname; db.dropDatabase()"
        print_success "Database dropped"
    fi
    
    press_any_key
}

backup_mongodb_db() {
    read_input "Enter database name" "" dbname
    local backup_dir="$NDC_BACKUP_DIR/mongodb_${dbname}_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$backup_dir"
    
    print_step "Backing up $dbname..."
    
    if mongodump --db="$dbname" --out="$backup_dir"; then
        tar czf "${backup_dir}.tar.gz" -C "$NDC_BACKUP_DIR" "$(basename "$backup_dir")"
        rm -rf "$backup_dir"
        print_success "Backup saved: ${backup_dir}.tar.gz"
    else
        print_error "Backup failed"
    fi
    
    press_any_key
}

restore_mongodb_db() {
    read_input "Enter database name" "" dbname
    read_input "Enter backup archive path" "" backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found!"
        press_any_key
        return
    fi
    
    if confirm_action "Restore $dbname from backup?"; then
        local temp_dir="/tmp/mongodb_restore_$$"
        mkdir -p "$temp_dir"
        tar xzf "$backup_file" -C "$temp_dir"
        
        mongorestore --db="$dbname" "$temp_dir"/*
        rm -rf "$temp_dir"
        print_success "Database restored"
    fi
    
    press_any_key
}

mysql_menu() {
    while true; do
        print_header "MYSQL/MARIADB MANAGER"
        
        echo -e " ${GREEN}1)${NC} List databases"
        echo -e " ${GREEN}2)${NC} Create database"
        echo -e " ${GREEN}3)${NC} Drop database"
        echo -e " ${GREEN}4)${NC} Create user"
        echo -e " ${GREEN}5)${NC} Backup database"
        echo -e " ${GREEN}6)${NC} Restore database"
        echo -e " ${GREEN}7)${NC} MySQL status"
        echo ""
        echo -e " ${RED}0)${NC} Back"
        echo ""
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case $choice in
            1) mysql -e "SHOW DATABASES;"; press_any_key ;;
            2) create_mysql_db ;;
            3) drop_mysql_db ;;
            4) create_mysql_user ;;
            5) backup_mysql_db ;;
            6) restore_mysql_db ;;
            7) systemctl status mariadb; press_any_key ;;
            0) return ;;
        esac
    done
}

create_mysql_db() {
    read_input "Enter database name" "" dbname
    read_input "Enter username" "" username
    read_password "Enter password" password
    
    mysql <<EOF
CREATE DATABASE $dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON $dbname.* TO '$username'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    print_success "Database created: $dbname"
    press_any_key
}

drop_mysql_db() {
    read_input "Enter database name to drop" "" dbname
    
    if confirm_action "Drop database $dbname?"; then
        mysql -e "DROP DATABASE $dbname;"
        print_success "Database dropped"
    fi
    
    press_any_key
}

create_mysql_user() {
    read_input "Enter username" "" username
    read_password "Enter password" password
    
    mysql -e "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password'; FLUSH PRIVILEGES;"
    print_success "User created: $username"
    
    press_any_key
}

backup_mysql_db() {
    read_input "Enter database name" "" dbname
    local backup_file="$NDC_BACKUP_DIR/mysql_${dbname}_$(date +%Y%m%d_%H%M%S).sql"
    
    mkdir -p "$NDC_BACKUP_DIR"
    
    print_step "Backing up $dbname..."
    
    if mysqldump "$dbname" > "$backup_file"; then
        gzip "$backup_file"
        print_success "Backup saved: ${backup_file}.gz"
    else
        print_error "Backup failed"
    fi
    
    press_any_key
}

restore_mysql_db() {
    read_input "Enter database name" "" dbname
    read_input "Enter backup file path" "" backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found!"
        press_any_key
        return
    fi
    
    if confirm_action "Restore $dbname from backup?"; then
        if [[ "$backup_file" == *.gz ]]; then
            gunzip -c "$backup_file" | mysql "$dbname"
        else
            mysql "$dbname" < "$backup_file"
        fi
        print_success "Database restored"
    fi
    
    press_any_key
}

redis_menu() {
    print_header "REDIS MANAGER"
    
    echo -e " ${GREEN}1)${NC} Redis status"
    echo -e " ${GREEN}2)${NC} Flush all keys"
    echo -e " ${GREEN}3)${NC} Redis CLI"
    echo -e " ${GREEN}4)${NC} Redis info"
    echo ""
    echo -e " ${RED}0)${NC} Back"
    echo ""
    
    read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
    
    case $choice in
        1) systemctl status redis; press_any_key ;;
        2) 
            if confirm_action "Flush all Redis keys?"; then
                redis-cli FLUSHALL
                print_success "All keys flushed"
            fi
            press_any_key
            ;;
        3) redis-cli ;;
        4) redis-cli INFO; press_any_key ;;
        0) return ;;
    esac
}

backup_all_databases() {
    print_header "BACKUP ALL DATABASES"
    
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$NDC_BACKUP_DIR/full_backup_$backup_date"
    
    mkdir -p "$backup_dir"
    
    print_step "Backing up all databases..."
    
    # MongoDB
    if command -v mongodump >/dev/null; then
        mongodump --out="$backup_dir/mongodb"
        tar czf "$backup_dir/mongodb.tar.gz" -C "$backup_dir" mongodb
        rm -rf "$backup_dir/mongodb"
    fi
    
    # MySQL
    if command -v mysqldump >/dev/null; then
        mysqldump --all-databases > "$backup_dir/mysql_all.sql"
        gzip "$backup_dir/mysql_all.sql"
    fi
    
    tar czf "${backup_dir}.tar.gz" -C "$NDC_BACKUP_DIR" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    print_success "Full backup saved: ${backup_dir}.tar.gz"
    press_any_key
}

restore_database() {
    print_header "RESTORE DATABASE"
    print_warning "Use specific database manager menus for restoration"
    press_any_key
}
