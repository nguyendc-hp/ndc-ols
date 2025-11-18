#!/bin/bash
#######################################
# NDC OLS - Validators
# Input validation functions
#######################################

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

#######################################
# Domain validation
#######################################

validate_domain_format() {
    local domain="$1"
    
    # Check if empty
    if [ -z "$domain" ]; then
        print_error "Domain cannot be empty"
        return 1
    fi
    
    # Check length
    if [ ${#domain} -gt 253 ]; then
        print_error "Domain too long (max 253 characters)"
        return 1
    fi
    
    # Check format
    if ! [[ $domain =~ ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid domain format: $domain"
        return 1
    fi
    
    return 0
}

# Check if domain already exists
domain_exists() {
    local domain="$1"
    local apps_dir="${NDC_APPS_DIR:-/var/www}"
    
    if [ -d "$apps_dir/$domain" ]; then
        return 0
    fi
    return 1
}

# Validate and check domain availability
validate_and_check_domain() {
    local domain="$1"
    
    if ! validate_domain_format "$domain"; then
        return 1
    fi
    
    if domain_exists "$domain"; then
        print_error "Domain already exists: $domain"
        return 1
    fi
    
    return 0
}

#######################################
# Port validation
#######################################

validate_port_format() {
    local port="$1"
    
    # Check if empty
    if [ -z "$port" ]; then
        print_error "Port cannot be empty"
        return 1
    fi
    
    # Check if numeric
    if ! [[ $port =~ ^[0-9]+$ ]]; then
        print_error "Port must be numeric"
        return 1
    fi
    
    # Check range
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        print_error "Port must be between 1 and 65535"
        return 1
    fi
    
    # Check reserved ports (requires root)
    if [ "$port" -lt 1024 ] && [[ $EUID -ne 0 ]]; then
        print_error "Ports below 1024 require root privileges"
        return 1
    fi
    
    return 0
}

# Check if port is available
port_available() {
    local port="$1"
    
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 1
    fi
    
    if ss -tuln 2>/dev/null | grep -q ":$port "; then
        return 1
    fi
    
    return 0
}

# Validate and check port availability
validate_and_check_port() {
    local port="$1"
    
    if ! validate_port_format "$port"; then
        return 1
    fi
    
    if ! port_available "$port"; then
        print_error "Port $port is already in use"
        return 1
    fi
    
    return 0
}

#######################################
# Email validation
#######################################

validate_email_format() {
    local email="$1"
    
    # Check if empty
    if [ -z "$email" ]; then
        print_error "Email cannot be empty"
        return 1
    fi
    
    # Check format
    if ! [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid email format: $email"
        return 1
    fi
    
    return 0
}

#######################################
# URL validation
#######################################

validate_url_format() {
    local url="$1"
    
    # Check if empty
    if [ -z "$url" ]; then
        print_error "URL cannot be empty"
        return 1
    fi
    
    # Check format (http or https)
    if ! [[ $url =~ ^https?:// ]]; then
        print_error "URL must start with http:// or https://"
        return 1
    fi
    
    return 0
}

# Validate Git repository URL
validate_git_url() {
    local url="$1"
    
    # Check if empty
    if [ -z "$url" ]; then
        print_error "Git URL cannot be empty"
        return 1
    fi
    
    # Check format (git, http, https, ssh)
    if ! [[ $url =~ ^(https?|git|ssh):// ]] && ! [[ $url =~ ^git@ ]]; then
        print_error "Invalid Git URL format"
        return 1
    fi
    
    # Try to check if repository exists (optional, requires internet)
    if command_exists git; then
        if ! git ls-remote "$url" >/dev/null 2>&1; then
            print_warning "Cannot access Git repository: $url"
            ask_yes_no "Continue anyway?" "n" || return 1
        fi
    fi
    
    return 0
}

#######################################
# Path validation
#######################################

validate_path() {
    local path="$1"
    local must_exist="${2:-false}"
    
    # Check if empty
    if [ -z "$path" ]; then
        print_error "Path cannot be empty"
        return 1
    fi
    
    # Check if must exist
    if [ "$must_exist" = true ]; then
        if [ ! -e "$path" ]; then
            print_error "Path does not exist: $path"
            return 1
        fi
    fi
    
    # Check if absolute path
    if ! [[ "$path" = /* ]]; then
        print_warning "Path is not absolute: $path"
    fi
    
    return 0
}

# Validate directory path
validate_directory() {
    local dir="$1"
    local must_exist="${2:-false}"
    
    if ! validate_path "$dir" "$must_exist"; then
        return 1
    fi
    
    if [ "$must_exist" = true ]; then
        if [ ! -d "$dir" ]; then
            print_error "Not a directory: $dir"
            return 1
        fi
    fi
    
    return 0
}

# Validate file path
validate_file() {
    local file="$1"
    local must_exist="${2:-false}"
    
    if ! validate_path "$file" "$must_exist"; then
        return 1
    fi
    
    if [ "$must_exist" = true ]; then
        if [ ! -f "$file" ]; then
            print_error "Not a file: $file"
            return 1
        fi
    fi
    
    return 0
}

#######################################
# App name validation
#######################################

validate_app_name() {
    local app_name="$1"
    
    # Check if empty
    if [ -z "$app_name" ]; then
        print_error "App name cannot be empty"
        return 1
    fi
    
    # Check length
    if [ ${#app_name} -lt 2 ]; then
        print_error "App name too short (min 2 characters)"
        return 1
    fi
    
    if [ ${#app_name} -gt 50 ]; then
        print_error "App name too long (max 50 characters)"
        return 1
    fi
    
    # Check format (alphanumeric, dash, underscore)
    if ! [[ $app_name =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "App name can only contain: a-z, A-Z, 0-9, -, _"
        return 1
    fi
    
    # Cannot start with dash or underscore
    if [[ $app_name =~ ^[-_] ]]; then
        print_error "App name cannot start with dash or underscore"
        return 1
    fi
    
    return 0
}

#######################################
# Database name validation
#######################################

validate_database_name() {
    local db_name="$1"
    local db_type="${2:-postgresql}"
    
    # Check if empty
    if [ -z "$db_name" ]; then
        print_error "Database name cannot be empty"
        return 1
    fi
    
    # Check length
    if [ ${#db_name} -lt 2 ]; then
        print_error "Database name too short (min 2 characters)"
        return 1
    fi
    
    case "$db_type" in
        postgresql)
            # PostgreSQL: max 63 chars, lowercase, alphanumeric + underscore
            if [ ${#db_name} -gt 63 ]; then
                print_error "Database name too long (max 63 characters for PostgreSQL)"
                return 1
            fi
            if ! [[ $db_name =~ ^[a-z_][a-z0-9_]*$ ]]; then
                print_error "PostgreSQL database name: lowercase letters, numbers, underscores only"
                return 1
            fi
            ;;
        mysql|mariadb)
            # MySQL/MariaDB: max 64 chars
            if [ ${#db_name} -gt 64 ]; then
                print_error "Database name too long (max 64 characters for MySQL/MariaDB)"
                return 1
            fi
            if ! [[ $db_name =~ ^[a-zA-Z0-9_]+$ ]]; then
                print_error "MySQL database name: letters, numbers, underscores only"
                return 1
            fi
            ;;
        mongodb)
            # MongoDB: more flexible
            if [ ${#db_name} -gt 64 ]; then
                print_error "Database name too long (max 64 characters for MongoDB)"
                return 1
            fi
            if ! [[ $db_name =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_error "MongoDB database name: letters, numbers, underscores, dashes only"
                return 1
            fi
            ;;
    esac
    
    return 0
}

#######################################
# Username validation
#######################################

validate_username() {
    local username="$1"
    
    # Check if empty
    if [ -z "$username" ]; then
        print_error "Username cannot be empty"
        return 1
    fi
    
    # Check length
    if [ ${#username} -lt 3 ]; then
        print_error "Username too short (min 3 characters)"
        return 1
    fi
    
    if [ ${#username} -gt 32 ]; then
        print_error "Username too long (max 32 characters)"
        return 1
    fi
    
    # Check format
    if ! [[ $username =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        print_error "Username must start with letter or underscore, contain only lowercase letters, numbers, dash, underscore"
        return 1
    fi
    
    return 0
}

#######################################
# Password validation
#######################################

validate_password() {
    local password="$1"
    local min_length="${2:-8}"
    
    # Check if empty
    if [ -z "$password" ]; then
        print_error "Password cannot be empty"
        return 1
    fi
    
    # Check length
    if [ ${#password} -lt $min_length ]; then
        print_error "Password too short (min $min_length characters)"
        return 1
    fi
    
    # Check strength (optional)
    local has_upper=0
    local has_lower=0
    local has_digit=0
    local has_special=0
    
    [[ $password =~ [A-Z] ]] && has_upper=1
    [[ $password =~ [a-z] ]] && has_lower=1
    [[ $password =~ [0-9] ]] && has_digit=1
    [[ $password =~ [^a-zA-Z0-9] ]] && has_special=1
    
    local strength=$((has_upper + has_lower + has_digit + has_special))
    
    if [ $strength -lt 3 ]; then
        print_warning "Weak password! Should contain: uppercase, lowercase, numbers, special characters"
        ask_yes_no "Use this password anyway?" "n" || return 1
    fi
    
    return 0
}

#######################################
# Node.js version validation
#######################################

validate_node_version() {
    local version="$1"
    
    # Check if empty
    if [ -z "$version" ]; then
        print_error "Node.js version cannot be empty"
        return 1
    fi
    
    # Check format (e.g., 18, 18.17, 18.17.0, v18.17.0, lts/hydrogen)
    if ! [[ $version =~ ^(v?[0-9]+|v?[0-9]+\.[0-9]+|v?[0-9]+\.[0-9]+\.[0-9]+|lts/[a-z]+)$ ]]; then
        print_error "Invalid Node.js version format: $version"
        print_info "Valid formats: 18, 18.17, 18.17.0, v18.17.0, lts/hydrogen"
        return 1
    fi
    
    return 0
}

#######################################
# IP address validation
#######################################

validate_ipv4() {
    local ip="$1"
    
    # Check if empty
    if [ -z "$ip" ]; then
        print_error "IP address cannot be empty"
        return 1
    fi
    
    # Check format
    if ! [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_error "Invalid IPv4 format: $ip"
        return 1
    fi
    
    # Check octets
    IFS='.' read -r -a octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [ "$octet" -gt 255 ]; then
            print_error "Invalid IPv4 address: $ip"
            return 1
        fi
    done
    
    return 0
}

#######################################
# Number validation
#######################################

validate_number() {
    local num="$1"
    local min="${2:-}"
    local max="${3:-}"
    
    # Check if empty
    if [ -z "$num" ]; then
        print_error "Number cannot be empty"
        return 1
    fi
    
    # Check if numeric
    if ! [[ $num =~ ^[0-9]+$ ]]; then
        print_error "Not a valid number: $num"
        return 1
    fi
    
    # Check min
    if [ -n "$min" ] && [ "$num" -lt "$min" ]; then
        print_error "Number too small (min: $min)"
        return 1
    fi
    
    # Check max
    if [ -n "$max" ] && [ "$num" -gt "$max" ]; then
        print_error "Number too large (max: $max)"
        return 1
    fi
    
    return 0
}

#######################################
# Export all functions
#######################################

export -f validate_domain_format domain_exists validate_and_check_domain
export -f validate_port_format port_available validate_and_check_port
export -f validate_email_format validate_url_format validate_git_url
export -f validate_path validate_directory validate_file
export -f validate_app_name validate_database_name
export -f validate_username validate_password
export -f validate_node_version validate_ipv4 validate_number
