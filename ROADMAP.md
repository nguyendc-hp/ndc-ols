# NDC OLS - Node & React VPS Management Script
## Dự án Quản lý VPS cho ReactJS và NodeJS

---

## 📋 TỔNG QUAN DỰ ÁN

### Mục tiêu
Xây dựng một công cụ script quản lý VPS chuyên biệt cho các dự án ReactJS và NodeJS, tương tự WPTangToc OLS nhưng tập trung vào Node.js ecosystem.

### Đặc điểm chính
- **Miễn phí & Open Source**
- **Cài đặt đơn giản**: `curl -sO https://yourdomain.com/share/ndc-ols && bash ndc-ols`
- **Tối ưu hiệu năng** cho Node.js và React
- **Quản lý đa dự án** không giới hạn
- **Hỗ trợ**: AlmaLinux 8/9, Rocky Linux 8/9, Ubuntu 22.04/24.04

---

## 🎯 PHÂN TÍCH WPTANGTOC OLS

### Các tính năng chính (30 features)
WPTangToc OLS cung cấp menu 30 tính năng:

1. **Quản lý ứng dụng** (WordPress → Node/React apps)
2. **Quản lý Domain** - Thêm/xóa domain, cấu hình vhost
3. **Quản lý SSL** - Let's Encrypt tự động
4. **Quản lý Database** - Thêm/xóa/backup/restore
5. **Sao lưu & Khôi phục** - Backup tự động, lưu cloud
6. **Tải mã nguồn** - Clone/deploy ứng dụng
7. **Quản lý Service** - Start/stop/restart services
8. **Quản lý IP** - Firewall, chặn/mở IP
9. **Quản lý SSH/SFTP** - Đổi port, mật khẩu
10. **Quản lý cập nhật** - Update packages
11. **Preload Cache** - Tối ưu cache
12. **WebGuiAdmin** - Web interface
13. **Cấu hình Webserver** - Nginx/OpenLiteSpeed config
14. **Quản lý PHP** - Đổi version PHP (→ Node.js versions)
15. **Quản lý logs** - Xem và phân tích logs
16. **Duplicate website** - Nhân bản dự án
17. **Quản lý mã nguồn** - File explorer, quick access
18. **Phân quyền** - Permissions cho files/folders
19. **Quản lý Cache** - Redis/Memcached
20. **Thông tin tài khoản** - Credentials
21. **Thông tin server** - System info, resources
22. **Bảo mật** - Firewall, fail2ban, brute force protection
23. **Cập nhật tool** - Self-update
24. **PhpMyAdmin** - Database GUI (→ Mongo Express, pgAdmin)
25. **Gửi yêu cầu** - Support ticket
26. **Quản lý Swap** - RAM ảo
27. **Chuyển website** - Migration tool
28. **File Manager** - Web-based file manager
29. **Quản lý tài nguyên** - CPU/RAM/Disk monitoring
30. **Donate** - Hỗ trợ tác giả

### Stack công nghệ WPTangToc OLS
- **Web Server**: OpenLiteSpeed
- **PHP**: LSPHP 8.3, 8.2, 8.1, 8.0, 7.4, 7.3
- **Database**: MariaDB 11.4, 10.11, 10.6, 10.5
- **Cache**: Redis, LSmemcached
- **Security**: Fail2ban, firewall
- **Backup**: Google Drive integration

---

## 🚀 NDC OLS - CHỨC NĂNG ĐỀ XUẤT

### Stack công nghệ cho Node/React
- **Web Server**: Nginx / Caddy
- **Node.js**: Multiple versions (v18 LTS, v20 LTS, v22 LTS)
- **Process Manager**: PM2
- **Database**: 
  - PostgreSQL (15, 14, 13)
  - MongoDB (7.0, 6.0)
  - MySQL/MariaDB
  - Redis
- **Reverse Proxy**: Nginx with SSL
- **Cache**: Redis, Varnish
- **Container**: Docker + Docker Compose (optional)

### Menu chính NDC OLS (30 tính năng)

