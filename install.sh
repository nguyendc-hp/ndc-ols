#!/bin/bash
#######################################
# NDC OLS - Installation Script
# Auto install all dependencies
#######################################

set -e

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Variables
NDC_VERSION="1.0.0"
NDC_INSTALL_DIR="/usr/local/ndc-ols"
NDC_CONFIG_DIR="/etc/ndc-ols"
NDC_LOG_DIR="/var/log/ndc-ols"
NDC_BACKUP_DIR="/var/backups/ndc-ols"
GITHUB_REPO="https://github.com/nguyendc-hp/ndc-ols"
GITHUB_RAW="https://raw.githubusercontent.com/nguyendc-hp/ndc-ols/main"

#######################################
# Print functions
#######################################
print_banner() {
    clear
    echo -e "${BLUE}"
    echo "    _   _ ____   ____   ___  _     ____  "
    echo "   | \ | |  _ \ / ___| / _ \| |   / ___| "
    echo "   |  \| | | | | |    | | | | |   \___ \ "
    echo "   | |\  | |_| | |___ | |_| | |___ ___) |"
    echo "   |_| \_|____/ \____| \___/|_____|____/ "
    echo -e "${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "   ${BOLD}${GREEN}NDC OLS Installation Wizard${NC} - ${YELLOW}v${NDC_VERSION}${NC}"
    echo -e "   ${CYAN}Node.js & React VPS Management Tool${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} ${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}[✗]${NC} ${RED}$1${NC}"; }
print_warning() { echo -e "${YELLOW}[!]${NC} ${YELLOW}$1${NC}"; }
print_step() { echo -e "${BLUE}[→]${NC} ${BOLD}$1${NC}"; }

#######################################
# Check root
#######################################
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        echo "Please run: sudo bash $0"
        exit 1
    fi
}

#######################################
# Detect OS
#######################################
detect_os() {
    print_step "Detecting operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        print_error "Cannot detect OS!"
        exit 1
    fi
    
    print_success "Detected: $OS $OS_VERSION"
    
    # Check compatibility
    case "$OS" in
        ubuntu)
            if [[ "$OS_VERSION" != "22.04" ]] && [[ "$OS_VERSION" != "24.04" ]]; then
                print_error "Unsupported Ubuntu version: $OS_VERSION"
                print_info "Supported: Ubuntu 22.04, 24.04"
                exit 1
            fi
            PKG_MANAGER="apt-get"
            ;;
        almalinux|rocky)
            if [[ "$OS_VERSION" != 8* ]] && [[ "$OS_VERSION" != 9* ]]; then
                print_error "Unsupported version: $OS_VERSION"
                print_info "Supported: AlmaLinux/Rocky Linux 8, 9"
                exit 1
            fi
            PKG_MANAGER="dnf"
            ;;
        *)
            print_error "Unsupported OS: $OS"
            print_info "Supported: Ubuntu 22.04/24.04, AlmaLinux 8/9, Rocky Linux 8/9"
            exit 1
            ;;
    esac
}

#######################################
# Update system
#######################################
update_system() {
    print_step "Updating system packages..."
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get update -qq
            apt-get upgrade -y -qq
            ;;
        dnf)
            dnf update -y -q
            ;;
    esac
    
    print_success "System updated"
}

#######################################
# Install dependencies
#######################################
install_dependencies() {
    print_step "Installing dependencies..."
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y -qq curl wget git tar gzip unzip software-properties-common \
                build-essential libssl-dev ca-certificates gnupg lsb-release \
                netcat net-tools htop iotop screen vim nano ufw fail2ban \
                >/dev/null 2>&1
            ;;
        dnf)
            dnf install -y -q curl wget git tar gzip unzip \
                gcc gcc-c++ make openssl-devel ca-certificates \
                nc net-tools htop iotop screen vim nano firewalld fail2ban \
                >/dev/null 2>&1
            ;;
    esac
    
    print_success "Dependencies installed"
}

#######################################
# Install Nginx
#######################################
install_nginx() {
    print_step "Installing Nginx..."
    
    if command -v nginx >/dev/null 2>&1; then
        print_warning "Nginx already installed, skipping..."
        return
    fi
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y -qq nginx >/dev/null 2>&1
            ;;
        dnf)
            dnf install -y -q nginx >/dev/null 2>&1
            ;;
    esac
    
    systemctl enable nginx
    systemctl start nginx
    
    print_success "Nginx installed and started"
}

#######################################
# Install NVM and Node.js
#######################################
install_node() {
    print_step "Installing NVM and Node.js..."
    
    # Install NVM
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >/dev/null 2>&1
        
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        print_success "NVM installed"
    else
        print_warning "NVM already installed"
    fi
    
    # Install Node.js LTS
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    nvm install --lts >/dev/null 2>&1
    nvm use --lts >/dev/null 2>&1
    nvm alias default 'lts/*' >/dev/null 2>&1
    
    NODE_VERSION=$(node -v)
    print_success "Node.js $NODE_VERSION installed"
}

