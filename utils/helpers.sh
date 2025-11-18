#!/bin/bash
#######################################
# NDC OLS - Helper Functions
# Các hàm tiện ích dùng chung
#######################################

# Source colors
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh" 2>/dev/null || source /usr/local/ndc-ols/utils/colors.sh

#######################################
# Print functions
#######################################

# Print info message
print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Print success message
print_success() {
    echo -e "${GREEN}[${CHECKMARK}]${NC} ${GREEN}$1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}[${CROSSMARK}]${NC} ${RED}$1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}[!]${NC} ${YELLOW}$1${NC}"
}

# Print step
print_step() {
    echo -e "${BLUE}[${ARROW}]${NC} ${BOLD}$1${NC}"
}

# Print separator
print_separator() {
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
}

# Print header
print_header() {
    clear
    print_separator
    echo -e "${BCYAN}$1${NC}"
    print_separator
    echo ""
}

#######################################
# Confirmation functions
#######################################

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        local prompt="[Y/n]"
        local default_answer="y"
    else
        local prompt="[y/N]"
        local default_answer="n"
    fi
    
    while true; do
        read -p "$(echo -e "${YELLOW}?${NC} $question $prompt: ")" answer
        answer=${answer:-$default_answer}
        
        case ${answer,,} in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) print_error "Please answer yes or no." ;;
        esac
    done
}

# Confirm action
confirm_action() {
    local message="$1"
    echo ""
    echo -e "${YELLOW}⚠${NC}  ${BOLD}$message${NC}"
    ask_yes_no "Are you sure you want to continue?" "n"
}

#######################################
# Input functions
#######################################

# Read input with default value
read_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        read -p "$(echo -e "${CYAN}?${NC} $prompt ${IBLACK}[$default]${NC}: ")" input
        input=${input:-$default}
    else
        read -p "$(echo -e "${CYAN}?${NC} $prompt: ")" input
    fi
    
    if [ -n "$var_name" ]; then
        eval "$var_name='$input'"
    else
        echo "$input"
    fi
}

# Read password
read_password() {
    local prompt="$1"
    local var_name="$2"
    
    read -s -p "$(echo -e "${CYAN}?${NC} $prompt: ")" password
    echo ""
    
    if [ -n "$var_name" ]; then
        eval "$var_name='$password'"
    else
        echo "$password"
    fi
}

#######################################
# Loading/Progress functions
#######################################

# Show spinner
show_spinner() {
    local pid=$1
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        echo -ne "\r${CYAN}${spin:$i:1}${NC} $message..."
        sleep .1
    done
    echo -ne "\r"
}

# Progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    echo -ne "\r${CYAN}["
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' ' '
    echo -ne "]${NC} ${percentage}%"
}

#######################################
# System check functions
#######################################

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        print_info "Please run: sudo $0"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if service is running
service_running() {
    systemctl is-active --quiet "$1"
}

# Check if port is in use
port_in_use() {
    local port=$1
    netstat -tuln | grep -q ":$port "
}

# Get OS type
get_os_type() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "centos"
    else
        echo "unknown"
    fi
}

# Get OS version
get_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

# Check OS compatibility
check_os_compatibility() {
    local os=$(get_os_type)
    local version=$(get_os_version)
    
    case "$os" in
        ubuntu)
            if [[ "$version" == "22.04" ]] || [[ "$version" == "24.04" ]]; then
                return 0
            fi
            ;;
        almalinux|rocky)
            if [[ "$version" == "8"* ]] || [[ "$version" == "9"* ]]; then
                return 0
            fi
            ;;
    esac
    
    print_error "Unsupported OS: $os $version"
    print_info "Supported: Ubuntu 22.04/24.04, AlmaLinux 8/9, Rocky Linux 8/9"
    return 1
}

#######################################
# File/Directory functions
#######################################

# Create directory if not exists
create_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "Created directory: $dir"
    fi
}

# Backup file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        print_success "Backed up: $file → $backup"
    fi
}

# Check if file exists and readable
check_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi
    if [ ! -r "$file" ]; then
        print_error "File not readable: $file"
        return 1
    fi
    return 0
}

#######################################
# Network functions
#######################################

# Get public IP
get_public_ip() {
    curl -s https://api.ipify.org 2>/dev/null || \
    curl -s https://ifconfig.me 2>/dev/null || \
    echo "N/A"
}

# Check internet connection
check_internet() {
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_error "No internet connection!"
        return 1
    fi
    return 0
}

# Validate domain
validate_domain() {
    local domain="$1"
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate email
validate_email() {
    local email="$1"
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate port
validate_port() {
    local port="$1"
    if [[ $port =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

#######################################
# String functions
#######################################

# Generate random string
generate_random_string() {
    local length="${1:-16}"
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}

# Generate random password
generate_password() {
    local length="${1:-20}"
    tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$length"
}

# Convert to lowercase
to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert to uppercase
to_uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Trim whitespace
trim() {
    local var="$1"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

#######################################
# Log functions
#######################################

# Log to file
log() {
    local level="$1"
    shift
    local message="$@"
    local log_file="${NDC_LOG_FILE:-/var/log/ndc-ols.log}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$log_file"
}

# Log info
log_info() {
    log "INFO" "$@"
    print_info "$@"
}

# Log success
log_success() {
    log "SUCCESS" "$@"
    print_success "$@"
}

# Log error
log_error() {
    log "ERROR" "$@"
    print_error "$@"
}

# Log warning
log_warning() {
    log "WARNING" "$@"
    print_warning "$@"
}

#######################################
# Time functions
#######################################

# Get timestamp
get_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# Get formatted date
get_date() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Calculate duration
calculate_duration() {
    local start=$1
    local end=$2
    local duration=$((end - start))
    
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))
    
    printf "%02d:%02d:%02d" $hours $minutes $seconds
}

#######################################
# System info functions
#######################################

# Get CPU cores
get_cpu_cores() {
    nproc
}

# Get total RAM in GB
get_total_ram() {
    free -g | awk '/^Mem:/{print $2}'
}

# Get free disk space in GB
get_free_disk() {
    df -BG / | awk 'NR==2 {print $4}' | sed 's/G//'
}

# Get system uptime
get_uptime() {
    uptime -p
}

#######################################
# Press any key to continue
#######################################

press_any_key() {
    echo ""
    read -n 1 -s -r -p "$(echo -e "${IBLACK}Press any key to continue...${NC}")"
    echo ""
}

# Pause with countdown
pause_with_countdown() {
    local seconds="${1:-5}"
    local message="${2:-Continuing in}"
    
    for ((i=$seconds; i>0; i--)); do
        echo -ne "\r${IBLACK}$message $i seconds...${NC}"
        sleep 1
    done
    echo -ne "\r\033[K"
}

#######################################
# Export all functions
#######################################

export -f print_info print_success print_error print_warning print_step
export -f print_separator print_header
export -f ask_yes_no confirm_action
export -f read_input read_password
export -f show_spinner progress_bar
export -f check_root command_exists service_running port_in_use
export -f get_os_type get_os_version check_os_compatibility
export -f create_dir backup_file check_file
export -f get_public_ip check_internet validate_domain validate_email validate_port
export -f generate_random_string generate_password to_lowercase to_uppercase trim
export -f log log_info log_success log_error log_warning
export -f get_timestamp get_date calculate_duration
export -f get_cpu_cores get_total_ram get_free_disk get_uptime
export -f press_any_key pause_with_countdown
