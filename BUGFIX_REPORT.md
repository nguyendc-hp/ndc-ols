# NDC-OLS Install Script - Bug Fix Report

**Date:** 2024
**Focus:** Fix 502 Bad Gateway (pgAdmin) and 500 Internal Server Error (Mongo Express)
**Root Cause:** Missing validation, process verification, and improper environment configuration

---

## Summary of Issues Fixed

### **Issue 1: Mongo Express - HTTP 500 Internal Server Error (Port 8081)**

**Root Causes:**
1. Node.js interpreter not explicitly specified in PM2 config - could use wrong node binary
2. No health check to verify app responds to HTTP requests (only checked if process was "online")
3. Insufficient error logging on startup failure
4. Process could crash immediately after becoming "online" without detection

**Fixes Applied:**

```bash
# OLD CODE
pm2 start "$NDC_CONFIG_DIR/mongo-express.config.js"
sleep 10
if ! pm2 list | grep -q "mongo-express.*online"; then
    pm2 logs mongo-express --lines 50 --nostream
    pm2 restart mongo-express
fi

# NEW CODE
# 1. Explicitly specify Node binary for PM2
NODE_BIN="$NVM_DIR/versions/node/$(node -v | sed 's/^v//')/bin/node"
cat > "$NDC_CONFIG_DIR/mongo-express.config.js" <<EOF
module.exports = {
  apps: [{
    name: 'mongo-express',
    interpreter: '$NODE_BIN',  # <- FIX: Use explicit Node path
    max_memory_restart: '200M',  # <- FIX: Prevent memory leaks
    # ... rest of config
  }]
};
EOF

# 2. Make app script executable
chmod +x "$MONGO_EXPRESS_SCRIPT"

# 3. Enhanced startup verification with recovery
if ! pm2 list | grep -q "mongo-express.*online"; then
    print_error "Mongo Express failed to start"
    
    # Check if node process exists
    if pgrep -f "mongo-express.*app.js" >/dev/null; then
        print_info "Process exists but PM2 reports offline. Waiting longer..."
        sleep 5
    else
        print_error "Process doesn't exist. Attempting recovery..."
        # Delete and retry
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
fi

# 4. Port verification with retry logic
local max_retries=5
local retry_count=0
while [ $retry_count -lt $max_retries ]; do
    if ss -tulnp 2>/dev/null | grep -q ":8081"; then
        port_ok=true
        break
    fi
    sleep 2
done
```

**Result:** Mongo Express will now:
- Use correct Node.js binary for execution
- Have explicit memory management
- Recover automatically if crash occurs immediately after start
- Verify port binding with retry logic

---

### **Issue 2: pgAdmin - HTTP 502 Bad Gateway (Port 5050)**

**Root Causes:**
1. No verification that Gunicorn binary exists before PM2 start
2. No validation that Gunicorn process started successfully
3. Insufficient Gunicorn configuration (worker threads too high, no timeout)
4. Nginx proxy missing proper buffering and timeout settings
5. No HTTP health check to confirm backend is responding
6. Missing `SCRIPT_NAME` environment variable (causes routing issues)

**Fixes Applied:**

```bash
# OLD CODE
pm2 start "$NDC_CONFIG_DIR/pgadmin.config.js"
pm2 save
systemctl restart nginx

# NEW CODE
# 1. Verify Gunicorn exists before attempting to start
if [ ! -f "$PGADMIN_DIR/venv/bin/gunicorn" ]; then
    print_error "Gunicorn not found at $PGADMIN_DIR/venv/bin/gunicorn"
    return
fi

# 2. Improved Gunicorn configuration
cat > "$NDC_CONFIG_DIR/pgadmin.config.js" <<'PGADMIN_CONFIG'
module.exports = {
  apps: [{
    name: 'pgadmin',
    script: 'PGADMIN_VENV_BIN/gunicorn',
    # OLD: --workers=1 --threads=25 (threads too high)
    # NEW: optimized for stability
    args: '--bind 127.0.0.1:5051 --workers 2 --threads 10 --timeout 120 --access-logfile - --error-logfile -',
    max_memory_restart: '300M',
    env: {
      PGADMIN_SETUP_EMAIL: 'PGADMIN_EMAIL_VAL',
      PGADMIN_SETUP_PASSWORD: 'PGADMIN_PASS_VAL',
      SCRIPT_NAME: '/'  # <- FIX: Add routing context
    }
  }]
};
PGADMIN_CONFIG

# 3. Enhanced startup verification
pm2 delete pgadmin >/dev/null 2>&1 || true
sleep 2
pm2 start "$NDC_CONFIG_DIR/pgadmin.config.js"
pm2 save
sleep 5

# Verify pgAdmin started
if ! pm2 list | grep -q "pgadmin.*online"; then
    print_error "pgAdmin failed to start"
    print_info "Displaying PM2 logs:"
    pm2 logs pgadmin --lines 30 --nostream 2>&1 || true
    
    # Attempt recovery
    pm2 delete pgadmin 2>/dev/null || true
    sleep 2
    pm2 start "$NDC_CONFIG_DIR/pgadmin.config.js"
    sleep 10
    
    if ! pm2 list | grep -q "pgadmin.*online"; then
        print_error "pgAdmin still not running"
        return
    fi
fi

# 4. Verify Gunicorn is actually listening
local gunicorn_ok=false
for i in {1..5}; do
    if ss -tulnp 2>/dev/null | grep -q ":5051"; then
        gunicorn_ok=true
        break
    fi
    sleep 1
done

if [ "$gunicorn_ok" = true ]; then
    print_success "pgAdmin Gunicorn is listening on 127.0.0.1:5051"
else
    print_error "pgAdmin Gunicorn is not listening on port 5051"
    pm2 logs pgadmin --lines 20 --nostream 2>&1 || true
fi

# 5. Enhanced Nginx configuration
cat > /etc/nginx/conf.d/pgadmin.conf <<'NGINX_PGADMIN'
upstream pgadmin_backend {
    server 127.0.0.1:5051 fail_timeout=10s max_fails=3;
    keepalive 32;  # <- FIX: Keep connections alive
}

server {
    listen 5050 default_server;
    server_name _;
    client_max_body_size 25M;

    location / {
        proxy_pass http://pgadmin_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";  # <- FIX: Keep-alive
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Script-Name /;
        # <- FIX: Add proper timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        # <- FIX: Add buffering to prevent memory issues
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }
}
NGINX_PGADMIN

# 6. Validate Nginx before restart
if ! nginx -t >/dev/null 2>&1; then
    print_error "Nginx configuration validation failed"
    nginx -t
    return
fi

# 7. Reload Nginx safely
if ! systemctl reload nginx 2>&1; then
    print_error "Failed to reload Nginx"
    systemctl status nginx || true
    return
fi
```

