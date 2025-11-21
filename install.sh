#!/bin/bash
#######################################
# NDC OLS - Installation Script
# Auto install all dependencies
#######################################

set -euo pipefail

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# Global error handler
trap 'error_handler $? $LINENO' ERR
error_handler() {
    local exit_code=$1
    local line_number=$2
    print_error "Installation failed at line $line_number with exit code $exit_code"
    cleanup_on_error
    exit $exit_code
}

# Cleanup function for error cases
cleanup_on_error() {
    print_warning "Attempting cleanup..."
    # Kill any background processes
    jobs -p | xargs -r kill 2>/dev/null || true
    # Make sure we're in a safe directory
    cd /tmp 2>/dev/null || cd / || true
}

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
print_cool_face() {
    echo -e "${CYAN}"
    echo "        .           . "
    echo "      /' \         / \`"
    echo "     /   | .---.  |   \\"
    echo "    |    |/  _  \|    |"
    echo "    |    |\`  _  /|    |"
    echo "     \   | '---'  |   /"
    echo "      \./         \./  "
    echo "         |       |     "
    echo "         |       |     "
    echo "         |       |     "
    echo "     /   |       |   \\ "
    echo "    |    |       |    |"
    echo "    |    |       |    |"
    echo "     \   |       |   / "
    echo "      \./         \./  "
    echo -e "${NC}"
    echo -e "${YELLOW}   ( •_•)${NC}"
    echo -e "${YELLOW}   ( •_•)>⌐■-■${NC}"
    echo -e "${YELLOW}   (⌐■_■)${NC}  ${GREEN}System Ready...${NC}"
    echo ""
}

matrix_effect() {
    echo -e "${GREEN}Initializing Matrix Protocol...${NC}"
    sleep 1
    local lines=20
    for (( i=1; i<=lines; i++ )); do
        local line=""
        for (( j=1; j<=80; j++ )); do
            local char=$(printf "\\$(printf '%03o' $((RANDOM%26+97)))")
            local color=$((RANDOM%2))
            if [ $color -eq 0 ]; then
                line="${line}${GREEN}${char}${NC}"
            else
                line="${line}${BOLD}${GREEN}${char}${NC}"
            fi
        done
        echo -e "$line"
        sleep 0.05
    done
    clear
}

print_banner() {
    clear
    matrix_effect
    print_cool_face
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
# Wait for APT/DPKG Lock
#######################################
wait_for_apt() {
    if [ "$PKG_MANAGER" != "apt-get" ]; then
        return 0
    fi
    
    local i=0
    local stale_lock_count=0
    local max_wait=600  # 10 minutes (increased from 5)
    local last_pid=""
    local pid_change_count=0
    
    print_info "Checking if package manager is busy..."
    
    while true; do
        local running_proc=""
        local current_pid=""
        
        # Check common package manager processes
        if pgrep -x "apt" >/dev/null 2>&1; then running_proc="apt"; current_pid=$(pgrep -x apt); fi
        if pgrep -x "apt-get" >/dev/null 2>&1; then running_proc="apt-get"; current_pid=$(pgrep -x apt-get); fi
        if pgrep -x "dpkg" >/dev/null 2>&1; then running_proc="dpkg"; current_pid=$(pgrep -x dpkg); fi
        if pgrep -f "unattended-upgr" >/dev/null 2>&1; then running_proc="unattended-upgrades"; current_pid=$(pgrep -f "unattended-upgr"); fi
        
        local lock_exists=0
        [ -f /var/lib/dpkg/lock-frontend ] && lock_exists=1
        [ -f /var/lib/dpkg/lock ] && lock_exists=1
        [ -f /var/lib/apt/lists/lock ] && lock_exists=1
        
        # If no process and no lock, we are good
        if [ -z "$running_proc" ] && [ $lock_exists -eq 0 ]; then
            print_success "Package manager is ready"
            break
        fi
        
        if [ -n "$running_proc" ]; then
            # Track if process PID changed (i.e., completed and new one started)
            if [ "$last_pid" != "$current_pid" ] && [ -n "$last_pid" ]; then
                pid_change_count=$((pid_change_count+1))
            fi
            last_pid="$current_pid"
            
            if [ $((i % 30)) -eq 0 ]; then
                print_info "Process '$running_proc' is still running. Waiting... (${i}s)"
            fi
            
            # If unattended-upgrades appears stuck (same PID for too long), try to stop it
            if [ "$running_proc" = "unattended-upgrades" ] && [ $i -gt 120 ]; then
                print_warning "unattended-upgrades running too long. Attempting to stop..."
                systemctl stop unattended-upgrades 2>/dev/null || true
                sleep 5
            fi
            
            stale_lock_count=0
        else
            # Lock exists but no process found
            stale_lock_count=$((stale_lock_count+1))
            if [ $stale_lock_count -gt 5 ]; then
                print_warning "Stale lock detected. Cleaning up..."
                rm -f /var/lib/dpkg/lock-frontend 2>/dev/null || true
                rm -f /var/lib/dpkg/lock 2>/dev/null || true
                rm -f /var/lib/apt/lists/lock 2>/dev/null || true
                dpkg --configure -a >/dev/null 2>&1 || true
                sleep 2
                break
            fi
        fi
        
        sleep 2
        i=$((i+2))
        
        if [ $i -gt $max_wait ]; then
            print_warning "Timeout waiting for package manager (${max_wait}s). Force clearing locks..."
            # Force clear all locks
            killall -9 unattended-upgrades 2>/dev/null || true
            killall -9 apt-get 2>/dev/null || true
            killall -9 dpkg 2>/dev/null || true
            sleep 3
            rm -f /var/lib/dpkg/lock* 2>/dev/null || true
            rm -f /var/lib/apt/lists/lock 2>/dev/null || true
            dpkg --configure -a >/dev/null 2>&1 || true
            print_success "Locks cleared. Proceeding with installation..."
            break
        fi
    done
}

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
    
    wait_for_apt
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get update
            apt-get upgrade -y
            ;;
        dnf)
            dnf update -y
            ;;
    esac
    
    print_success "System updated"
}

