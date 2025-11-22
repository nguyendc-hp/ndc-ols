# Changelog

All notable changes to NDC OLS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-11-22

### Added - Database GUI Management Revolution 🎨

#### MongoDB Express
- **Dual Access Modes**: SSH Tunnel (default, secure) + Web Access (optional)
- **Enable/Disable Toggle**: One-click switch between access modes
- **Domain + SSL Support**: Automatic Nginx reverse proxy with Let's Encrypt
- **SSH Tunnel Helper**: Detailed instructions for Windows/Linux/macOS/PuTTY
- **Automatic Firewall Management**: Auto-configure UFW/Firewalld based on access mode
- **Real-time Status Display**: Show current access mode in menu
- **Secure by Default**: Binds to localhost only, requires explicit enable for web access
- **Credentials Management**: Auto-generated secure passwords stored in `/etc/ndc-ols/auth.conf`

#### pgAdmin 4 for PostgreSQL
- **Full Installation**: PostgreSQL GUI admin tool (previously missing)
- **Dual Access Modes**: SSH Tunnel + Web Access on port 5050
- **Enable/Disable Toggle**: Same security model as Mongo Express
- **Domain + SSL Support**: Reverse proxy with automatic certificate
- **SSH Tunnel Support**: Detailed connection instructions
- **Automatic User Setup**: Creates admin user with secure password
- **Service Integration**: systemd service management

#### Enhanced Security
- **Default Secure Mode**: All database GUIs bind to localhost by default
- **Explicit Web Access**: Users must explicitly enable public access
- **Firewall Automation**: Ports automatically opened/closed based on mode
- **SSL Integration**: Easy domain setup with Let's Encrypt
- **Access Mode Tracking**: Stores current mode in `/etc/ndc-ols/`

### Added - System Test Suite
- **Comprehensive Testing**: 45+ tests covering all components
- **NDC-OLS Installation**: Verify directories, commands, configs
- **System Services**: Nginx, firewall, Fail2ban
- **Node.js & PM2**: Version checks, running apps
- **Databases**: MongoDB, PostgreSQL, MySQL connection tests
- **Database GUIs**: Mongo Express, pgAdmin, phpMyAdmin
- **Redis**: Connection and version tests
- **SSL/Certbot**: Certificate detection
- **Network**: Public IP, connectivity, DNS
- **Resources**: Disk space, memory usage
- **Exit Codes**: Returns 0 for success, 1 for failures
- **Summary Report**: Pass/fail counts with health status

### Added - Documentation

#### Quick Deploy Guide
- **Step-by-step Instructions**: From fresh VPS to deployed app
- **MiCenter Specific**: Tailored for this project
- **SSH Tunnel Guide**: Detailed for all platforms (Windows/Linux/macOS/PuTTY)
- **Troubleshooting Section**: Common issues and solutions
- **Security Checklist**: Post-deployment security steps
- **Backup Guide**: Automated and manual backup instructions
- **Performance Tips**: PM2 clustering, Nginx optimization
- **Update Procedure**: How to update deployed apps

#### Enhanced README
- **Table of Contents**: Easy navigation
- **Features Overview**: Complete list with emojis
- **Database GUI Section**: Detailed access instructions
- **Deployment Section**: Both automated and manual methods
- **Testing Section**: How to run system tests
- **Troubleshooting**: Common issues for each component
- **Quick Reference Tables**: Access modes, security ratings
- **Command Examples**: Real-world usage examples

### Changed

#### GUI Manager Module
- **Complete Rewrite**: From stub to full-featured module (950+ lines)
- **Better Organization**: Separate functions for each GUI tool
- **Improved Error Handling**: Validates each step, shows helpful errors
- **User Feedback**: Real-time status updates during installation
- **Modular Design**: Easy to add new GUI tools in future

### Fixed

#### MongoDB Express
- **Clone Issues**: Now uses npm install with proper validation
- **Port 8081 Access**: Firewall rules properly managed
- **Binding Issues**: Correctly switches between localhost and 0.0.0.0
- **PM2 Integration**: Reliable startup with health checks
- **Credentials**: Properly loads from auth.conf

