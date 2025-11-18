#!/bin/bash
#######################################
# Module: Backup Manager
# Backup & Restore system
#######################################

source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

backup_manager_menu() {
    while true; do
        print_header "BACKUP & RESTORE"
        
        echo -e " ${GREEN}1)${NC} Backup app (code + database)"
        echo -e " ${GREEN}2)${NC} Restore app from backup"
        echo -e " ${GREEN}3)${NC} List backups"
        echo -e " ${GREEN}4)${NC} Delete old backups"
        echo -e " ${GREEN}5)${NC} Setup auto backup schedule"
        echo -e " ${GREEN}6)${NC} Cloud backup setup (Rclone)"
        echo -e " ${GREEN}7)${NC} Manual full system backup"
        echo ""
        echo -e " ${RED}0)${NC} Back to main menu"
        echo ""
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case $choice in
            1) backup_app ;;
            2) restore_app ;;
            3) list_backups ;;
            4) delete_old_backups ;;
            5) setup_auto_backup ;;
            6) setup_cloud_backup ;;
            7) full_system_backup ;;
            0) return ;;
            *) print_error "Invalid option"; sleep 2 ;;
        esac
    done
}

backup_app() {
    print_header "BACKUP APP"
    
    read_input "Enter app name" "" app_name
    read_input "Enter app directory" "/var/www" app_dir
    
    if [ ! -d "$app_dir/$app_name" ]; then
        print_error "App directory not found!"
        press_any_key
        return
    fi
    
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_file="$NDC_BACKUP_DIR/${app_name}_${backup_date}.tar.gz"
    
    mkdir -p "$NDC_BACKUP_DIR"
    
    print_step "Backing up $app_name..."
    
    tar czf "$backup_file" -C "$app_dir" "$app_name"
    
    print_success "Backup created: $backup_file"
    
    if ask_yes_no "Backup database too?" "y"; then
        read_input "Database type [postgresql/mongodb/mysql]" "postgresql" db_type
        read_input "Database name" "" db_name
        
        case "$db_type" in
            postgresql)
                sudo -u postgres pg_dump "$db_name" | gzip > "${backup_file%.tar.gz}_db.sql.gz"
                ;;
            mongodb)
                mongodump --db="$db_name" --archive="${backup_file%.tar.gz}_db.archive" --gzip
                ;;
            mysql)
                mysqldump "$db_name" | gzip > "${backup_file%.tar.gz}_db.sql.gz"
                ;;
        esac
        
        print_success "Database backup created"
    fi
    
    press_any_key
}

restore_app() {
    print_header "RESTORE APP"
    
    read_input "Enter backup file path" "$NDC_BACKUP_DIR/" backup_file
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found!"
        press_any_key
        return
    fi
    
    read_input "Restore to directory" "/var/www" restore_dir
    
    if confirm_action "Restore from backup? Existing files may be overwritten!"; then
        print_step "Restoring..."
        
        tar xzf "$backup_file" -C "$restore_dir"
        
        print_success "App restored to $restore_dir"
        
        if ask_yes_no "Restore database too?" "y"; then
            local db_backup="${backup_file%.tar.gz}_db.sql.gz"
            if [ -f "$db_backup" ]; then
                read_input "Database name" "" db_name
                read_input "Database type [postgresql/mongodb/mysql]" "postgresql" db_type
                
                case "$db_type" in
                    postgresql)
                        gunzip -c "$db_backup" | sudo -u postgres psql "$db_name"
                        ;;
                    mysql)
                        gunzip -c "$db_backup" | mysql "$db_name"
                        ;;
                esac
                
                print_success "Database restored"
            fi
        fi
    fi
    
    press_any_key
}

list_backups() {
    print_header "ALL BACKUPS"
    
    ls -lh "$NDC_BACKUP_DIR"
    
    echo ""
    press_any_key
}