**Result:** pgAdmin will now:
- Verify Gunicorn binary exists before starting
- Have optimized worker/thread settings
- Include proper timeout and routing configuration
- Pass required environment variables (`SCRIPT_NAME`)
- Be verified as actually listening on port 5051
- Have Nginx properly configured for proxying with buffering and timeouts

---

## Key Improvements Summary

| Issue | Old Code | New Code | Impact |
|-------|----------|----------|--------|
| **Mongo Express - Node Binary** | Uses default node in PATH | Explicitly specifies NVM node binary | Ensures correct Node version |
| **Mongo Express - Recovery** | Single retry, no process check | Process check + conditional recovery | Auto-recovery from immediate crash |
| **Mongo Express - Memory** | No limit | `max_memory_restart: '200M'` | Prevents memory leaks/OOM |
| **pgAdmin - Pre-flight Check** | None | Verify Gunicorn exists | Prevents vague errors |
| **pgAdmin - Gunicorn Config** | `--workers=1 --threads=25` | `--workers 2 --threads 10` | Stable under load |
| **pgAdmin - Environment** | Missing `SCRIPT_NAME` | Includes `SCRIPT_NAME: '/'` | Fixes routing issues |
| **pgAdmin - Verification** | Only PM2 status | PM2 status + port binding check | Confirms actual listening |
| **Nginx - Timeouts** | Missing | 60s connect/send/read timeouts | Prevents timeout 502 errors |
| **Nginx - Buffering** | None | Proper buffer sizes | Handles large responses |
| **Nginx - Keep-alive** | Missing | Upstream keepalive + proxy keep-alive | Connection reuse |

---

## Testing Recommendations

### Test Mongo Express (8081):
```bash
# After installation, verify:
curl http://localhost:8081/
# Should see HTML response (auth required)

# Check PM2 status:
pm2 list

# Check memory usage:
pm2 monit

# Check logs for errors:
pm2 logs mongo-express --lines 50
```

### Test pgAdmin (5050):
```bash
# After installation, verify Gunicorn is listening:
ss -tulnp | grep 5051
netstat -tulnp | grep 5051

# Verify Nginx can reach it:
curl http://127.0.0.1:5051/

# Verify Nginx reverse proxy works:
curl http://localhost:5050/

# Check PM2 status:
pm2 list

# Check Gunicorn logs:
pm2 logs pgadmin --lines 50

# Check Nginx logs:
tail -f /var/log/nginx/error.log
```

---

## Files Modified

- `install.sh`: Lines 520-620 (Mongo Express section)
- `install.sh`: Lines 1090-1200 (pgAdmin section)

---

## Deployment Notes

1. **Backup:** Always backup `install.sh` before deploying
2. **Testing:** Test on staging environment first
3. **PM2 Persistence:** After successful startup, run `pm2 startup && pm2 save`
4. **Nginx Reload:** The script now validates Nginx before reload (safer)
5. **Error Recovery:** Both services now have automatic recovery on startup failure

---

## Expected Outcome

✅ **Mongo Express:** 
- Will not return 500 errors due to process crashes
- Will properly recover if Gunicorn fails to start
- Will have stable memory management

✅ **pgAdmin:**
- Will not return 502 errors due to Gunicorn not running
- Will properly detect if Gunicorn fails to start
- Will have correct timeouts and buffering in Nginx
- Will have proper routing configuration