#######################################
# Install PM2
#######################################
install_pm2() {
    print_step "Installing PM2..."
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    npm install -g pm2 >/dev/null 2>&1
    pm2 startup systemd -u root --hp /root >/dev/null 2>&1
    pm2 save >/dev/null 2>&1
    
    print_success "PM2 installed"
}

#######################################
# Install PostgreSQL
#######################################
install_postgresql() {
    print_step "Installing PostgreSQL..."
    
    if command -v psql >/dev/null 2>&1; then
        print_warning "PostgreSQL already installed, skipping..."
        return
    fi
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y -qq postgresql postgresql-contrib >/dev/null 2>&1
            ;;
        dnf)
            dnf install -y -q postgresql-server postgresql-contrib >/dev/null 2>&1
            postgresql-setup --initdb >/dev/null 2>&1
            ;;
    esac
    
    systemctl enable postgresql
    systemctl start postgresql
    
    print_success "PostgreSQL installed"
}

#######################################
# Install MongoDB
#######################################
install_mongodb() {
    print_step "Installing MongoDB..."
    
    if command -v mongod >/dev/null 2>&1; then
        print_warning "MongoDB already installed, skipping..."
        return
    fi
    
    case "$PKG_MANAGER" in
        apt-get)
            curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            apt-get update -qq
            apt-get install -y -qq mongodb-org >/dev/null 2>&1
            ;;
        dnf)
            cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
            dnf install -y -q mongodb-org >/dev/null 2>&1
            ;;
    esac
    
    systemctl enable mongod
    systemctl start mongod
    
    print_success "MongoDB installed"
}

#######################################
# Install MySQL/MariaDB
#######################################
install_mysql() {
    print_step "Installing MariaDB..."
    
    if command -v mysql >/dev/null 2>&1; then
        print_warning "MySQL/MariaDB already installed, skipping..."
        return
    fi
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y -qq mariadb-server mariadb-client >/dev/null 2>&1
            ;;
        dnf)
            dnf install -y -q mariadb-server mariadb >/dev/null 2>&1
            ;;
    esac
    
    systemctl enable mariadb
    systemctl start mariadb
    
    print_success "MariaDB installed"
}

#######################################
# Install Redis
#######################################
install_redis() {
    print_step "Installing Redis..."
    
    if command -v redis-cli >/dev/null 2>&1; then
        print_warning "Redis already installed, skipping..."
        return
    fi
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y -qq redis-server >/dev/null 2>&1
            systemctl enable redis-server
            systemctl start redis-server
            ;;
        dnf)
            dnf install -y -q redis >/dev/null 2>&1
            systemctl enable redis
            systemctl start redis
            ;;
    esac
    
    print_success "Redis installed"
}

#######################################
# Install Certbot (Let's Encrypt)
#######################################
install_certbot() {
    print_step "Installing Certbot..."
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y -qq certbot python3-certbot-nginx >/dev/null 2>&1
            ;;
        dnf)
            dnf install -y -q certbot python3-certbot-nginx >/dev/null 2>&1
            ;;
    esac
    
    print_success "Certbot installed"
}

#######################################
# Setup Firewall
#######################################
setup_firewall() {
    print_step "Configuring firewall..."
    
    case "$PKG_MANAGER" in
        apt-get)
            ufw --force enable >/dev/null 2>&1
            ufw allow 22/tcp >/dev/null 2>&1
            ufw allow 80/tcp >/dev/null 2>&1
            ufw allow 443/tcp >/dev/null 2>&1
            ;;
        dnf)
            systemctl enable firewalld >/dev/null 2>&1
            systemctl start firewalld >/dev/null 2>&1
            firewall-cmd --permanent --add-service=ssh >/dev/null 2>&1
            firewall-cmd --permanent --add-service=http >/dev/null 2>&1
            firewall-cmd --permanent --add-service=https >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1
            ;;
    esac
    
    print_success "Firewall configured"
}

#######################################
# Setup Fail2ban
#######################################
setup_fail2ban() {
    print_step "Configuring Fail2ban..."
    
    systemctl enable fail2ban >/dev/null 2>&1
    systemctl start fail2ban >/dev/null 2>&1
    
    print_success "Fail2ban configured"
}

