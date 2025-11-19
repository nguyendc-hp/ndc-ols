# NDC OLS - Full Stack Deployment Guide

NDC OLS provides a powerful **"Full Stack Deploy"** feature designed for MERN (MongoDB, Express, React, Node) and PERN (PostgreSQL) stack applications.

## How it Works

This feature automates the deployment of "Monorepo" style projects where both Frontend and Backend are in the same repository.

### Supported Structure

```
my-project/
├── backend/         # Node.js / Express
│   ├── package.json
│   └── index.js
└── frontend/        # React / Vue / Next.js
    ├── package.json
    └── vite.config.js
```

## Step-by-Step Deployment

1. **Prepare your VPS**
   Ensure you have installed NDC OLS.

2. **Run Deployment**
   ```bash
   ndc
   # Select: 6) Deploy New App
   # Select: 10) Full Stack (Node + React Monorepo)
   ```

3. **Enter Details**
   - **Git URL**: Your repository URL (e.g., `https://github.com/user/repo.git`)
   - **App Name**: Name for the folder (e.g., `myapp`)
   - **Domain**: Your domain (e.g., `myapp.com`)
   - **Backend Port**: Port your Node app runs on (e.g., `8080`)

4. **Configuration (Automatic)**
   - The script clones your repo.
   - Detects `backend` and `frontend` folders.
   - Installs dependencies for both.
   - **Backend**: Starts with PM2.
   - **Frontend**: Builds to static files (`dist` or `build`).
   - **Nginx**: Configures reverse proxy (`/api` -> Backend, `/` -> Frontend).
   - **SSL**: Auto-installs Let's Encrypt SSL.

## Example: Price Tracker Pro

If you are deploying **Price Tracker Pro**:

1. Select **Option 10**.
2. Git URL: `https://github.com/robothutbuimivn/price-tracker-pro.git`
3. Backend Port: `8080`
4. When asked for `.env`, the script will open `nano`.
   - Set `DATABASE_PATH=/var/www/price-tracker/backend/database.db`
5. Done!

## Environment Variables

The script automatically handles `.env` files:
- Copies `.env.example` to `.env` if it exists.
- Opens editor for you to fill in secrets.
- Automatically sets `VITE_API_BASE_URL` for React frontend to point to your domain's API.

## Troubleshooting

- **502 Bad Gateway**: Check if Backend is running (`pm2 list`).
- **404 on API**: Check Nginx config (`/etc/nginx/sites-available/domain.com`).
- **Database Error**: Ensure database is installed (`ndc` -> `4) Database Manager`).
