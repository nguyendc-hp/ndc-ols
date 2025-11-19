# Changelog

All notable changes to NDC OLS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