```
════════════════════════════════════════════════════════════
               NDC OLS - Node & React Management
           OpenSource VPS Management for Node.js
════════════════════════════════════════════════════════════

 1) Quản lý Apps (Node/React)     16) Clone/Duplicate Project
 2) Quản lý Domain                17) Quản lý Source Code
 3) Quản lý SSL (Let's Encrypt)   18) Phân quyền Files/Folders
 4) Quản lý Database              19) Quản lý Cache (Redis)
 5) Backup & Restore              20) Thông tin Credentials
 6) Deploy New App                21) Thông tin Server
 7) Quản lý Services (PM2)        22) Bảo mật & Firewall
 8) Firewall & IP Management      23) Update NDC OLS
 9) SSH/SFTP Management           24) Database Admin GUI
10) System Update                 25) Support Request
11) CDN & Cache Config            26) Quản lý Swap/Memory
12) Nginx Configuration           27) Migration Tool
13) Environment Variables         28) File Manager Web
14) Node.js Version Manager       29) Monitor Resources
15) Logs Management               30) Donate & Support
```

---

## 📂 CẤU TRÚC DỰ ÁN CHI TIẾT

### 1. **Quản lý Apps (Node/React)** ⭐
**Mục đích**: Quản lý tất cả ứng dụng Node.js/React trên VPS

**Chức năng con**:
- 1.1. List tất cả apps đang chạy
- 1.2. Thêm app mới
- 1.3. Xóa app
- 1.4. Start/Stop/Restart app
- 1.5. Xem logs realtime
- 1.6. Cấu hình environment variables
- 1.7. Thay đổi port
- 1.8. Build React app (npm run build)
- 1.9. Cài dependencies (npm install)
- 1.10. Update app từ Git

**Công nghệ**:
- PM2 process manager
- Git integration
- npm/yarn/pnpm support

---

### 2. **Quản lý Domain**
**Mục đích**: Tự động cấu hình domain cho apps

**Chức năng con**:
- 2.1. Thêm domain mới
- 2.2. Xóa domain
- 2.3. List domains
- 2.4. Cấu hình subdomain
- 2.5. Redirect www <-> non-www
- 2.6. Proxy pass to app port
- 2.7. Static files serving (React build)

**Công nghệ**:
- Nginx configuration automation
- DNS validation

---

### 3. **Quản lý SSL**
**Mục đích**: Tự động SSL cho domains

**Chức năng con**:
- 3.1. Cài SSL Let's Encrypt
- 3.2. Tự động renew
- 3.3. SSL cho multiple domains
- 3.4. Force HTTPS redirect
- 3.5. SSL Wildcard
- 3.6. Check SSL status

**Công nghệ**:
- Certbot
- Acme.sh
- Auto-renewal cron jobs

---

### 4. **Quản lý Database**
**Mục đích**: Quản lý PostgreSQL, MongoDB, MySQL/MariaDB

**Chức năng con**:
- 4.1. Tạo database mới
- 4.2. Xóa database
- 4.3. List databases
- 4.4. Tạo user + phân quyền
- 4.5. Backup database
- 4.6. Restore database
- 4.7. Import/Export SQL
- 4.8. Optimize database
- 4.9. Check database size

**Công nghệ**:
- PostgreSQL, MongoDB, MySQL
- Automated backup scripts
- Compression (gzip, bzip2)

---

### 5. **Backup & Restore**
**Mục đích**: Sao lưu tự động và khôi phục

**Chức năng con**:
- 5.1. Backup toàn bộ app (code + DB)
- 5.2. Backup theo lịch (daily/weekly)
- 5.3. Lưu lên cloud (S3, Google Drive, Dropbox)
- 5.4. Restore từ backup
- 5.5. List backups
- 5.6. Xóa backup cũ
- 5.7. Download backup về local
- 5.8. Encryption backup

**Công nghệ**:
- Rclone (cloud sync)
- Tar + gzip
- Cron jobs
- GPG encryption

---

### 6. **Deploy New App**
**Mục đích**: Deploy app từ Git, GitHub, GitLab

**Chức năng con**:
- 6.1. Clone from Git repository
- 6.2. Setup từ template (React, Next.js, Express, NestJS)
- 6.3. Auto install dependencies
- 6.4. Auto build
- 6.5. Setup PM2
- 6.6. Configure domain + SSL
- 6.7. Setup database connection
- 6.8. CI/CD webhook (GitHub Actions, GitLab CI)

**Templates hỗ trợ**:
- React (Vite, CRA)
- Next.js
- Express.js
- NestJS
- Nuxt.js
- Vue.js
- Svelte/SvelteKit
- Gatsby

---

### 7. **Quản lý Services (PM2)**
**Mục đích**: Quản lý PM2 process manager

