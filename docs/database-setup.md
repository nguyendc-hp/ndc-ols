# Database Setup & Management

NDC OLS automatically installs and configures the following databases:
- **MongoDB** (with Mongo Express GUI)
- **MySQL/MariaDB** (with phpMyAdmin GUI)
- **PostgreSQL** (with pgAdmin 4 GUI)
- **Redis** (Cache)

## 1. Access Credentials

After installation, all credentials are saved in `/etc/ndc-ols/auth.conf`. You can view them by running:

```bash
cat /etc/ndc-ols/auth.conf
```

Or simply run:
```bash
ndc info
```

## 2. MongoDB

- **Service**: `mongod`
- **Port**: 27017 (localhost only)
- **GUI**: Mongo Express at `http://YOUR_IP:8081`
- **Auth**: Enabled by default.

### Connecting from Node.js
```javascript
const mongoose = require('mongoose');
mongoose.connect('mongodb://admin:PASSWORD@127.0.0.1:27017/admin?authSource=admin');
```

## 3. MySQL / MariaDB

- **Service**: `mariadb`
- **Port**: 3306 (localhost only)
- **GUI**: phpMyAdmin at `http://YOUR_IP:8080`
- **Root User**: `root`

### Connecting from Node.js
```javascript
const mysql = require('mysql2');
const connection = mysql.createConnection({
  host: '127.0.0.1',
  user: 'root',
  password: 'PASSWORD',
  database: 'test'
});
```

## 4. PostgreSQL

- **Service**: `postgresql`
- **Port**: 5432 (localhost only)
- **GUI**: pgAdmin 4 at `http://YOUR_IP:5050`
- **Admin User**: `admin`

### Connecting from Node.js
```javascript
const { Client } = require('pg');
const client = new Client({
  user: 'admin',
  host: '127.0.0.1',
  database: 'postgres',
  password: 'PASSWORD',
  port: 5432,
});
```

### Using pgAdmin 4
1. Go to `http://YOUR_IP:5050`
2. Login with email `admin@ndc.local` and the generated password.
3. Right click "Servers" > "Register" > "Server".
4. **General** tab: Name it "Localhost".
5. **Connection** tab:
   - Host name/address: `127.0.0.1`
   - Port: `5432`
   - Maintenance database: `postgres`
   - Username: `admin`
   - Password: (your generated password)
   - Save password: Yes

## 5. Redis

- **Service**: `redis-server`
- **Port**: 6379 (localhost only)

### Connecting from Node.js
```javascript
const redis = require('redis');
const client = redis.createClient();
await client.connect();
```

## Security Notes

- All databases are bound to `127.0.0.1` by default for security.
- GUIs (Mongo Express, phpMyAdmin, pgAdmin) are exposed on public ports (8081, 8080, 5050).
- **Recommendation**: Use the Firewall manager (`ndc firewall`) to restrict access to these ports if needed.
