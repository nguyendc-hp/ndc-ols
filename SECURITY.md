# Security Policy

## Supported Versions

Currently supported versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in NDC OLS, please report it to us privately.

### How to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please email:
- **Email:** security@ndc-ols.com
- **Subject:** Security Vulnerability Report

### What to Include

1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Potential impact** (what could an attacker do?)
4. **Suggested fix** (if you have one)
5. **Your contact information**

### Response Timeline

- **24 hours:** Acknowledgment of your report
- **48 hours:** Initial assessment
- **7 days:** Status update and plan
- **30 days:** Fix released (for critical issues)

### Disclosure Policy

- We ask that you give us reasonable time to fix the issue before public disclosure
- We will credit you in the security advisory (unless you prefer to remain anonymous)
- We will keep you updated on the progress

## Security Best Practices

When using NDC OLS:

### 1. Server Security

```bash
# Change default SSH port
ndc → 9) SSH Management → 1) Change SSH port

# Setup SSH key authentication
ndc → 9) SSH Management → 2) Setup SSH key

# Disable password login
ndc → 9) SSH Management → 4) Disable password authentication

# Enable firewall
ndc → 8) Firewall Management
```

### 2. Database Security

```bash
# Use strong passwords
- Minimum 16 characters
- Mix of letters, numbers, symbols

# Restrict access
- Bind to localhost only
- Use firewall rules
- Regular backups
```

### 3. Application Security

```bash
# Use environment variables for secrets
# Never commit .env files
# Keep dependencies updated
npm audit
npm audit fix

# Use SSL for all domains
ndc → 3) SSL Management
```

### 4. System Security

```bash
# Keep system updated
ndc → 10) Update System

# Monitor logs regularly
ndc → 15) Logs Management

# Setup Fail2ban
# Automatically blocks brute-force attempts
```

### 5. Backup Security

```bash
# Regular backups
ndc → 5) Backup & Restore → 5) Auto-backup

# Encrypt backups
# Use GPG encryption for sensitive data

# Off-site storage
ndc → 5) Backup & Restore → 6) Cloud backup
```

## Known Security Considerations

### 1. Root Access

NDC OLS requires root access for:
- Installing system packages
- Configuring Nginx/databases
- Managing system services

**Mitigation:** Review all scripts before running. Code is open-source and auditable.

### 2. Database Credentials

Credentials are stored in:
- `/root/.ndc-ols/credentials.conf`

**Mitigation:** 
- File has 600 permissions (root only)
- Use strong passwords
- Rotate credentials regularly

### 3. SSL Certificates

Let's Encrypt certificates are automatically renewed.

**Mitigation:**
- Monitor expiration dates
- Setup email notifications
- Backup certificates

### 4. PM2 Process Manager

Apps run as root by default.

**Mitigation:**
- Create separate user for apps (planned feature)
- Use process isolation
- Monitor resource usage

## Security Updates

Subscribe to security updates:

- **GitHub:** Watch this repository for security advisories
- **Email:** security-updates@ndc-ols.com
- **RSS:** https://ndc-ols.com/security.rss

## Security Audit

Last security audit: Pending
Next scheduled audit: Q2 2024

Interested in performing a security audit? Contact security@ndc-ols.com

## Third-Party Dependencies

NDC OLS uses the following third-party software:

- Nginx (Latest stable)
- Node.js (LTS versions)
- PM2 (Latest)
- PostgreSQL (15/14)
- MongoDB (7.0/6.0)
- MariaDB (10.11)
- Redis (Latest)
- Certbot (Latest)
- Fail2ban (Latest)

All dependencies are from official repositories and are kept up-to-date.

## Bug Bounty Program

Currently: No formal bug bounty program

We appreciate security researchers and will:
- Credit you in our security advisory
- Acknowledge your contribution
- Potentially offer rewards for critical vulnerabilities (decided case-by-case)

## Contact

- **Security Email:** security@ndc-ols.com
- **GPG Key:** [Available on request]
- **Response Time:** Within 24 hours

Thank you for helping keep NDC OLS secure! 🔒