**Chức năng con**:
- 7.1. PM2 list all processes
- 7.2. Start/Stop/Restart process
- 7.3. PM2 logs
- 7.4. PM2 monit (realtime monitor)
- 7.5. Auto restart on crash
- 7.6. Startup script (auto start on boot)
- 7.7. PM2 ecosystem file
- 7.8. Delete process

**Công nghệ**:
- PM2
- Systemd integration

---

### 8. **Firewall & IP Management**
**Mục đích**: Bảo mật server với firewall

**Chức năng con**:
- 8.1. Enable/Disable firewall
- 8.2. Chặn IP
- 8.3. Whitelist IP
- 8.4. List blocked IPs
- 8.5. Open/Close ports
- 8.6. Rate limiting
- 8.7. DDoS protection (basic)
- 8.8. GeoIP blocking

**Công nghệ**:
- UFW (Ubuntu)
- Firewalld (CentOS/AlmaLinux)
- Fail2ban
- iptables

---

### 9. **SSH/SFTP Management**
**Mục đích**: Bảo mật SSH

**Chức năng con**:
- 9.1. Đổi SSH port
- 9.2. Đổi root password
- 9.3. SSH key authentication
- 9.4. Disable root login
- 9.5. Disable password login
- 9.6. SFTP user management
- 9.7. SSH logs

---

### 10. **System Update**
**Mục đích**: Cập nhật hệ thống

**Chức năng con**:
- 10.1. Update package list
- 10.2. Upgrade packages
- 10.3. Update Node.js
- 10.4. Update Nginx
- 10.5. Update PM2
- 10.6. Security updates only
- 10.7. Auto update schedule

---

### 11. **CDN & Cache Config**
**Mục đích**: Tối ưu cache và CDN

**Chức năng con**:
- 11.1. Nginx cache config
- 11.2. Browser cache headers
- 11.3. Gzip/Brotli compression
- 11.4. Redis cache setup
- 11.5. Cloudflare integration
- 11.6. Purge cache

---

### 12. **Nginx Configuration**
**Mục đích**: Cấu hình Nginx nâng cao

**Chức năng con**:
- 12.1. Edit nginx.conf
- 12.2. Edit site config
- 12.3. Test config
- 12.4. Reload Nginx
- 12.5. Nginx access logs
- 12.6. Nginx error logs
- 12.7. Rate limiting config
- 12.8. Load balancing

---

### 13. **Environment Variables**
**Mục đích**: Quản lý .env files

**Chức năng con**:
- 13.1. View .env
- 13.2. Edit .env
- 13.3. Backup .env
- 13.4. Template .env
- 13.5. Encryption .env

---

### 14. **Node.js Version Manager**
**Mục đích**: Quản lý multiple Node.js versions

**Chức năng con**:
- 14.1. List installed versions
- 14.2. Install new version
- 14.3. Uninstall version
- 14.4. Switch default version
- 14.5. Set version per app
- 14.6. Update npm/yarn/pnpm

**Công nghệ**:
- NVM (Node Version Manager)
- n (Node version manager)

---

### 15. **Logs Management**
**Mục đích**: Xem và phân tích logs

**Chức năng con**:
- 15.1. App logs (PM2)
- 15.2. Nginx access logs
- 15.3. Nginx error logs
- 15.4. System logs
- 15.5. Database logs
- 15.6. SSH logs
- 15.7. Clear logs
- 15.8. Log rotation config

---

### 16. **Clone/Duplicate Project**
**Mục đích**: Nhân bản project

**Chức năng con**:
- 16.1. Clone app to new domain
- 16.2. Clone database
- 16.3. Update configs

---

### 17. **Quản lý Source Code**
**Mục đích**: Truy cập nhanh source code

**Chức năng con**:
- 17.1. Quick cd to app folder
- 17.2. Open in nano/vim
- 17.3. Git status
- 17.4. Git pull/push
- 17.5. File search

---

### 18. **Phân quyền Files/Folders**
**Mục đích**: Set permissions tự động

**Chức năng con**:
- 18.1. Fix ownership
- 18.2. Fix permissions (755/644)
- 18.3. Recursive permissions

---

### 19. **Quản lý Cache (Redis)**
**Mục đích**: Redis cache management

**Chức năng con**:
- 19.1. Install Redis
- 19.2. Start/Stop Redis
- 19.3. Redis CLI
- 19.4. Flush cache
- 19.5. Redis config
- 19.6. Monitor Redis