delete_old_backups() {
    print_header "DELETE OLD BACKUPS"
    
    read_input "Delete backups older than (days)" "30" days
    
    if confirm_action "Delete backups older than $days days?"; then
        find "$NDC_BACKUP_DIR" -name "*.tar.gz" -mtime +$days -delete
        find "$NDC_BACKUP_DIR" -name "*.sql.gz" -mtime +$days -delete
        print_success "Old backups deleted"
    fi
    
    press_any_key
}

setup_auto_backup() {
    print_header "SETUP AUTO BACKUP"
    
    echo "Select schedule:"
    echo "  1) Daily at 2 AM"
    echo "  2) Weekly (Sunday 2 AM)"
    echo "  3) Custom cron expression"
    echo ""
    
    read_input "Enter choice [1-3]" "1" schedule
    
    case $schedule in
        1) cron_expr="0 2 * * *" ;;
        2) cron_expr="0 2 * * 0" ;;
        3) read_input "Enter cron expression" "" cron_expr ;;
    esac
    
    # Create backup script
    cat > /usr/local/bin/ndc-auto-backup.sh <<'EOF'
#!/bin/bash
NDC_BACKUP_DIR="/var/backups/ndc-ols"
mkdir -p "$NDC_BACKUP_DIR"
backup_date=$(date +%Y%m%d_%H%M%S)

# Backup all apps
for app in /var/www/*/; do
    app_name=$(basename "$app")
    tar czf "$NDC_BACKUP_DIR/${app_name}_${backup_date}.tar.gz" -C /var/www "$app_name"
done

# Backup databases
command -v pg_dumpall >/dev/null && sudo -u postgres pg_dumpall | gzip > "$NDC_BACKUP_DIR/postgresql_all_${backup_date}.sql.gz"
command -v mysqldump >/dev/null && mysqldump --all-databases | gzip > "$NDC_BACKUP_DIR/mysql_all_${backup_date}.sql.gz"

# Delete backups older than 30 days
find "$NDC_BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
find "$NDC_BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete
EOF
    
    chmod +x /usr/local/bin/ndc-auto-backup.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v ndc-auto-backup; echo "$cron_expr /usr/local/bin/ndc-auto-backup.sh") | crontab -
    
    print_success "Auto backup configured: $cron_expr"
    press_any_key
}

setup_cloud_backup() {
    print_header "CLOUD BACKUP SETUP (RCLONE)"
    
    if ! command_exists rclone; then
        print_step "Installing rclone..."
        curl https://rclone.org/install.sh | bash
    fi
    
    print_info "Run: rclone config"
    print_info "Configure your cloud storage (Google Drive, S3, Dropbox, etc.)"
    
    echo ""
    read -p "Press Enter to open rclone config..."
    rclone config
    
    press_any_key
}

full_system_backup() {
    print_header "FULL SYSTEM BACKUP"
    
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$NDC_BACKUP_DIR/full_backup_$backup_date"
    
    mkdir -p "$backup_dir"
    
    print_step "Creating full system backup..."
    
    # Apps
    tar czf "$backup_dir/apps.tar.gz" -C /var/www .
    
    # Databases
    command -v pg_dumpall >/dev/null && sudo -u postgres pg_dumpall | gzip > "$backup_dir/postgresql.sql.gz"
    command -v mysqldump >/dev/null && mysqldump --all-databases | gzip > "$backup_dir/mysql.sql.gz"
    command -v mongodump >/dev/null && mongodump --out="$backup_dir/mongodb" && tar czf "$backup_dir/mongodb.tar.gz" -C "$backup_dir" mongodb && rm -rf "$backup_dir/mongodb"
    
    # Configs
    tar czf "$backup_dir/nginx.tar.gz" -C /etc nginx
    tar czf "$backup_dir/ndc-ols.tar.gz" -C "$NDC_INSTALL_DIR" .
    
    # Create final archive
    tar czf "${backup_dir}.tar.gz" -C "$NDC_BACKUP_DIR" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    print_success "Full backup created: ${backup_dir}.tar.gz"
    print_info "Size: $(du -h "${backup_dir}.tar.gz" | cut -f1)"
    
    press_any_key
}