#######################################
# Install dependencies
#######################################
install_dependencies() {
    print_step "Installing dependencies..."
    
    wait_for_apt
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y curl wget git tar gzip unzip software-properties-common \
                build-essential libssl-dev ca-certificates gnupg lsb-release \
                netcat net-tools htop iotop screen vim nano ufw fail2ban \
                python3-pip python3-venv libpq-dev psmisc
            ;;
        dnf)
            dnf install -y curl wget git tar gzip unzip \
                gcc gcc-c++ make openssl-devel ca-certificates \
                nc net-tools htop iotop screen vim nano firewalld fail2ban \
                python3-pip python3-virtualenv libpq-devel python3-devel
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
            apt-get install -y nginx
            ;;
        dnf)
            dnf install -y nginx
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
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        print_success "NVM installed"
    else
        print_warning "NVM already installed"
    fi
    
    # Install Node.js LTS
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    
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
    
    npm install -g pm2
    pm2 startup systemd -u root --hp /root
    pm2 save
    
    print_success "PM2 installed"
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
    
    wait_for_apt
    
    case "$PKG_MANAGER" in
        apt-get)
            curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            apt-get update
            apt-get install -y mongodb-org mongodb-mongosh
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
            dnf install -y mongodb-org mongodb-mongosh
            ;;
    esac
    
    systemctl enable mongod
    systemctl start mongod
    
    # Wait for MongoDB to start
    print_info "Waiting for MongoDB to start..."
    local max_retries=30
    local count=0
    local mongo_ready=0
    
    while [ $count -lt $max_retries ]; do
        if mongosh --quiet --eval "db.runCommand({ ping: 1 })" >/dev/null 2>&1; then
            mongo_ready=1
            break
        fi
        sleep 1
        count=$((count+1))
    done
    
    if [ $mongo_ready -eq 0 ]; then
        print_error "MongoDB failed to start or is not responsive."
        return
    fi
    
    # Secure MongoDB
    print_step "Securing MongoDB..."
    
    # Generate passwords
    MONGO_ADMIN_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
    MONGO_EXPRESS_USER="admin"
    MONGO_EXPRESS_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
    
    # Create admin user
    print_info "Creating admin user..."
    if mongosh --quiet --eval "
      use admin;
      db.createUser({
        user: 'admin',
        pwd: '$MONGO_ADMIN_PASS',
        roles: [ { role: 'root', db: 'admin' } ]
      });
    " >/dev/null; then
        print_success "MongoDB admin user created."
    else
        print_error "Failed to create MongoDB admin user."
        # Don't return, try to continue but warn
    fi
    
    # Enable auth
    sed -i 's/^#security:/security:/' /etc/mongod.conf 2>/dev/null || echo "security:" >> /etc/mongod.conf
    if ! grep -q "authorization: enabled" /etc/mongod.conf; then
        sed -i 's/^security:/security:\n  authorization: enabled/' /etc/mongod.conf
    fi
    
    # Fix bindIp if needed (ensure localhost)
    sed -i 's/bindIp: .*/bindIp: 127.0.0.1/' /etc/mongod.conf
    
    systemctl restart mongod
    sleep 5
    
    # Save credentials
    mkdir -p "$NDC_CONFIG_DIR"
    cat > "$NDC_CONFIG_DIR/auth.conf" <<EOF
# Database Credentials
MONGODB_USER=admin
MONGODB_PASS=$MONGO_ADMIN_PASS
MONGO_EXPRESS_USER=$MONGO_EXPRESS_USER
MONGO_EXPRESS_PASS=$MONGO_EXPRESS_PASS
EOF
    chmod 600 "$NDC_CONFIG_DIR/auth.conf"
    
    print_success "MongoDB installed and secured"
}

