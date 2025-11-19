#!/bin/bash
# Module: Deploy Manager - Deploy apps from Git
source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

deploy_manager_menu() {
    print_header "DEPLOY NEW APP"
    
    echo "Select template:"
    echo "  1) React (Vite)"
    echo "  2) React (Create React App)"
    echo "  3) Next.js"
    echo "  4) Express.js API"
    echo "  5) NestJS"
    echo "  6) Vue.js"
    echo "  7) Nuxt.js"
    echo "  8) Static HTML"
    echo "  9) Custom (from Git)"
    echo "  10) Full Stack (Node + React Monorepo)"
    echo ""
    
    read -p "$(echo -e "${CYAN}Enter choice:${NC} ")" choice
    
    case $choice in
        1|2|3|4|5|6|7|8) deploy_from_template "$choice" ;;
        9) deploy_from_git ;;
        10) deploy_full_stack ;;
        *) print_error "Invalid"; return ;;
    esac
}

deploy_full_stack() {
    print_header "DEPLOY FULL STACK APP (MERN/PERN)"
    
    read_input "Git repository URL" "" git_url
    read_input "App name" "" app_name
    read_input "Domain" "" domain
    read_input "Backend Port" "8080" backend_port
    
    local app_root="/var/www/$app_name"
    
    # 1. Clone Repository
    print_step "Cloning repository..."
    if [ -d "$app_root" ]; then
        print_warning "Directory exists. Pulling latest changes..."
        cd "$app_root"
        git pull
    else
        git clone "$git_url" "$app_root"
    fi
    
    cd "$app_root" || return
    
    # 2. Detect Structure
    local backend_dir="backend"
    local frontend_dir="frontend"
    
    if [ ! -d "backend" ]; then
        read_input "Backend directory name" "." backend_dir
    fi
    
    if [ ! -d "frontend" ]; then
        read_input "Frontend directory name" "." frontend_dir
    fi
    
    # 3. Setup Backend
    print_step "Setting up Backend..."
    cd "$app_root/$backend_dir" || return
    
    # Handle .env
    if [ -f ".env.example" ] && [ ! -f ".env" ]; then
        cp .env.example .env
        print_info "Created .env from .env.example"
        print_info "Please configure .env variables:"
        nano .env
    fi
    
    print_info "Installing backend dependencies..."
    npm install
    
    print_info "Starting backend with PM2..."
    pm2 start npm --name "${app_name}-backend" -- start
    pm2 save
    
    # 4. Setup Frontend
    print_step "Setting up Frontend..."
    cd "$app_root/$frontend_dir" || return
    
    # Handle .env for Frontend
    if [ -f ".env.example" ] && [ ! -f ".env" ]; then
        cp .env.example .env
    fi
    
    # Auto-configure VITE_API_BASE_URL if possible
    if [ -f ".env" ]; then
        if grep -q "VITE_API_BASE_URL" .env; then
            sed -i "s|VITE_API_BASE_URL=.*|VITE_API_BASE_URL=https://$domain/api|g" .env
        fi
    else
        echo "VITE_API_BASE_URL=https://$domain/api" > .env
    fi
    
    print_info "Installing frontend dependencies..."
    npm install
    
    print_info "Building frontend..."
    npm run build
    
    local build_dir="dist"
    if [ ! -d "dist" ] && [ -d "build" ]; then
        build_dir="build"
    fi
    
    # 5. Configure Nginx
    print_step "Configuring Nginx..."
    
    if [ -f "/etc/nginx/sites-available/$domain" ]; then
        print_warning "Existing config for $domain found. It will be overwritten."
        print_warning "You will need to reinstall SSL after this step."
    fi
    
    cat > "/etc/nginx/sites-available/$domain" <<EOF
server {
    listen 80;
    server_name $domain www.$domain;

    root $app_root/$frontend_dir/$build_dir;
    index index.html;

    # Frontend
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API Proxy
    location /api/ {
        proxy_pass http://localhost:$backend_port/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/"
    nginx -t && systemctl reload nginx
    
    # 6. SSL Setup
    if ask_yes_no "Install SSL (HTTPS) now?" "y"; then
        certbot --nginx -d "$domain" --non-interactive --agree-tos --email "admin@$domain" --redirect
    fi
    
    print_success "Full Stack App Deployed Successfully!"
    print_info "Frontend: https://$domain"
    print_info "Backend: https://$domain/api"
    press_any_key
}

deploy_from_git() {
    read_input "Git repository URL" "" git_url
    read_input "App name" "" app_name
    read_input "Domain (optional)" "" domain
    read_input "Port (for Node apps)" "3000" port
    
    local app_dir="/var/www/$app_name"
    
    print_step "Cloning repository..."
    git clone "$git_url" "$app_dir"
    
    cd "$app_dir" || return
    
    if [ -f "package.json" ]; then
        print_step "Installing dependencies..."
        npm install
        
        if ask_yes_no "Build project?" "y"; then
            npm run build
        fi
        
        if ask_yes_no "Add to PM2?" "y"; then
            pm2 start npm --name "$app_name" -- start
            pm2 save
        fi
    fi
    
    if [ -n "$domain" ]; then
        print_step "Creating Nginx config..."
        # Use domain-manager functions
        source "$NDC_INSTALL_DIR/modules/domain-manager.sh"
        add_nodejs_domain "$domain" "$port"
    fi
    
    print_success "App deployed: $app_name"
    press_any_key
}

deploy_from_template() {
    local template=$1
    read_input "App name" "" app_name
    read_input "Domain" "" domain
    
    case $template in
        1) deploy_react_vite "$app_name" "$domain" ;;
        2) deploy_react_cra "$app_name" "$domain" ;;
        3) deploy_nextjs "$app_name" "$domain" ;;
        4) deploy_express "$app_name" "$domain" ;;
    esac
}

deploy_react_vite() {
    local app_name=$1
    local domain=$2
    local app_dir="/var/www/$app_name"
    
    print_step "Creating React (Vite) app..."
    npm create vite@latest "$app_dir" -- --template react
    cd "$app_dir"
    npm install
    npm run build
    
    # Setup nginx for static site
    source "$NDC_INSTALL_DIR/modules/domain-manager.sh"
    add_react_domain "$domain"
    
    print_success "React app deployed!"
    press_any_key
}

deploy_express() {
    local app_name=$1
    local domain=$2
    local app_dir="/var/www/$app_name"
    
    mkdir -p "$app_dir"
    cd "$app_dir"
    
    npm init -y
    npm install express
    
    cat > index.js <<'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({ message: 'Hello from Express!' });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
EOF
    
    pm2 start index.js --name "$app_name"
    pm2 save
    
    source "$NDC_INSTALL_DIR/modules/domain-manager.sh"
    add_nodejs_domain "$domain" "3000"
    
    print_success "Express API deployed!"
    press_any_key
}