---

### 20. **Thông tin Credentials**
**Mục đích**: Hiển thị credentials

**Chức năng con**:
- 20.1. Database credentials
- 20.2. FTP credentials
- 20.3. App URLs
- 20.4. API keys

---

### 21. **Thông tin Server**
**Mục đích**: System information

**Chức năng con**:
- 21.1. CPU usage
- 21.2. RAM usage
- 21.3. Disk usage
- 21.4. Network stats
- 21.5. Uptime
- 21.6. OS version
- 21.7. Installed software versions

---

### 22. **Bảo mật & Firewall**
**Mục đích**: Security hardening

**Chức năng con**:
- 22.1. Install Fail2ban
- 22.2. Configure Fail2ban
- 22.3. Security audit
- 22.4. Two-factor authentication
- 22.5. Intrusion detection

---

### 23. **Update NDC OLS**
**Mục đích**: Self-update script

**Chức năng con**:
- 23.1. Check for updates
- 23.2. Download update
- 23.3. Install update
- 23.4. Rollback update

---

### 24. **Database Admin GUI**
**Mục đích**: Web-based database management

**Chức năng con**:
- 24.1. Install pgAdmin (PostgreSQL)
- 24.2. Install Mongo Express (MongoDB)
- 24.3. Install phpMyAdmin (MySQL)
- 24.4. Configure access
- 24.5. SSL for admin panels

---

### 25. **Support Request**
**Mục đích**: Gửi ticket support

**Chức năng con**:
- 25.1. Create ticket
- 25.2. View tickets
- 25.3. System info report

---

### 26. **Quản lý Swap/Memory**
**Mục đích**: Tăng RAM ảo

**Chức năng con**:
- 26.1. Create swap
- 26.2. Resize swap
- 26.3. Remove swap
- 26.4. Check swap usage

---

### 27. **Migration Tool**
**Mục đích**: Chuyển app giữa các server

**Chức năng con**:
- 27.1. Export app + DB
- 27.2. Import to new server
- 27.3. SSH migration
- 27.4. Verify migration

---

### 28. **File Manager Web**
**Mục đích**: Web-based file manager

**Chức năng con**:
- 28.1. Install File Browser
- 28.2. Configure access
- 28.3. SSL protection
- 28.4. User permissions

---

### 29. **Monitor Resources**
**Mục đích**: Realtime monitoring

**Chức năng con**:
- 29.1. htop
- 29.2. iotop
- 29.3. nethogs
- 29.4. PM2 monit
- 29.5. Install Netdata
- 29.6. Install Grafana + Prometheus

---

### 30. **Donate & Support**
**Mục đích**: Hỗ trợ dự án

**Chức năng con**:
- 30.1. PayPal link
- 30.2. Crypto wallet
- 30.3. GitHub Sponsors

---

## 📅 LỘ TRÌNH THỰC HIỆN

### Phase 1: Foundation (Tuần 1-2) - Core System
**Mục tiêu**: Xây dựng core script và menu

**Tasks**:
- [ ] Setup Git repository
- [ ] Tạo menu chính (bash script)
- [ ] System detection (OS, version)
- [ ] Color scheme và UI
- [ ] Logging system
- [ ] Error handling
- [ ] Update mechanism

**Deliverables**:
- Script với menu hoạt động
- Tài liệu cài đặt cơ bản

---

### Phase 2: Web Server Setup (Tuần 3-4)
**Mục tiêu**: Cài đặt Nginx + SSL

**Tasks**:
- [ ] Install Nginx
- [ ] Configure Nginx defaults
- [ ] SSL với Let's Encrypt (Certbot)
- [ ] Auto-renewal SSL
- [ ] Vhost management functions
- [ ] Test Nginx configs

**Deliverables**:
- Chức năng 2, 3, 12 hoàn thiện

---

### Phase 3: Node.js Ecosystem (Tuần 5-6)
**Mục tiêu**: Node.js + PM2

**Tasks**:
- [ ] Install NVM
- [ ] Install multiple Node.js versions
- [ ] Install PM2
- [ ] PM2 startup script
- [ ] PM2 ecosystem management
- [ ] Node.js app deployment automation

**Deliverables**:
- Chức năng 1, 6, 7, 14 hoàn thiện

---

### Phase 4: Database Management (Tuần 7-8)
**Mục tiêu**: PostgreSQL + MongoDB + MySQL