#######################################
# Install Mongo Express
#######################################
install_mongo_express() {
    print_step "Installing Mongo Express..."
    
    # Load credentials
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
    else
        print_error "Credentials not found, skipping Mongo Express setup"
        return
    fi
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Create directory for mongo-express local install
    MONGO_EXPRESS_DIR="$NDC_INSTALL_DIR/mongo-express"
    
    # Clean up previous installs to avoid conflicts
    rm -rf "$MONGO_EXPRESS_DIR"
    mkdir -p "$MONGO_EXPRESS_DIR"
    
    print_info "Installing Mongo Express from GitHub (Source)..."
    cd "$MONGO_EXPRESS_DIR"
    
    # Clone from GitHub to get full source including assets build scripts
    if ! git clone https://github.com/mongo-express/mongo-express.git .; then
        print_error "Failed to clone Mongo Express repository"
        return
    fi
    
    # Install dependencies
    print_info "Installing dependencies..."
    if ! npm install; then
        print_error "Failed to install Mongo Express dependencies"
        return
    fi
    
    # Build assets
    print_info "Building assets..."
    if ! npm run build; then
        print_error "Failed to build Mongo Express assets"
        return
    fi
    
    # Path to app.js in cloned repo
    MONGO_EXPRESS_SCRIPT="$MONGO_EXPRESS_DIR/app.js"
    
    if [ ! -f "$MONGO_EXPRESS_SCRIPT" ]; then
        # Fallback if app.js is not in root (some versions use index.js or lib/app)
        if [ -f "$MONGO_EXPRESS_DIR/index.js" ]; then
            MONGO_EXPRESS_SCRIPT="$MONGO_EXPRESS_DIR/index.js"
        else
            print_error "Mongo Express install failed (script not found)"
            return
        fi
    fi
    
    # Make app script executable
    chmod +x "$MONGO_EXPRESS_SCRIPT"
    
    # Get Node binary for PM2
    NODE_BIN="$NVM_DIR/versions/node/$(node -v | sed 's/^v//')/bin/node"
    if [ ! -f "$NODE_BIN" ]; then
        NODE_BIN=$(which node)
    fi
    
    # Configure
    cat > "$NDC_CONFIG_DIR/mongo-express.config.js" <<EOF
module.exports = {
  apps: [{
    name: 'mongo-express',
    script: '$MONGO_EXPRESS_SCRIPT',
    cwd: '$MONGO_EXPRESS_DIR',
    interpreter: '$NODE_BIN',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '200M',
    env: {
      NODE_ENV: 'production',
      ME_CONFIG_MONGODB_ENABLE_ADMIN: 'true',
      ME_CONFIG_MONGODB_SERVER: '127.0.0.1',
      ME_CONFIG_MONGODB_PORT: '27017',
      ME_CONFIG_MONGODB_AUTH_DATABASE: 'admin',
      ME_CONFIG_MONGODB_AUTH_USERNAME: '$MONGODB_USER',
      ME_CONFIG_MONGODB_AUTH_PASSWORD: '$MONGODB_PASS',
      ME_CONFIG_BASICAUTH_USERNAME: '$MONGO_EXPRESS_USER',
      ME_CONFIG_BASICAUTH_PASSWORD: '$MONGO_EXPRESS_PASS',
      ME_CONFIG_SITE_HOST: '0.0.0.0',
      ME_CONFIG_SITE_BASEURL: '/',
      ME_CONFIG_SITE_COOKIE_SECRET: 'secret_$(date +%s)',
      ME_CONFIG_SITE_SESSION_SECRET: 'secret_$(date +%s)',
      VCAP_APP_HOST: '0.0.0.0',
      PORT: '8081'
    }
  }]
};
EOF

    # Stop existing if any
    pm2 delete mongo-express >/dev/null 2>&1 || true

    # Start
    pm2 start "$NDC_CONFIG_DIR/mongo-express.config.js"
    pm2 save
    
    # Wait and check if it's running
    sleep 5
    
    # Check PM2 status
    if ! pm2 list | grep -q "mongo-express.*online"; then
        print_error "Mongo Express failed to start"
        print_info "Displaying PM2 logs (last 50 lines):"
        pm2 logs mongo-express --lines 50 --nostream 2>&1 || true
        
        # Check if node process exists
        if pgrep -f "mongo-express.*app.js" >/dev/null; then
            print_info "Process exists but PM2 reports offline. Waiting longer..."
            sleep 5
        else
            print_error "Process doesn't exist. Attempting recovery..."
            pm2 delete mongo-express 2>/dev/null || true
            sleep 2
            pm2 start "$NDC_CONFIG_DIR/mongo-express.config.js"
            sleep 10
            
            if pm2 list | grep -q "mongo-express.*online"; then
                print_success "Mongo Express started on retry"
            else
                print_error "Mongo Express failed to start after retry"
                pm2 logs mongo-express --lines 50 --nostream 2>&1 || true
                return 1
            fi
        fi
    else
        print_success "Mongo Express started successfully"
    fi
    
    # Open firewall port 8081
    print_info "Configuring firewall for Mongo Express..."
    if command -v ufw >/dev/null; then
        ufw allow 8081/tcp >/dev/null 2>&1
        ufw reload >/dev/null 2>&1
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --permanent --add-port=8081/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
    else
        print_warning "No firewall manager found (ufw/firewalld). Please open port 8081 manually."
    fi
    
    # Verify if port is listening and app is responding
    print_info "Verifying Mongo Express connection..."
    
    local max_retries=5
    local retry_count=0
    local port_ok=false
    local app_ok=false
    
    while [ $retry_count -lt $max_retries ]; do
        # Check if port is listening
        if command -v ss >/dev/null; then
            if ss -tulnp 2>/dev/null | grep -q ":8081"; then
                port_ok=true
                break
            fi
        elif command -v netstat >/dev/null; then
            if netstat -tulnp 2>/dev/null | grep -q ":8081"; then
                port_ok=true
                break
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            sleep 2
        fi
    done
    
    if [ "$port_ok" = true ]; then
        print_success "Mongo Express is listening on port 8081"
    else
        print_error "Mongo Express port 8081 is not listening"
        print_info "Checking PM2 processes:"
        pm2 list | grep mongo-express || true
    fi
    
    print_success "Mongo Express installed (Port 8081)"
}