#### Installation Process
- **MongoDB Setup**: Wait for service to start before creating users
- **Mongo Express**: Verify installation before starting PM2
- **Error Recovery**: Better handling of installation failures
- **Dependency Order**: Ensures Node.js installed before npm packages

### Security Improvements

- **Default Closed Ports**: Database GUIs not exposed by default
- **SSH Tunnel First**: Encourages secure access method
- **Explicit Opt-in**: Users must choose to enable web access
- **Warning Messages**: Alert users about security implications
- **Firewall Integration**: Automatic port management
- **SSL Encouragement**: Prompts for domain + SSL setup

### Performance

- **PM2 Cluster Mode**: Backend runs in cluster mode (2 instances)
- **Nginx Gzip**: Enabled for all deployments
- **Static Asset Caching**: 1-year cache for JS/CSS/images
- **Connection Pooling**: MongoDB connection reuse

### Developer Experience

- **Quick Setup Script**: One-line VPS setup
- **Test Before Deploy**: Run system tests before deploying apps
- **Detailed Logs**: PM2, Nginx, MongoDB logs easily accessible
- **Credential Management**: All passwords in one file
- **Update Script**: Easy app updates via Git pull

## [Unreleased]

### Added
- Initial release of NDC OLS
- 30 feature modules for VPS management
- One-line installation script
- Support for Ubuntu 22.04/24.04, AlmaLinux 8/9, Rocky Linux 8/9
- Nginx automatic vhost configuration
- Node.js/NVM multi-version support
- PM2 process manager integration
- Multi-database support (PostgreSQL, MongoDB, MySQL/MariaDB, Redis)
- Let's Encrypt SSL automation
- Backup system with cloud sync (Rclone)
- Firewall management (UFW/Firewalld)
- SSH hardening tools
- Deploy from Git or templates
- 8 built-in project templates (React, Next.js, Express, NestJS, etc.)
- System monitoring and logs
- Auto-update mechanism

### Features by Category

#### App Management
- List/start/stop/restart apps via PM2
- View realtime logs
- Update apps from Git
- Rebuild and restart apps

#### Domain Management
- Add Node.js domains (reverse proxy)
- Add React/Vue domains (static)
- Add Next.js domains (SSR)
- Automatic Nginx configuration

#### SSL Management
- Install SSL via Let's Encrypt
- Renew SSL certificates
- Force HTTPS redirect
- Auto-renewal setup

#### Database Management
- PostgreSQL: Create DB/users, backup/restore
- MongoDB: Database management, mongodump
- MySQL/MariaDB: Full management suite
- Redis: Cache management

#### Backup & Restore
- Backup apps (code + database)
- Restore from backups
- Auto-backup scheduling
- Cloud backup (S3, Google Drive, Dropbox)
- Full system backup

#### Deployment
- Deploy from Git repository
- Deploy React (Vite/CRA)
- Deploy Next.js
- Deploy Express/NestJS
- Deploy Vue/Nuxt
- Quick start templates

#### Security
- SSH port changing
- SSH key setup
- Disable root login
- Firewall configuration
- Fail2ban setup
- IP blocking/unblocking

#### System
- System updates
- Node.js version management
- Service management
- System information
- Resource monitoring

## [1.1.0] - 2025-11-19

### Added
- **Full Stack Deploy**: New deployment option for MERN/PERN stack apps (Monorepo support).
- **Auto-detection**: Automatically detects `backend` and `frontend` folders in Git repositories.
- **Smart Configuration**: Auto-configures Nginx reverse proxy for `/api` and static files for `/`.
- **Env Management**: Auto-generates `.env` files and configures `VITE_API_BASE_URL`.

## [1.0.0] - 2025-11-18

### Beta Release
- Initial public beta
- Core features tested
- Community testing phase

---

## Version History

- **Unreleased**: Current development
- **1.0.0**: Planned stable release
- **0.1.0**: Beta release

## Links
- [GitHub Releases](https://github.com/ndc-ols/releases)
- [Documentation](https://docs.ndc-ols.com)
