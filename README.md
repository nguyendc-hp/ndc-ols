# NDC OLS - Node & React VPS Management Script

<div align="center">

![NDC OLS Logo](https://img.shields.io/badge/NDC_OLS-v1.0.0-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Node.js](https://img.shields.io/badge/Node.js-18_|_20_|_22-green?style=for-the-badge&logo=node.js)
![Bash](https://img.shields.io/badge/Bash-4.0+-black?style=for-the-badge&logo=gnu-bash)

**🚀 Công cụ quản lý VPS chuyên nghiệp cho ReactJS và Node.js**

[Cài đặt](#-cài-đặt) • [Tính năng](#-tính-năng) • [Documentation](#-tài-liệu) • [Support](#-hỗ-trợ) • [Donate](#-donate)

</div>

---

## 📖 Giới thiệu

**NDC OLS** (Node Deploy & Control - OpenSource Linux Script) là công cụ quản lý VPS mã nguồn mở, giúp bạn dễ dàng thiết lập, triển khai và quản lý các ứng dụng **Node.js** và **React** trên VPS/Server Linux.

### 🎯 Tại sao chọn NDC OLS?

- ✅ **Miễn phí 100%** - Open Source, không giới hạn số lượng apps
- ✅ **Cài đặt 1 dòng lệnh** - Setup hoàn chỉnh trong vài phút
- ✅ **30 tính năng toàn diện** - Từ deploy đến monitoring
- ✅ **Tự động hóa cao** - SSL, backup, security tất cả tự động
- ✅ **Hiệu năng tối ưu** - Nginx + PM2 + Redis
- ✅ **Bảo mật mạnh mẽ** - Firewall, Fail2ban, SSH hardening
- ✅ **Hỗ trợ đa database** - PostgreSQL, MongoDB, MySQL, Redis
- ✅ **Multi-version Node.js** - Dễ dàng chuyển đổi versions
- ✅ **Backup tự động** - Lưu trữ local + cloud (S3, Google Drive)
- ✅ **Community-driven** - Phát triển bởi cộng đồng

### 🏆 So sánh với các công cụ khác

| Tính năng | NDC OLS | ServerPilot | Runcloud | Ploi |
|-----------|---------|-------------|----------|------|
| **Giá** | Miễn phí | $10-42/tháng | $8-80/tháng | $10-39/tháng |
| **Open Source** | ✅ | ❌ | ❌ | ❌ |
| **Số lượng apps** | Không giới hạn | Giới hạn | Giới hạn | Giới hạn |
| **Node.js support** | ✅ Native | ⚠️ Limited | ⚠️ Limited | ✅ |
| **Tùy chỉnh** | ✅ Full control | ❌ | ⚠️ Limited | ⚠️ Limited |
| **Docker support** | ✅ | ❌ | ✅ | ✅ |
| **CLI** | ✅ | ⚠️ Limited | ❌ | ⚠️ Limited |

---

## 🚀 Cài đặt

### Yêu cầu hệ thống

- **OS**: Ubuntu 22.04/24.04, AlmaLinux 8/9, Rocky Linux 8/9
- **RAM**: Tối thiểu 1GB (khuyến nghị 2GB+)
- **Disk**: Tối thiểu 10GB free space
- **Root access**: Cần quyền root hoặc sudo

### Cài đặt nhanh

**Chỉ cần 1 dòng lệnh:**

```bash
curl -sL https://raw.githubusercontent.com/ndcviet/ndc-ols/main/install.sh | bash
```

**Hoặc tải về và chạy:**

```bash
curl -sO https://raw.githubusercontent.com/ndcviet/ndc-ols/main/install.sh
chmod +x install.sh
bash install.sh
```

**Hoặc clone từ GitHub:**

```bash
git clone https://github.com/ndcviet/ndc-ols.git
cd ndc-ols
chmod +x install.sh
bash install.sh
```

### Quá trình cài đặt

Script sẽ tự động:
1. ✅ Kiểm tra hệ thống và cài đặt dependencies
2. ✅ Cài đặt Nginx web server
3. ✅ Cài đặt NVM + Node.js (LTS versions)
4. ✅ Cài đặt PM2 process manager
5. ✅ Cài đặt databases (PostgreSQL, MongoDB, MySQL, Redis)
6. ✅ Cấu hình firewall (UFW/Firewalld)
7. ✅ Cài đặt SSL (Let's Encrypt)
8. ✅ Cấu hình bảo mật (Fail2ban, SSH hardening)
9. ✅ Setup backup system

**Thời gian cài đặt**: ~10-15 phút

### Sau khi cài đặt

Gọi menu chính:

```bash
ndc
```

Hoặc:

```bash
ndc-ols
```

---

## 🎨 Tính năng

### 📱 Menu chính

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

 0) Exit
```

### 🔥 Tính năng chi tiết

#### 1️⃣ Quản lý Apps (Node/React)
- List tất cả apps đang chạy
- Thêm/Xóa apps
- Start/Stop/Restart apps
- View logs realtime
- Cấu hình environment variables
- Build React apps
- Update từ Git

#### 2️⃣ Quản lý Domain
- Thêm domain/subdomain tự động
- Cấu hình Nginx vhost
- Proxy pass to app port
- Static files serving
- Redirect www ↔ non-www

#### 3️⃣ Quản lý SSL
- SSL miễn phí Let's Encrypt
- Tự động renew
- Wildcard SSL
- Force HTTPS redirect
- Multi-domain SSL

#### 4️⃣ Quản lý Database
- PostgreSQL, MongoDB, MySQL/MariaDB, Redis
- Tạo/Xóa database
- Backup/Restore
- Import/Export
- Database admin GUI

#### 5️⃣ Backup & Restore
- Backup tự động theo lịch
- Lưu trữ cloud (S3, Google Drive, Dropbox)
- Mã hóa backup
- Restore dễ dàng
- Quản lý backup history

#### 6️⃣ Deploy New App
- Deploy từ Git (GitHub, GitLab, Bitbucket)
- Templates: React, Next.js, Express, NestJS, Vue, Svelte
- Auto install dependencies
- Auto build
- Setup PM2 + Domain + SSL
- CI/CD webhooks

#### 7️⃣ Quản lý Services (PM2)
- PM2 process management
- Auto restart on crash
- Startup script (boot on startup)
- Logs monitoring
- Resource usage monitoring

#### 8️⃣ Firewall & IP Management
- UFW/Firewalld configuration
- Whitelist/Blacklist IPs
- Port management
- Rate limiting
- DDoS protection basic
- GeoIP blocking

#### 9️⃣ SSH/SFTP Management
- Đổi SSH port
- SSH key authentication
- Disable root login
- SFTP users
- SSH logs

#### 🔟 System Update
- Update packages
- Update Node.js versions
- Update Nginx, PM2
- Security updates
- Auto update schedule

#### 1️⃣1️⃣ CDN & Cache Config
- Nginx caching
- Browser cache headers
- Gzip/Brotli compression
- Redis cache
- Cloudflare integration

#### 1️⃣2️⃣ Nginx Configuration
- Edit configs
- Test configs
- Reload Nginx
- View logs
- Rate limiting
- Load balancing

#### 1️⃣3️⃣ Environment Variables
- View/Edit .env files
- Backup .env
- Template .env
- Encryption

#### 1️⃣4️⃣ Node.js Version Manager
- Install multiple Node versions
- Switch versions
- Set version per app
- Update npm/yarn/pnpm

#### 1️⃣5️⃣ Logs Management
- App logs (PM2)
- Nginx logs
- System logs
- Database logs
- SSH logs
- Log rotation

#### 1️⃣6️⃣ Clone/Duplicate Project
- Clone app + database
- Deploy to new domain
- Update configurations

#### 1️⃣7️⃣ Quản lý Source Code
- Quick access to source
- Git operations
- File search
- Code editor

#### 1️⃣8️⃣ Phân quyền Files/Folders
- Fix ownership
- Fix permissions
- Recursive apply

#### 1️⃣9️⃣ Quản lý Cache (Redis)
- Install/Configure Redis
- Flush cache
- Monitor Redis
- Redis CLI

#### 2️⃣0️⃣ Thông tin Credentials
- Database credentials
- FTP/SFTP info
- App URLs
- API keys

#### 2️⃣1️⃣ Thông tin Server
- CPU/RAM/Disk usage
- Network stats
- Uptime
- Software versions

#### 2️⃣2️⃣ Bảo mật & Firewall
- Fail2ban setup
- Security audit
- Two-factor authentication
- Intrusion detection

#### 2️⃣3️⃣ Update NDC OLS
- Check for updates
- Self-update script
- Rollback updates
- Changelog

#### 2️⃣4️⃣ Database Admin GUI
- pgAdmin (PostgreSQL)
- Mongo Express (MongoDB)
- phpMyAdmin (MySQL)
- SSL protection

#### 2️⃣5️⃣ Support Request
- Create ticket
- View tickets
- System info report

#### 2️⃣6️⃣ Quản lý Swap/Memory
- Create/Resize swap
- Monitor swap usage
- Optimize memory

#### 2️⃣7️⃣ Migration Tool
- Export app + DB
- Import to new server
- SSH migration
- Verify migration

#### 2️⃣8️⃣ File Manager Web
- Web-based file manager
- Upload/Download files
- Edit files online
- SSL protected

#### 2️⃣9️⃣ Monitor Resources
- htop, iotop, nethogs
- PM2 monitoring
- Netdata dashboard
- Grafana + Prometheus

#### 3️⃣0️⃣ Donate & Support
- Support project
- PayPal/Crypto
- GitHub Sponsors

---

## 🛠 Stack công nghệ

### Web Server
- **Nginx** - High-performance web server
- **SSL/TLS** - Let's Encrypt (Certbot)

### Runtime
- **Node.js** - v18 LTS, v20 LTS, v22 LTS
- **NVM** - Node Version Manager
- **PM2** - Process Manager

### Databases
- **PostgreSQL** - v15, v14
- **MongoDB** - v7.0, v6.0
- **MySQL/MariaDB** - v8.0, v10.11
- **Redis** - Latest (cache & sessions)

### Security
- **UFW/Firewalld** - Firewall
- **Fail2ban** - Brute force protection
- **Let's Encrypt** - Free SSL certificates

### Backup & Cloud
- **Rclone** - Cloud sync (S3, Google Drive, Dropbox)
- **Cron** - Scheduled tasks
- **GPG** - Encryption

### Monitoring
- **PM2** - Process monitoring
- **Netdata** - System monitoring
- **Grafana + Prometheus** - Advanced metrics (optional)

### GUI Tools
- **pgAdmin** - PostgreSQL admin
- **Mongo Express** - MongoDB admin
- **phpMyAdmin** - MySQL admin
- **File Browser** - Web file manager

---

## 📚 Tài liệu

### Quick Start Guides

- [Cài đặt NDC OLS](docs/INSTALLATION.md)
- [Deploy React App](docs/deploy-react.md)
- [Deploy Node.js API](docs/deploy-nodejs.md)
- [Deploy Next.js App](docs/deploy-nextjs.md)
- [Cấu hình Database](docs/database-setup.md)
- [Setup SSL/HTTPS](docs/ssl-setup.md)
- [Backup & Restore](docs/backup-restore.md)
- [Migration Server](docs/migration.md)

### Advanced Guides

- [Nginx Configuration](docs/nginx-config.md)
- [PM2 Advanced](docs/pm2-advanced.md)
- [Security Best Practices](docs/security.md)
- [Performance Tuning](docs/performance.md)
- [Monitoring Setup](docs/monitoring.md)
- [CI/CD Integration](docs/cicd.md)

### Troubleshooting

- [Common Issues](docs/TROUBLESHOOTING.md)
- [FAQ](docs/FAQ.md)
- [Error Codes](docs/error-codes.md)

---

## 🎓 Ví dụ sử dụng

### Deploy React App (Vite)

```bash
# 1. Gọi menu
ndc

# 2. Chọn option 6 (Deploy New App)
6

# 3. Nhập thông tin:
- Template: React (Vite)
- Git URL: https://github.com/username/my-react-app.git
- Domain: myapp.com
- Auto SSL: Yes

# 4. Đợi vài phút, xong!
# App của bạn đã live tại: https://myapp.com
```

### Deploy Node.js API

```bash
# 1. Gọi menu
ndc

# 2. Chọn option 6 (Deploy New App)
6

# 3. Nhập thông tin:
- Template: Express.js
- Git URL: https://github.com/username/my-api.git
- Port: 3000
- Domain: api.myapp.com
- Database: PostgreSQL
- Auto SSL: Yes

# 4. App running tại: https://api.myapp.com
```

### Setup Auto Backup

```bash
# 1. Gọi menu
ndc

# 2. Chọn option 5 (Backup & Restore)
5

# 3. Chọn "Setup Auto Backup"
2

# 4. Cấu hình:
- Schedule: Daily at 2 AM
- Cloud: Google Drive
- Encryption: Yes

# Done! Backup tự động mỗi ngày
```

---

## 🤝 Đóng góp

Chúng tôi rất hoan nghênh mọi đóng góp từ cộng đồng!

### Cách đóng góp

1. Fork repo
2. Tạo branch mới (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Tạo Pull Request

### Guidelines

- Follow bash scripting best practices
- Add comments cho code phức tạp
- Test trên Ubuntu và AlmaLinux
- Update documentation nếu cần

### Contributors

<a href="https://github.com/yourusername/ndc-ols/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=yourusername/ndc-ols" />
</a>

---

## 📞 Hỗ trợ

### Community Support

- **GitHub Issues**: [Report bugs](https://github.com/yourusername/ndc-ols/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/yourusername/ndc-ols/discussions)
- **Discord**: [Join server](https://discord.gg/your-invite)
- **Facebook Group**: [Cộng đồng NDC OLS](https://facebook.com/groups/ndc-ols)

### Documentation

- **Docs**: [docs.ndc-ols.com](https://docs.ndc-ols.com)
- **Wiki**: [GitHub Wiki](https://github.com/yourusername/ndc-ols/wiki)
- **Blog**: [Tutorials & Tips](https://blog.ndc-ols.com)

### Professional Support

Cần hỗ trợ nhanh? Email: support@ndc-ols.com

---

## 💖 Donate

NDC OLS hoàn toàn miễn phí và open source. Nếu bạn thấy hữu ích, hãy ủng hộ để dự án phát triển!

### Donation Options

- **PayPal**: [paypal.me/ndc-ols](https://paypal.me/ndc-ols)
- **GitHub Sponsors**: [Sponsor us](https://github.com/sponsors/yourusername)
- **Bitcoin**: `1NDCxxxxxxxxxxxxxxxxxxx`
- **Ethereum**: `0xNDCxxxxxxxxxxxxxxxxxxx`

### Sponsors

Cảm ơn các nhà tài trợ của chúng tôi! 🙏

<!-- sponsors -->

---

## 📊 Stats

![GitHub stars](https://img.shields.io/github/stars/yourusername/ndc-ols?style=social)
![GitHub forks](https://img.shields.io/github/forks/yourusername/ndc-ols?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/yourusername/ndc-ols?style=social)

![GitHub issues](https://img.shields.io/github/issues/yourusername/ndc-ols)
![GitHub pull requests](https://img.shields.io/github/issues-pr/yourusername/ndc-ols)
![GitHub last commit](https://img.shields.io/github/last-commit/yourusername/ndc-ols)
![GitHub contributors](https://img.shields.io/github/contributors/yourusername/ndc-ols)

---

## 📜 License

MIT License - xem [LICENSE](LICENSE) file để biết thêm chi tiết.

```
MIT License

Copyright (c) 2025 NDC OLS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software...
```

---

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/ndc-ols&type=Date)](https://star-history.com/#yourusername/ndc-ols&Date)

---

## 🗺 Roadmap

### v1.0 (Current) ✅
- [x] Core features
- [x] 30 management modules
- [x] Auto backup system
- [x] SSL automation
- [x] Multi-database support

### v1.5 (Q1 2025) 🔄
- [ ] Docker support
- [ ] Web GUI dashboard
- [ ] Multi-server management
- [ ] Advanced monitoring (Grafana)
- [ ] Kubernetes integration

### v2.0 (Q2 2025) 🎯
- [ ] Cloud deployment (AWS, DigitalOcean, Vultr)
- [ ] AI-powered optimization
- [ ] Mobile app
- [ ] Auto-scaling
- [ ] Advanced CI/CD

---

## 📸 Screenshots

### Main Menu
![Main Menu](docs/images/main-menu.png)

### Deploy App
![Deploy App](docs/images/deploy-app.png)

### Monitoring Dashboard
![Monitoring](docs/images/monitoring.png)

---

## 🔗 Links & Community

- **GitHub**: [github.com/ndcviet/ndc-ols](https://github.com/ndcviet/ndc-ols)
- **Documentation**: [github.com/ndcviet/ndc-ols/wiki](https://github.com/ndcviet/ndc-ols/wiki)
- **Issues**: [github.com/ndcviet/ndc-ols/issues](https://github.com/ndcviet/ndc-ols/issues)
- **Discussions**: [github.com/ndcviet/ndc-ols/discussions](https://github.com/ndcviet/ndc-ols/discussions)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)

### 👥 Community

- **Discord**: Coming soon
- **Facebook Group**: Coming soon
- **Twitter**: Coming soon

---

## ⚡ Quick Commands

```bash
# Gọi menu chính
ndc

# Deploy app nhanh
ndc deploy

# Xem logs
ndc logs [app-name]

# Restart app
ndc restart [app-name]

# Backup ngay
ndc backup

# Update NDC OLS
ndc update

# Xem system info
ndc info

# Help
ndc help
```

---

<div align="center">

**Made with ❤️ by NDC OLS Team**

⭐ Star us on GitHub — it helps!

[⬆ Back to top](#ndc-ols---node--react-vps-management-script)

</div>
