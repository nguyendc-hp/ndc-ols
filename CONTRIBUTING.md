# Contributing to NDC OLS

Thank you for your interest in contributing to NDC OLS!

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Use the bug report template
3. Include:
   - OS version
   - NDC OLS version
   - Steps to reproduce
   - Expected vs actual behavior
   - Error logs

### Suggesting Features

1. Check existing feature requests
2. Explain the use case
3. Describe the proposed solution
4. Provide examples if possible

### Code Contributions

#### Setup Development Environment

```bash
# Fork and clone
git clone https://github.com/yourusername/ndc-ols.git
cd ndc-ols

# Create feature branch
git checkout -b feature/your-feature-name
```

#### Coding Standards

**Bash Scripts:**
- Use 4 spaces for indentation
- Add comments for complex logic
- Use descriptive variable names
- Follow existing code style
- Test on Ubuntu and AlmaLinux

**Example:**
```bash
#!/bin/bash

# Good variable names
app_name="myapp"
domain_name="example.com"

# Use functions
function install_package() {
    local package_name="$1"
    
    if command_exists "$package_name"; then
        print_success "Package $package_name already installed"
        return 0
    fi
    
    print_info "Installing $package_name..."
    # Installation logic
}

# Error handling
if ! install_package "nginx"; then
    print_error "Failed to install Nginx"
    return 1
fi
```

#### Testing

Before submitting:

```bash
# Test installation
bash install.sh

# Test main menu
./ndc-ols.sh

# Test specific modules
bash modules/app-manager.sh

# Check for syntax errors
bash -n ndc-ols.sh
bash -n modules/*.sh
```

#### Pull Request Process

1. **Update documentation** if needed
2. **Test thoroughly** on multiple OS versions
3. **Update CHANGELOG.md**
4. **Create pull request** with:
   - Clear description
   - Related issue number
   - Screenshots/logs if relevant

#### PR Template

```markdown
## Description
Brief description of changes

## Related Issue
Fixes #123

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Ubuntu 22.04
- [ ] Tested on Ubuntu 24.04
- [ ] Tested on AlmaLinux 8/9
- [ ] All existing tests pass

## Screenshots (if applicable)
[Add screenshots]

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] CHANGELOG.md updated
```

### Documentation Contributions

Help improve documentation:

- Fix typos/grammar
- Add examples
- Clarify confusing sections
- Translate to other languages

## Development Workflow

### 1. Pick an Issue

- Look for `good first issue` or `help wanted` labels
- Comment on the issue to claim it

### 2. Make Changes

- Follow coding standards
- Keep commits focused
- Write clear commit messages

### 3. Test Locally

```bash
# Test on clean VPS
vagrant up ubuntu22  # or use DigitalOcean/Vultr
vagrant ssh ubuntu22
# Upload and test your changes
```

### 4. Submit PR

- Push to your fork
- Create pull request
- Wait for review

## Project Structure

```
ndc-ols/
├── install.sh              # Main installer
├── ndc-ols.sh              # Main menu script
├── utils/                  # Utility functions
│   ├── colors.sh
│   ├── helpers.sh
│   └── validators.sh
├── modules/                # Feature modules
│   ├── app-manager.sh
│   ├── domain-manager.sh
│   └── ...
├── templates/              # Config templates
│   ├── nginx/
│   ├── pm2/
│   └── env/
├── config/                 # Configuration files
└── docs/                   # Documentation
```

## Adding a New Module

1. **Create module file:**

```bash
touch modules/mymodule-manager.sh
```

2. **Use template:**

```bash
#!/bin/bash

# Source utilities
source "$NDC_INSTALL_DIR/utils/colors.sh"
source "$NDC_INSTALL_DIR/utils/helpers.sh"

# Module functions
function show_mymodule_menu() {
    clear
    print_header "My Module Manager"
    
    echo "1) Option 1"
    echo "2) Option 2"
    echo "0) Back"
    
    read -p "Select option: " choice
    
    case $choice in
        1) option1 ;;
        2) option2 ;;
        0) return ;;
        *) print_error "Invalid option" ;;
    esac
}

# Main
show_mymodule_menu
```

3. **Add to main menu** in `ndc-ols.sh`:

```bash
case $choice in
    # ... existing cases ...
    31) bash "$MODULES_DIR/mymodule-manager.sh" ;;
esac
```

4. **Test thoroughly**

5. **Update documentation**

## Community Guidelines

- Be respectful and inclusive
- Help others learn
- Give constructive feedback
- Credit original authors

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

- Discord: https://discord.gg/ndc-ols
- GitHub Discussions: https://github.com/ndc-ols/discussions
- Email: dev@ndc-ols.com

Thank you for contributing! 🎉