**Tasks**:
- [ ] Install PostgreSQL
- [ ] Install MongoDB
- [ ] Install MySQL/MariaDB
- [ ] Database backup scripts
- [ ] Database restore scripts
- [ ] Automated backup cron jobs
- [ ] Install database GUI tools

**Deliverables**:
- Chức năng 4, 24 hoàn thiện

---

### Phase 5: Backup & Security (Tuần 9-10)
**Mục tiêu**: Backup system + Security

**Tasks**:
- [ ] Backup system (local)
- [ ] Cloud backup (Rclone + S3/Google Drive)
- [ ] Encryption backup
- [ ] Firewall setup (UFW/Firewalld)
- [ ] Fail2ban installation
- [ ] SSH hardening
- [ ] IP management

**Deliverables**:
- Chức năng 5, 8, 9, 22 hoàn thiện

---

### Phase 6: Advanced Features (Tuần 11-12)
**Mục tiêu**: Cache, Logs, Monitoring

**Tasks**:
- [ ] Redis installation
- [ ] Cache management
- [ ] Logs aggregation
- [ ] Environment variables management
- [ ] File permissions automation
- [ ] Swap management

**Deliverables**:
- Chức năng 11, 13, 15, 18, 19, 26 hoàn thiện

---

### Phase 7: Tools & Utilities (Tuần 13-14)
**Mục tiêu**: Additional tools

**Tasks**:
- [ ] File Manager web (File Browser)
- [ ] Clone/Duplicate functions
- [ ] Migration tool
- [ ] Source code management helpers
- [ ] Resource monitoring (Netdata)

**Deliverables**:
- Chức năng 16, 17, 27, 28, 29 hoàn thiện

---

### Phase 8: Polish & Documentation (Tuần 15-16)
**Mục tiêu**: Hoàn thiện và tài liệu

**Tasks**:
- [ ] Testing toàn bộ features
- [ ] Bug fixes
- [ ] Performance optimization
- [ ] Viết documentation đầy đủ
- [ ] Video hướng dẫn
- [ ] Website cho project
- [ ] GitHub repository + README

**Deliverables**:
- Chức năng 20, 21, 23, 25, 30 hoàn thiện
- Tài liệu hoàn chỉnh
- Website landing page

---

## 🛠 CÔNG NGHỆ SỬ DỤNG

### Core Technologies
- **Scripting**: Bash/Shell
- **Web Server**: Nginx
- **Reverse Proxy**: Nginx
- **SSL**: Let's Encrypt (Certbot)
- **Node.js**: NVM + Multiple versions
- **Process Manager**: PM2
- **Package Managers**: npm, yarn, pnpm

### Databases
- **PostgreSQL**: v15, v14
- **MongoDB**: v7.0, v6.0
- **MySQL/MariaDB**: v8.0, v10.11
- **Redis**: Latest

### Security
- **Firewall**: UFW (Ubuntu) / Firewalld (CentOS/AlmaLinux)
- **Fail2ban**: Brute force protection
- **SSH**: Key-based authentication

### Backup & Cloud
- **Rclone**: Cloud sync (S3, Google Drive, Dropbox)
- **Cron**: Scheduled tasks
- **GPG**: Encryption

### Monitoring
- **PM2**: Process monitoring
- **Netdata**: System monitoring
- **Grafana + Prometheus**: Advanced monitoring (optional)

### GUI Tools
- **pgAdmin**: PostgreSQL admin
- **Mongo Express**: MongoDB admin
- **phpMyAdmin**: MySQL admin
- **File Browser**: Web file manager

---

## 📁 CẤU TRÚC THỨ MỤC