#######################################
# Clone NDC OLS repository
#######################################
clone_ndc_ols() {
    print_step "Installing NDC OLS files..."
    
    # Create directories
    mkdir -p "$NDC_INSTALL_DIR"
    mkdir -p "$NDC_CONFIG_DIR"
    mkdir -p "$NDC_LOG_DIR"
    mkdir -p "$NDC_BACKUP_DIR"
    mkdir -p "$NDC_INSTALL_DIR/modules"
    mkdir -p "$NDC_INSTALL_DIR/utils"
    mkdir -p "$NDC_INSTALL_DIR/templates"
    
    # Download or copy files
    if [ -d "$(dirname "$0")/modules" ]; then
        # Local installation
        cp -r "$(dirname "$0")"/* "$NDC_INSTALL_DIR/"
    else
        # Remote installation
        # Remove existing directory if it exists to avoid clone errors
        rm -rf "$NDC_INSTALL_DIR"
        mkdir -p "$NDC_INSTALL_DIR"
        
        git clone "$GITHUB_REPO" "$NDC_INSTALL_DIR" || {
            print_error "Failed to clone repository from $GITHUB_REPO"
            exit 1
        }
    fi
    
    # Set permissions
    chmod +x "$NDC_INSTALL_DIR/ndc-ols.sh"
    chmod +x "$NDC_INSTALL_DIR/modules/"*.sh
    chmod +x "$NDC_INSTALL_DIR/utils/"*.sh
    
    print_success "NDC OLS files installed"
}

#######################################
# Create symlink
#######################################
create_symlink() {
    print_step "Creating command shortcuts..."
    
    ln -sf "$NDC_INSTALL_DIR/ndc-ols.sh" /usr/local/bin/ndc
    ln -sf "$NDC_INSTALL_DIR/ndc-ols.sh" /usr/local/bin/ndc-ols
    
    print_success "Commands created: ndc, ndc-ols"
}

#######################################
# Create config file
#######################################
create_config() {
    print_step "Creating configuration..."
    
    cat > "$NDC_CONFIG_DIR/settings.conf" <<EOF
# NDC OLS Configuration
NDC_VERSION="$NDC_VERSION"
NDC_INSTALL_DIR="$NDC_INSTALL_DIR"
NDC_CONFIG_DIR="$NDC_CONFIG_DIR"
NDC_APPS_DIR="/var/www"
NDC_LOG_DIR="$NDC_LOG_DIR"
NDC_BACKUP_DIR="$NDC_BACKUP_DIR"
INSTALL_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
OS="$OS"
OS_VERSION="$OS_VERSION"
EOF
    
    touch "$NDC_CONFIG_DIR/apps.conf"
    
    print_success "Configuration created"
}

#######################################
# Show completion message
#######################################
show_completion() {
    clear
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}          ✓ NDC OLS Installed Successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Installed Components:${NC}"
    echo -e "  ${GREEN}✓${NC} Nginx web server"
    echo -e "  ${GREEN}✓${NC} Node.js + NVM"
    echo -e "  ${GREEN}✓${NC} PM2 process manager"
    echo -e "  ${GREEN}✓${NC} PostgreSQL database"
    echo -e "  ${GREEN}✓${NC} MongoDB database"
    echo -e "  ${GREEN}✓${NC} MariaDB database"
    echo -e "  ${GREEN}✓${NC} Redis cache"
    echo -e "  ${GREEN}✓${NC} Let's Encrypt SSL"
    echo -e "  ${GREEN}✓${NC} Firewall (UFW/Firewalld)"
    echo -e "  ${GREEN}✓${NC} Fail2ban protection"
    echo ""
    echo -e "${CYAN}Quick Start:${NC}"
    echo -e "  Run: ${YELLOW}ndc${NC} or ${YELLOW}ndc-ols${NC}"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo -e "  https://docs.ndc-ols.com"
    echo ""
    echo -e "${CYAN}Support:${NC}"
    echo -e "  GitHub: https://github.com/ndc-ols"
    echo -e "  Discord: https://discord.gg/ndc-ols"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

#######################################
# Main installation
#######################################
main() {
    print_banner
    
    # Check root
    check_root
    
    # Detect OS
    detect_os
    
    echo ""
    echo -e "${YELLOW}This will install:${NC}"
    echo "  • Nginx, Node.js, PM2"
    echo "  • PostgreSQL, MongoDB, MariaDB, Redis"
    echo "  • SSL (Let's Encrypt), Firewall, Fail2ban"
    echo ""
    
    # Check if running interactively
    if [ -t 0 ]; then
        read -p "$(echo -e "${CYAN}Continue with installation? [y/N]:${NC} ")" confirm
    else
        # If piped, try to read from /dev/tty
        if [ -c /dev/tty ]; then
            read -p "$(echo -e "${CYAN}Continue with installation? [y/N]:${NC} ")" confirm < /dev/tty
        else
            # If no tty, assume yes (for automated installs) or exit
            # For safety, let's assume yes if it's a pipe install intended to be automated, 
            # but usually curl | bash implies "do it".
            confirm="y"
        fi
    fi
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 1
    fi
    
    echo ""
    print_step "Starting installation..."
    echo ""
    
    # Installation steps
    update_system
    install_dependencies
    install_nginx
    install_node
    install_pm2
    install_postgresql
    install_mongodb
    install_mysql
    install_redis
    install_certbot
    setup_firewall
    setup_fail2ban
    clone_ndc_ols
    create_symlink
    create_config
    
    # Show completion
    show_completion
}

# Run main
main "$@"
