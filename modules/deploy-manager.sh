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
    echo ""
    
    read -p "$(echo -e "${CYAN}Enter choice:${NC} ")" choice
    
    case $choice in
        1|2|3|4|5|6|7|8) deploy_from_template "$choice" ;;
        9) deploy_from_git ;;
        *) print_error "Invalid"; return ;;
    esac
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