```
/root/ndc-ols/
├── ndc-ols.sh              # Main script
├── install.sh              # Installation script
├── update.sh               # Update script
├── config/
│   ├── settings.conf       # Global settings
│   └── apps.conf           # Apps registry
├── modules/
│   ├── app-manager.sh      # Module 1: App management
│   ├── domain-manager.sh   # Module 2: Domain management
│   ├── ssl-manager.sh      # Module 3: SSL management
│   ├── db-manager.sh       # Module 4: Database management
│   ├── backup-manager.sh   # Module 5: Backup & Restore
│   ├── deploy-manager.sh   # Module 6: Deployment
│   ├── pm2-manager.sh      # Module 7: PM2 services
│   ├── firewall-manager.sh # Module 8: Firewall & IP
│   ├── ssh-manager.sh      # Module 9: SSH/SFTP
│   ├── update-manager.sh   # Module 10: System updates
│   ├── cache-manager.sh    # Module 11: CDN & Cache
│   ├── nginx-manager.sh    # Module 12: Nginx config
│   ├── env-manager.sh      # Module 13: Environment vars
│   ├── node-manager.sh     # Module 14: Node.js versions
│   ├── logs-manager.sh     # Module 15: Logs
│   ├── clone-manager.sh    # Module 16: Clone project
│   ├── source-manager.sh   # Module 17: Source code
│   ├── permission-manager.sh # Module 18: Permissions
│   ├── redis-manager.sh    # Module 19: Redis cache
│   ├── info-manager.sh     # Module 20-21: Info
│   ├── security-manager.sh # Module 22: Security
│   ├── self-update.sh      # Module 23: Self-update
│   ├── gui-manager.sh      # Module 24: DB GUI
│   ├── support-manager.sh  # Module 25: Support
│   ├── swap-manager.sh     # Module 26: Swap
│   ├── migration-manager.sh # Module 27: Migration
│   ├── filemanager.sh      # Module 28: File Manager
│   ├── monitor-manager.sh  # Module 29: Monitoring
│   └── donate.sh           # Module 30: Donate
├── templates/
│   ├── nginx/
│   │   ├── react-app.conf
│   │   ├── node-app.conf
│   │   ├── nextjs-app.conf
│   │   └── static-site.conf
│   ├── pm2/
│   │   └── ecosystem.config.js
│   └── env/
│       ├── react.env.example
│       └── node.env.example
├── backups/
│   ├── apps/
│   ├── databases/
│   └── configs/
├── logs/
│   ├── ndc-ols.log
│   ├── install.log
│   └── error.log
└── utils/
    ├── colors.sh           # Color definitions
    ├── helpers.sh          # Helper functions
    ├── validators.sh       # Input validators
    └── notifications.sh    # Email/Slack notifications

/var/www/
├── app1.com/
│   ├── source/             # Source code
│   ├── logs/               # App logs
│   └── .env                # Environment variables
├── app2.com/
└── app3.com/

/etc/nginx/
├── sites-available/
├── sites-enabled/
└── ndc-ols/                # NDC OLS nginx configs
    ├── cache.conf
    ├── ssl.conf
    └── security.conf
```

---

## 📝 FILE SCRIPT MẪU

### ndc-ols.sh (Main Menu)
```bash
#!/bin/bash

# Colors
source /root/ndc-ols/utils/colors.sh
source /root/ndc-ols/utils/helpers.sh

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "════════════════════════════════════════════════════════════"
    echo "               NDC OLS - Node & React Management"
    echo "           OpenSource VPS Management for Node.js"
    echo "               Version 1.0.0 | By Your Name"
    echo "════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Main menu
show_menu() {
    show_banner
    echo ""
    echo -e " ${GREEN}1)${NC}  Quản lý Apps (Node/React)     ${GREEN}16)${NC} Clone/Duplicate Project"
    echo -e " ${GREEN}2)${NC}  Quản lý Domain                ${GREEN}17)${NC} Quản lý Source Code"
    echo -e " ${GREEN}3)${NC}  Quản lý SSL                   ${GREEN}18)${NC} Phân quyền Files"
    echo -e " ${GREEN}4)${NC}  Quản lý Database              ${GREEN}19)${NC} Quản lý Cache"
    echo -e " ${GREEN}5)${NC}  Backup & Restore              ${GREEN}20)${NC} Thông tin Credentials"
    echo -e " ${GREEN}6)${NC}  Deploy New App                ${GREEN}21)${NC} Thông tin Server"
    echo -e " ${GREEN}7)${NC}  Quản lý Services (PM2)        ${GREEN}22)${NC} Bảo mật & Firewall"
    echo -e " ${GREEN}8)${NC}  Firewall & IP                 ${GREEN}23)${NC} Update NDC OLS"
    echo -e " ${GREEN}9)${NC}  SSH/SFTP Management           ${GREEN}24)${NC} Database Admin GUI"
    echo -e " ${GREEN}10)${NC} System Update                 ${GREEN}25)${NC} Support Request"
    echo -e " ${GREEN}11)${NC} CDN & Cache Config            ${GREEN}26)${NC} Quản lý Swap"
    echo -e " ${GREEN}12)${NC} Nginx Configuration           ${GREEN}27)${NC} Migration Tool"
    echo -e " ${GREEN}13)${NC} Environment Variables         ${GREEN}28)${NC} File Manager Web"
    echo -e " ${GREEN}14)${NC} Node.js Version Manager       ${GREEN}29)${NC} Monitor Resources"
    echo -e " ${GREEN}15)${NC} Logs Management               ${GREEN}30)${NC} Donate & Support"
    echo ""
    echo -e " ${RED}0)${NC}  Exit"
    echo ""
    read -p " Enter your choice [0-30]: " choice
    
    case $choice in
        1) source /root/ndc-ols/modules/app-manager.sh ;;
        2) source /root/ndc-ols/modules/domain-manager.sh ;;
        3) source /root/ndc-ols/modules/ssl-manager.sh ;;
        # ... other cases
        0) exit 0 ;;
        *) echo "Invalid option"; sleep 2 ;;
    esac
}

# Main loop
while true; do
    show_menu
done
```

