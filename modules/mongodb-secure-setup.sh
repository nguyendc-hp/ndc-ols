#!/bin/bash
# MongoDB secure setup for ndc-ols
# Tự động hóa: tạo user/password ngẫu nhiên, cấu hình bảo mật, hướng dẫn kết nối Compass

set -e

# 1. Sinh user/password ngẫu nhiên
MONGO_USER="admin_$(head -c 4 /dev/urandom | od -An -t x | tr -d ' ' | cut -c1-6)"
MONGO_PASS="$(head -c 12 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)"

# 2. Cài mongosh nếu chưa có
if ! command -v mongosh &> /dev/null; then
  echo "Cài đặt mongosh..."
  apt update
  apt install -y mongodb-clients
fi

# 3. Tạo user admin
echo "Creating admin user..."
if ! mongosh --quiet --eval "
  use admin;
  try {
    db.createUser({
      user: '$MONGO_USER',
      pwd: '$MONGO_PASS',
      roles: [ { role: 'userAdminAnyDatabase', db: 'admin' }, { role: 'readWriteAnyDatabase', db: 'admin' } ]
    });
    print('User created successfully');
  } catch (e) {
    if (e.code === 51003) { // User already exists
       print('User already exists, updating password...');
       db.changeUserPassword('$MONGO_USER', '$MONGO_PASS');
    } else {
       throw e;
    }
  }
"; then
    echo "Failed to create/update MongoDB user!"
    exit 1
fi

# 4. Bật xác thực trong mongod.conf
CONF_FILE="/etc/mongod.conf"
if ! grep -q "authorization: enabled" "$CONF_FILE"; then
  echo "Bật security.authorization trong mongod.conf..."
  echo -e "\nsecurity:\n  authorization: enabled" >> "$CONF_FILE"
fi

# 5. Chỉ cho phép truy cập từ localhost
# Preserve indentation to avoid breaking YAML
sed -i 's/^\( *\)bindIp: .*/\1bindIp: 127.0.0.1/' "$CONF_FILE"

# 6. Khởi động lại MongoDB
systemctl restart mongod

# 7. Chặn port 27017 trên firewall
ufw deny 27017 || true

# 8. In thông tin kết nối và hướng dẫn dùng Compass qua SSH Tunnel
cat <<INFO
====================================
MongoDB đã được bảo mật!
User: $MONGO_USER
Password: $MONGO_PASS

Kết nối Compass qua SSH Tunnel:
ssh -L 27017:localhost:27017 <user>@<VPS_IP>
Sau đó dùng chuỗi:
mongodb://$MONGO_USER:$MONGO_PASS@localhost:27017/admin?authSource=admin
====================================
INFO