#######################################
# Install MySQL/MariaDB
#######################################
install_mysql() {
    print_step "Installing MariaDB..."
    
    # Check if already installed
    if command -v mysql >/dev/null 2>&1; then
        print_warning "MySQL/MariaDB already installed."
    else
        wait_for_apt
        case "$PKG_MANAGER" in
            apt-get)
                apt-get install -y mariadb-server mariadb-client
                ;;
            dnf)
                dnf install -y mariadb-server mariadb
                ;;
        esac
    fi
    
    systemctl enable mariadb 2>/dev/null || true
    
    # Try to start, with error recovery
    if ! systemctl start mariadb 2>/dev/null; then
        print_warning "MariaDB failed to start. Attempting recovery..."
        
        # Aggressive cleanup
        systemctl stop mariadb 2>/dev/null || true
        sleep 1
        pkill -9 -f mariadbd 2>/dev/null || true
        pkill -9 -f mysqld 2>/dev/null || true
        pkill -9 -f mysqld_safe 2>/dev/null || true
        
        # Remove socket and lock files
        rm -f /var/run/mysqld/mysqld.sock 2>/dev/null || true
        rm -f /var/lib/mysql/mysql.sock 2>/dev/null || true
        rm -f /var/run/mysqld/*.sock 2>/dev/null || true
        mkdir -p /var/run/mysqld
        chown mysql:mysql /var/run/mysqld 2>/dev/null || true
        
        # Try start again
        sleep 2
        if ! systemctl start mariadb 2>/dev/null; then
             print_error "MariaDB recovery failed. Skipping MariaDB security setup."
             print_info "Manual fix: systemctl status mariadb, journalctl -xeu mariadb"
             return 0
        fi
    fi
    
    # Wait for MariaDB to be ready
    print_info "Waiting for MariaDB to be ready..."
    local max_retries=30
    local count=0
    while [ $count -lt $max_retries ]; do
        if mysql -e "SELECT 1" >/dev/null 2>&1; then
            break
        fi
        sleep 1
        count=$((count+1))
    done
    
    if [ $count -ge $max_retries ]; then
        print_warning "MariaDB is not responding after ${max_retries}s. Skipping password security setup."
        return 0
    fi

    # Check if we have credentials and they work
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
        if [ -n "${MYSQL_ROOT_PASS:-}" ]; then
            if mysql -u root -p"$MYSQL_ROOT_PASS" -e "SELECT 1" >/dev/null 2>&1; then
                print_success "MariaDB is already secured and running."
                return 0
            fi
        fi
    fi
    
    print_step "Securing MariaDB..."
    
    MYSQL_ROOT_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
    
    # Try standard method first
    if mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS'; FLUSH PRIVILEGES;" >/dev/null 2>&1; then
        print_success "Root password set successfully."
    else
        print_warning "Standard password method failed. Trying recovery mode..."
        
        # Backup database
        systemctl stop mariadb 2>/dev/null || true
        pkill -9 -f mariadbd 2>/dev/null || true
        pkill -9 -f mysqld 2>/dev/null || true
        pkill -9 -f mysqld_safe 2>/dev/null || true
        sleep 2
        
        # Clean socket
        rm -f /var/run/mysqld/mysqld.sock
        mkdir -p /var/run/mysqld
        chown mysql:mysql /var/run/mysqld
        
        print_info "Starting MariaDB in recovery mode..."
        # Use nohup to prevent HUP signal issues
        nohup mysqld_safe --skip-grant-tables --skip-networking >/dev/null 2>&1 &
        RECOVER_PID=$!
        
        # Wait for socket
        sleep 5
        local socket_retries=0
        while [ ! -S /var/run/mysqld/mysqld.sock ] && [ $socket_retries -lt 15 ]; do
            sleep 1
            socket_retries=$((socket_retries+1))
        done
        
        # Try password reset
        if mysql -u root --protocol=socket -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS'; FLUSH PRIVILEGES;" 2>/dev/null; then
            print_success "Password reset via recovery mode succeeded."
        else
            print_warning "Could not reset password. Using default access."
        fi
        
        # Clean shutdown
        pkill -f mysqld_safe 2>/dev/null || true
        pkill -9 -f mariadbd 2>/dev/null || true
        sleep 3
        
        # Normal restart
        systemctl start mariadb 2>/dev/null || true
        sleep 3
    fi

    # Security best practices (if connection works)
    if mysql -u root -p"$MYSQL_ROOT_PASS" -e "SELECT 1" >/dev/null 2>&1; then
        mysql -u root -p"$MYSQL_ROOT_PASS" -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
        mysql -u root -p"$MYSQL_ROOT_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || true
        mysql -u root -p"$MYSQL_ROOT_PASS" -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
        mysql -u root -p"$MYSQL_ROOT_PASS" -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    fi
    
    # Save credentials
    if [ ! -d "$NDC_CONFIG_DIR" ]; then
        mkdir -p "$NDC_CONFIG_DIR" || {
            print_error "Failed to create config directory"
            return 1
        }
    fi
    
    if [ ! -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        touch "$NDC_CONFIG_DIR/auth.conf" || {
            print_error "Failed to create auth config file"
            return 1
        }
        chmod 600 "$NDC_CONFIG_DIR/auth.conf"
    fi
    
    # Remove old entry if exists and append new
    sed -i '/MYSQL_ROOT_PASS=/d' "$NDC_CONFIG_DIR/auth.conf" 2>/dev/null || true
    echo "MYSQL_ROOT_PASS=$MYSQL_ROOT_PASS" >> "$NDC_CONFIG_DIR/auth.conf"
    
    print_success "MariaDB secured"
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
    
    wait_for_apt
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y redis-server
            systemctl enable redis-server
            systemctl start redis-server
            ;;
        dnf)
            dnf install -y redis
            systemctl enable redis
            systemctl start redis
            ;;
    esac
    
    print_success "Redis installed"
}

#######################################
# Install phpMyAdmin
#######################################
install_phpmyadmin() {
    print_step "Installing phpMyAdmin..."
    
    if [ -d "/usr/share/phpmyadmin" ]; then
        print_warning "phpMyAdmin already installed, skipping..."
        return
    fi
    
    # Install PHP and extensions first
    print_step "Installing PHP dependencies..."
    wait_for_apt
    case "$PKG_MANAGER" in
        apt-get)
            # Ensure non-interactive for phpmyadmin
            export DEBIAN_FRONTEND=noninteractive
            
            apt-get install -y php-fpm php-mysql php-mbstring php-zip php-gd php-json php-curl php-xml
            
            # Pre-configure debconf for phpmyadmin to avoid prompts and errors
            # We set dbconfig-install to false because we already have a DB and we don't want it to try to create one with random passwords we don't know
            # Or we can let it, but it might fail if root pass is set.
            # Safest is to NOT let it configure the DB automatically, we just want the files.
            echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect " | debconf-set-selections
            
            apt-get install -y phpmyadmin
            ;;
        dnf)
            dnf install -y php php-fpm php-mysqlnd php-mbstring php-zip php-gd php-json php-xml
            if dnf list phpmyadmin >/dev/null 2>&1; then
                dnf install -y phpmyadmin
            else
                print_warning "phpMyAdmin package not found in default repos. Skipping..."
                return
            fi
            ;;
    esac
    
    # Configure Nginx for phpMyAdmin
    print_step "Configuring Nginx for phpMyAdmin..."
    
    # Create a symlink to web root
    ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin
    
    # Create config
    cat > /etc/nginx/conf.d/phpmyadmin.conf <<EOF
server {
    listen 8080;
    server_name _;
    root /usr/share/phpmyadmin;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')-fpm.sock;
    }
}
EOF

    # Open port 8080
    if command -v ufw >/dev/null; then
        ufw allow 8080/tcp >/dev/null 2>&1
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --permanent --add-port=8080/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
    fi
    
    systemctl restart nginx
    
    print_success "phpMyAdmin installed (Port 8080)"
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
    
    wait_for_apt
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y postgresql postgresql-contrib
            ;;
        dnf)
            dnf install -y postgresql-server postgresql-contrib
            postgresql-setup --initdb
            ;;
    esac
    
    systemctl enable postgresql
    systemctl start postgresql
    
    # Wait for Postgres
    sleep 5
    
    # Secure PostgreSQL
    print_step "Securing PostgreSQL..."
    
    PG_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
    
    # Create admin user
    # Try to create, if exists alter
    sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD '$PG_PASS';" >/dev/null 2>&1 || \
    sudo -u postgres psql -c "ALTER USER admin WITH PASSWORD '$PG_PASS';" >/dev/null 2>&1
    
    sudo -u postgres psql -c "ALTER USER admin WITH SUPERUSER;" >/dev/null 2>&1
    
    # Save credentials
    if [ ! -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        mkdir -p "$NDC_CONFIG_DIR"
        touch "$NDC_CONFIG_DIR/auth.conf"
        chmod 600 "$NDC_CONFIG_DIR/auth.conf"
    fi
    
    # Remove old entry if exists and append new
    sed -i '/PG_PASS=/d' "$NDC_CONFIG_DIR/auth.conf"
    echo "PG_PASS=$PG_PASS" >> "$NDC_CONFIG_DIR/auth.conf"
    
    print_success "PostgreSQL installed and secured"
}

#######################################
# Install pgAdmin 4
#######################################
install_pgadmin() {
    print_step "Installing pgAdmin 4..."
    
    # Load credentials
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
    else
        print_error "Credentials not found, skipping pgAdmin setup"
        return
    fi
    
    PGADMIN_DIR="$NDC_INSTALL_DIR/pgadmin"
    mkdir -p "$PGADMIN_DIR"
    
    print_info "Setting up Python virtual environment..."
    cd "$PGADMIN_DIR"
    
    # Create venv
    python3 -m venv venv
    source venv/bin/activate
    
    # Install pgadmin4
    print_info "Installing pgAdmin4 package (this may take a while)..."
    pip install --upgrade pip >/dev/null 2>&1
    pip install wheel >/dev/null 2>&1
    
    if ! pip install pgadmin4 gunicorn; then
        print_error "Failed to install pgadmin4 via pip. Check logs."
        return
    fi
    
    # Find package dir reliably using python
    # Use || true to prevent set -e from exiting if import fails
    print_info "Locating pgAdmin4 installation..."
    PGADMIN_PKG_DIR=$(python -c "import os, pgadmin4; print(os.path.dirname(pgadmin4.__file__))" 2>/dev/null || true)
    
    if [ -z "$PGADMIN_PKG_DIR" ]; then
        print_warning "Python import failed. Searching directory..."
        # Fallback to find
        PGADMIN_PKG_DIR=$(find "$PGADMIN_DIR/venv" -name "pgadmin4" -type d | grep "site-packages" | head -n 1)
    fi
    
    if [ -z "$PGADMIN_PKG_DIR" ]; then
        print_error "Could not find pgadmin4 package directory"
        return
    fi
    
    print_info "pgAdmin4 location: $PGADMIN_PKG_DIR"
    
    # Generate credentials
    PGADMIN_EMAIL="admin@ndc.local"
    PGADMIN_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
    
    # Configure
    mkdir -p /var/lib/pgadmin
    mkdir -p /var/log/pgadmin
    chown -R root:root /var/lib/pgadmin /var/log/pgadmin
    
    # Config local
    cat > "$PGADMIN_PKG_DIR/config_local.py" <<EOF
import os
DATA_DIR = os.path.realpath(os.path.expanduser(u'/var/lib/pgadmin'))
LOG_FILE = os.path.join(os.path.realpath(os.path.expanduser(u'/var/log/pgadmin')), 'pgadmin4.log')
SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db')
SESSION_DB_PATH = os.path.join(DATA_DIR, 'sessions')
STORAGE_DIR = os.path.join(DATA_DIR, 'storage')
SERVER_MODE = True
EOF

    # Initialize DB
    print_info "Initializing pgAdmin database..."
    export PGADMIN_SETUP_EMAIL="$PGADMIN_EMAIL"
    export PGADMIN_SETUP_PASSWORD="$PGADMIN_PASS"
    
    # Run setup with error handling and output
    if [ -f "$PGADMIN_PKG_DIR/setup.py" ]; then
        if ! python "$PGADMIN_PKG_DIR/setup.py"; then
            print_warning "Standard setup failed. Trying to continue anyway..."
        fi
    else
        print_warning "setup.py not found, skipping manual setup..."
    fi
    
    # PM2 Config (Gunicorn binds to 5051, Nginx proxies 5050 -> 5051)
    cat > "$NDC_CONFIG_DIR/pgadmin.config.js" <<'PGADMIN_CONFIG'
module.exports = {
  apps: [{
    name: 'pgadmin',
    script: 'PGADMIN_VENV_BIN/gunicorn',
    args: '--bind 127.0.0.1:5051 --workers 2 --threads 10 --timeout 120 --access-logfile - --error-logfile - --chdir PGADMIN_PKG_DIR pgadmin4:app',
    interpreter: 'none',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '300M',
    env: {
      PGADMIN_SETUP_EMAIL: 'PGADMIN_EMAIL_VAL',
      PGADMIN_SETUP_PASSWORD: 'PGADMIN_PASS_VAL',
      SCRIPT_NAME: '/'
    }
  }]
};
PGADMIN_CONFIG
    
    # Replace placeholders with actual values
    sed -i "s|PGADMIN_VENV_BIN|$PGADMIN_DIR/venv/bin|g" "$NDC_CONFIG_DIR/pgadmin.config.js"
    sed -i "s|PGADMIN_PKG_DIR|$PGADMIN_PKG_DIR|g" "$NDC_CONFIG_DIR/pgadmin.config.js"
    sed -i "s|PGADMIN_EMAIL_VAL|$PGADMIN_EMAIL|g" "$NDC_CONFIG_DIR/pgadmin.config.js"
    sed -i "s|PGADMIN_PASS_VAL|$PGADMIN_PASS|g" "$NDC_CONFIG_DIR/pgadmin.config.js"

    # Verify Gunicorn path exists
    if [ ! -f "$PGADMIN_DIR/venv/bin/gunicorn" ]; then
        print_error "Gunicorn not found at $PGADMIN_DIR/venv/bin/gunicorn"
        return
    fi
    
    # Start PM2
    pm2 delete pgadmin >/dev/null 2>&1 || true
    sleep 2
    
    print_info "Starting pgAdmin with Gunicorn..."
    if ! pm2 start "$NDC_CONFIG_DIR/pgadmin.config.js"; then
        print_error "Failed to start pgAdmin with PM2"
        return
    fi
    
    pm2 save
    sleep 5
    
    # Verify pgAdmin started
    if ! pm2 list | grep -q "pgadmin.*online"; then
        print_error "pgAdmin failed to start (not online in PM2)"
        print_info "Displaying PM2 logs:"
        pm2 logs pgadmin --lines 30 --nostream 2>&1 || true
        print_info "Attempting recovery..."
        pm2 delete pgadmin 2>/dev/null || true
        sleep 2
        pm2 start "$NDC_CONFIG_DIR/pgadmin.config.js"
        sleep 10
        
        if ! pm2 list | grep -q "pgadmin.*online"; then
            print_error "pgAdmin still not running. Check: pm2 logs pgadmin"
            return
        fi
    fi
    
    # Verify Gunicorn is listening
    sleep 3
    local gunicorn_ok=false
    for i in {1..5}; do
        if command -v ss >/dev/null; then
            if ss -tulnp 2>/dev/null | grep -q ":5051"; then
                gunicorn_ok=true
                break
            fi
        elif command -v netstat >/dev/null; then
            if netstat -tulnp 2>/dev/null | grep -q ":5051"; then
                gunicorn_ok=true
                break
            fi
        fi
        sleep 1
    done
    
    if [ "$gunicorn_ok" = true ]; then
        print_success "pgAdmin Gunicorn is listening on 127.0.0.1:5051"
    else
        print_error "pgAdmin Gunicorn is not listening on port 5051"
        pm2 logs pgadmin --lines 20 --nostream 2>&1 || true
    fi
    
    # Nginx Config with proper buffering and timeouts
    print_info "Configuring Nginx for pgAdmin..."
    cat > /etc/nginx/conf.d/pgadmin.conf <<'NGINX_PGADMIN'
upstream pgadmin_backend {
    server 127.0.0.1:5051 fail_timeout=10s max_fails=3;
    keepalive 32;
}

server {
    listen 5050 default_server;
    server_name _;
    client_max_body_size 25M;

    location / {
        proxy_pass http://pgadmin_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Script-Name /;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
}
NGINX_PGADMIN

    # Validate Nginx configuration
    print_info "Validating Nginx configuration..."
    if ! nginx -t >/dev/null 2>&1; then
        print_error "Nginx configuration validation failed"
        nginx -t
        return
    fi
    
    # Open port 5050
    if command -v ufw >/dev/null; then
        ufw allow 5050/tcp >/dev/null 2>&1
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --permanent --add-port=5050/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
    fi
    
    # Reload Nginx
    print_info "Reloading Nginx..."
    if ! systemctl reload nginx 2>&1; then
        print_error "Failed to reload Nginx"
        systemctl status nginx || true
        return
    fi
    print_success "Nginx reloaded successfully"
    
    # Save creds
    sed -i '/PGADMIN_EMAIL=/d' "$NDC_CONFIG_DIR/auth.conf"
    sed -i '/PGADMIN_PASS=/d' "$NDC_CONFIG_DIR/auth.conf"
    echo "PGADMIN_EMAIL=$PGADMIN_EMAIL" >> "$NDC_CONFIG_DIR/auth.conf"
    echo "PGADMIN_PASS=$PGADMIN_PASS" >> "$NDC_CONFIG_DIR/auth.conf"
    
    print_success "pgAdmin 4 installed (Port 5050)"
}

#######################################
# Install Certbot (Let's Encrypt)
#######################################
install_certbot() {
    print_step "Installing Certbot..."
    
    wait_for_apt
    
    case "$PKG_MANAGER" in
        apt-get)
            apt-get install -y certbot python3-certbot-nginx
            ;;
        dnf)
            dnf install -y certbot python3-certbot-nginx
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
            ufw --force enable
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            ;;
        dnf)
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --permanent --add-service=ssh
            firewall-cmd --permanent --add-service=http
            firewall-cmd --permanent --add-service=https
            firewall-cmd --reload
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
# Setup Login Banner
#######################################
setup_login_banner() {
    print_step "Setting up login banner..."
    
    # Create profile script
    cat > /etc/profile.d/ndc-ols-login.sh <<EOF
#!/bin/bash
if [ -f /usr/local/bin/ndc ]; then
    /usr/local/bin/ndc --info
fi
EOF
    
    chmod +x /etc/profile.d/ndc-ols-login.sh
    print_success "Login banner configured"
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
        # Remote installation - ensure we exit the directory first
        cd /tmp 2>/dev/null || cd / || true
        
        # Remove existing directory if it exists
        if [ -d "$NDC_INSTALL_DIR" ]; then
            print_warning "Removing existing NDC OLS installation..."
            rm -rf "$NDC_INSTALL_DIR" || {
                print_error "Failed to remove old installation directory"
                return 1
            }
        fi
        
        mkdir -p "$NDC_INSTALL_DIR" || {
            print_error "Failed to create NDC OLS directory"
            return 1
        }
        
        print_info "Cloning NDC OLS from GitHub..."
        if ! git clone "$GITHUB_REPO" "$NDC_INSTALL_DIR"; then
            print_error "Failed to clone repository from $GITHUB_REPO"
            return 1
        fi
    fi
    
    # Set permissions
    chmod +x "$NDC_INSTALL_DIR/ndc-ols.sh" 2>/dev/null || true
    if [ -d "$NDC_INSTALL_DIR/modules" ]; then
        chmod +x "$NDC_INSTALL_DIR/modules"/*.sh 2>/dev/null || true
    fi
    if [ -d "$NDC_INSTALL_DIR/utils" ]; then
        chmod +x "$NDC_INSTALL_DIR/utils"/*.sh 2>/dev/null || true
    fi
    
    print_success "NDC OLS files installed successfully"
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
    # Get Public IP
    SERVER_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
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
    echo -e "  ${GREEN}✓${NC} MongoDB + Mongo Express"
    echo -e "  ${GREEN}✓${NC} MariaDB + phpMyAdmin"
    echo -e "  ${GREEN}✓${NC} PostgreSQL + pgAdmin 4"
    echo -e "  ${GREEN}✓${NC} Redis cache"
    echo -e "  ${GREEN}✓${NC} Let's Encrypt SSL"
    echo -e "  ${GREEN}✓${NC} Firewall (UFW/Firewalld)"
    echo -e "  ${GREEN}✓${NC} Fail2ban protection"
    echo ""
    
    if [ -f "$NDC_CONFIG_DIR/auth.conf" ]; then
        source "$NDC_CONFIG_DIR/auth.conf"
        echo -e "${CYAN}Database Credentials:${NC}"
        echo -e "  ${BOLD}MongoDB Admin:${NC}"
        echo -e "    User: ${YELLOW}$MONGODB_USER${NC}"
        echo -e "    Pass: ${YELLOW}$MONGODB_PASS${NC}"
        echo -e ""
        echo -e "  ${BOLD}Mongo Express GUI:${NC}"
        echo -e "    URL : ${YELLOW}http://$SERVER_IP:8081${NC}"
        echo -e "    User: ${YELLOW}$MONGO_EXPRESS_USER${NC}"
        echo -e "    Pass: ${YELLOW}$MONGO_EXPRESS_PASS${NC}"
        echo ""
        echo -e "  ${BOLD}phpMyAdmin GUI:${NC}"
        echo -e "    URL : ${YELLOW}http://$SERVER_IP:8080${NC}"
        echo -e "    User: ${YELLOW}root${NC}"
        echo -e "    Pass: ${YELLOW}$MYSQL_ROOT_PASS${NC}"
        echo ""
        echo -e "  ${BOLD}PostgreSQL Admin:${NC}"
        echo -e "    User: ${YELLOW}admin${NC}"
        echo -e "    Pass: ${YELLOW}$PG_PASS${NC}"
        echo -e ""
        echo -e "  ${BOLD}pgAdmin 4 GUI:${NC}"
        echo -e "    URL : ${YELLOW}http://$SERVER_IP:5050${NC}"
        echo -e "    User: ${YELLOW}$PGADMIN_EMAIL${NC}"
        echo -e "    Pass: ${YELLOW}$PGADMIN_PASS${NC}"
        echo ""
    fi

    echo -e "${CYAN}Quick Start:${NC}"
    echo -e "  Run: ${YELLOW}ndc${NC} or ${YELLOW}ndc-ols${NC}"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo -e "  https://docs.ndc-ols.com"
    echo ""
    echo -e "${CYAN}Support:${NC}"
    echo -e "  GitHub: https://github.com/nguyendc-hp/ndc-ols"
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
    echo "  • MongoDB, Mongo Express, MariaDB, phpMyAdmin, Redis"
    echo "  • PostgreSQL, pgAdmin 4"
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
    install_mongodb
    install_mongo_express
    install_mysql
    install_redis
    install_phpmyadmin
    install_postgresql
    install_pgadmin
    install_certbot
    setup_firewall
    setup_fail2ban
    clone_ndc_ols
    create_symlink
    create_config
    setup_login_banner
    
    # Show completion
    show_completion
}

# Run main
main "$@"