---

## 🎨 GIAO DIỆN & UX

### Color Scheme
```bash
# colors.sh
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
```

### Progress Indicators
- Loading spinner
- Progress bars
- Success/Error messages với icons

### Interactive Features
- Auto-complete cho domain names
- Confirmation prompts
- Real-time logs streaming

---

## 🔒 BẢO MẬT

### Security Best Practices
1. **SSH Hardening**
   - Disable root login
   - Key-based authentication only
   - Custom SSH port
   - Fail2ban protection

2. **Firewall**
   - Default deny all
   - Whitelist specific ports (80, 443, custom SSH)
   - Rate limiting

3. **App Security**
   - Environment variables không lưu trong Git
   - Secrets encryption
   - Regular security updates

4. **Database Security**
   - Strong passwords
   - Bind to localhost only
   - Regular backups

---

## 📚 TÀI LIỆU

### Documentation Structure
1. **README.md** - Overview, installation
2. **INSTALLATION.md** - Chi tiết cài đặt
3. **USAGE.md** - Hướng dẫn sử dụng từng feature
4. **TROUBLESHOOTING.md** - Xử lý lỗi thường gặp
5. **API.md** - API documentation (nếu có)
6. **CONTRIBUTING.md** - Hướng dẫn contribute
7. **CHANGELOG.md** - Lịch sử phát triển

### Video Tutorials
- Cài đặt NDC OLS
- Deploy React app
- Deploy Node.js API
- Backup & Restore
- Migration giữa servers

---

## 🌐 WEBSITE & COMMUNITY

### Website Features
- Landing page giới thiệu
- Documentation portal
- Blog tutorials
- Demo videos
- Download/Install instructions
- Community forum

### Community
- GitHub Discussions
- Discord server
- Facebook Group
- Newsletter

---

## 💰 MONETIZATION (Tùy chọn)

### Free vs Premium
**Free (Open Source)**:
- Tất cả core features
- Community support
- Regular updates

**Premium (Tùy chọn)**:
- Priority support
- Advanced monitoring (Grafana)
- Kubernetes deployment
- Multi-server management
- Professional themes
- White-label option

---

## 📊 SUCCESS METRICS

### KPIs
- Number of installations
- GitHub stars
- Community size
- Active users
- Bug reports / Feature requests
- Documentation views

### Analytics
- Track installations (opt-in)
- Feature usage statistics
- Performance metrics

---

## 🔄 MAINTENANCE & UPDATES

### Update Strategy
- **Patch updates**: Security fixes (immediate)
- **Minor updates**: New features (monthly)
- **Major updates**: Breaking changes (quarterly)

### Versioning
- Semantic versioning (v1.2.3)
- Changelog documentation
- Migration guides cho breaking changes

---

## 🚨 RISK MANAGEMENT

### Potential Risks
1. **Compatibility issues** với các OS versions
   - Solution: Test trên nhiều OS
   - Maintain compatibility matrix

2. **Security vulnerabilities**
   - Solution: Regular security audits
   - Prompt security patches

3. **Breaking changes** từ dependencies
   - Solution: Version pinning
   - Testing before updates

4. **Community support overhead**
   - Solution: Good documentation
   - Community moderators

---

## 🎯 COMPETITIVE ADVANTAGES

### So với WPTangToc OLS
- ✅ Chuyên biệt cho Node.js/React ecosystem
- ✅ Modern stack (không phải PHP)
- ✅ Container support (Docker)
- ✅ CI/CD integration
- ✅ Multiple database types

### So với các tool khác (Runcloud, ServerPilot, Ploi)
- ✅ **Miễn phí & Open Source**
- ✅ Full control
- ✅ Không giới hạn apps
- ✅ Customize được
- ✅ Community-driven

---

## 📞 CONTACT & SUPPORT

### Support Channels
1. **GitHub Issues** - Bug reports
2. **GitHub Discussions** - Questions & Ideas
3. **Email** - Direct support
4. **Discord** - Community chat
5. **Documentation** - Self-service

---

## ✅ CHECKLIST HOÀN THÀNH

### Phase 1: Foundation ⬜
- [ ] Git repository
- [ ] Main script with menu
- [ ] OS detection
- [ ] Color scheme
- [ ] Logging system
- [ ] Error handling

### Phase 2: Web Server ⬜
- [ ] Nginx installation
- [ ] SSL management
- [ ] Vhost automation

### Phase 3: Node.js ⬜
- [ ] NVM installation
- [ ] PM2 setup
- [ ] App deployment

### Phase 4: Databases ⬜
- [ ] PostgreSQL
- [ ] MongoDB
- [ ] MySQL
- [ ] Backup scripts

### Phase 5: Security ⬜
- [ ] Firewall
- [ ] Fail2ban
- [ ] SSH hardening

### Phase 6: Advanced ⬜
- [ ] Redis cache
- [ ] Logs management
- [ ] Monitoring

### Phase 7: Tools ⬜
- [ ] File Manager
- [ ] Migration tool
- [ ] Clone feature

### Phase 8: Documentation ⬜
- [ ] README
- [ ] Installation guide
- [ ] Video tutorials
- [ ] Website

---

## 🎓 HỌC VÀ PHÁT TRIỂN

### Skills cần có
1. **Bash Scripting** - Core
2. **Linux System Administration** - Required
3. **Nginx Configuration** - Required
4. **Node.js & npm** - Required
5. **PM2** - Required
6. **Git** - Required
7. **PostgreSQL/MongoDB** - Good to have
8. **Docker** - Good to have

### Resources học
- Bash scripting tutorials
- Linux server management courses
- Nginx documentation
- PM2 documentation
- Digital Ocean tutorials

---

## 📈 FUTURE ROADMAP

### v2.0 Features (Future)
- Docker & Docker Compose integration
- Kubernetes deployment
- Multi-server management
- Web-based GUI
- Mobile app monitoring
- AI-powered optimization
- Auto-scaling
- Load balancing
- Advanced analytics

### v3.0 Vision
- Cloud-agnostic deployment
- Serverless integration
- GraphQL API
- Microservices support
- Machine learning optimization

---

## 💡 TÓM TẮT

NDC OLS là một công cụ quản lý VPS chuyên biệt cho Node.js và React, lấy cảm hứng từ WPTangToc OLS nhưng tập trung vào modern JavaScript stack.

**Ưu điểm chính**:
- ✅ Miễn phí & Open Source
- ✅ 30 tính năng toàn diện
- ✅ Dễ cài đặt (1 dòng lệnh)
- ✅ Tự động hóa cao
- ✅ Bảo mật tốt
- ✅ Community-driven

**Timeline**: 16 tuần (4 tháng) để hoàn thành MVP

**Technology Stack**: 
- Bash/Shell scripting
- Nginx + PM2
- Node.js + NVM
- PostgreSQL + MongoDB + Redis
- Let's Encrypt SSL
- Fail2ban + UFW/Firewalld

**Target Users**:
- Developers deploy Node.js/React apps
- Startups với budget limited
- Freelancers quản lý multiple projects
- Agencies manage client servers

---

## 📝 NEXT STEPS

1. **Review roadmap này** và adjust theo nhu cầu
2. **Setup Git repository** và project structure
3. **Bắt đầu Phase 1** - Foundation
4. **Recruit contributors** nếu cần
5. **Setup project management** (GitHub Projects/Trello)
6. **Start coding!** 🚀

---

**Liên hệ & Hỗ trợ**:
- GitHub: [your-repo]
- Email: [your-email]
- Website: [your-website]

---

*Document version: 1.0*  
*Last updated: 2025-01-18*  
*Author: [Your Name]*
