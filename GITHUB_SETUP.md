# Hướng dẫn Push NDC OLS lên GitHub

## Bước 1: Tạo Repository trên GitHub

1. Truy cập: https://github.com/new
2. Repository name: `ndc-ols`
3. Description: `🚀 VPS Management Script for Node.js & React - Free & Open Source`
4. Chọn: **Public** (để mọi người có thể dùng)
5. **KHÔNG** check: Add README, .gitignore, license (vì đã có sẵn)
6. Click: **Create repository**

## Bước 2: Push Code lên GitHub

Sau khi tạo xong repository, chạy các lệnh sau trong thư mục `NDC OLS`:

```bash
cd "f:\WEBMIVN\NDC OLS"

# Thêm remote repository (thay YOUR_USERNAME bằng username GitHub của bạn)
git remote add origin https://github.com/YOUR_USERNAME/ndc-ols.git

# Hoặc nếu dùng SSH:
# git remote add origin git@github.com:YOUR_USERNAME/ndc-ols.git

# Đổi tên branch sang main (GitHub mặc định dùng main)
git branch -M main

# Push code lên GitHub
git push -u origin main
```

## Bước 3: Cài đặt Repository Settings

### 3.1. Thêm Topics (Tags)
Vào repository → Settings → Topics, thêm:
- `vps`
- `nodejs`
- `reactjs`
- `nginx`
- `pm2`
- `server-management`
- `devops`
- `bash`
- `automation`
- `linux`

### 3.2. Thêm Description
```
🚀 VPS Management Script for Node.js & React - Free & Open Source Alternative to ServerPilot, Runcloud, Ploi
```

### 3.3. Thêm Website (optional)
```
https://github.com/YOUR_USERNAME/ndc-ols
```

### 3.4. Enable Issues & Discussions
- ✅ Issues (để người dùng báo lỗi)
- ✅ Discussions (để community thảo luận)

## Bước 4: Tạo First Release

1. Vào: **Releases** → **Create a new release**
2. Tag: `v1.0.0`
3. Title: `🚀 NDC OLS v1.0.0 - Initial Release`
4. Description:
```markdown
## 🎉 NDC OLS v1.0.0 - Initial Release

First stable release of NDC OLS - VPS Management Script for Node.js & React!

### ✨ Features

- ✅ 30 comprehensive modules for VPS management
- ✅ One-line installation: `curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ndc-ols/main/install.sh | bash`
- ✅ Support for Ubuntu 22.04/24.04, AlmaLinux 8/9, Rocky Linux 8/9
- ✅ Nginx + Node.js/NVM + PM2 integration
- ✅ Multi-database support (PostgreSQL, MongoDB, MySQL, Redis)
- ✅ SSL automation with Let's Encrypt
- ✅ Backup system with cloud sync
- ✅ Firewall & security hardening
- ✅ Deploy from Git or templates
- ✅ 8 built-in project templates
- ✅ System monitoring and logs

### 📦 Installation

**Quick Install:**
```bash
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ndc-ols/main/install.sh | bash
```

**Or download:**
```bash
curl -sO https://raw.githubusercontent.com/YOUR_USERNAME/ndc-ols/main/install.sh
chmod +x install.sh
bash install.sh
```

### 📚 Documentation

- [Quick Start Guide](QUICKSTART.md)
- [Installation Guide](docs/INSTALLATION.md)
- [Usage Guide](docs/USAGE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

### 🙏 Credits

Inspired by WPTangToc OLS for WordPress management.

### 📄 License

MIT License - See [LICENSE](LICENSE)
```

5. Check: **Set as the latest release**
6. Click: **Publish release**

## Bước 5: Test Installation URL

Sau khi push xong, test URL cài đặt:

```bash
# Test trên VPS
ssh root@your-vps-ip

# Chạy lệnh cài đặt
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/ndc-ols/main/install.sh | bash
```

## Bước 6: Cập nhật README với URL chính xác

Sau khi có repository thật, cập nhật các URL trong README.md:

```bash
# Tìm và thay thế
YOUR_USERNAME → username thật của bạn
ndcviet → username thật của bạn (nếu khác)
```

## Bước 7: Tạo GitHub Actions (Optional)

GitHub Actions đã được setup sẵn trong `.github/workflows/shellcheck.yml` để:
- Tự động check syntax của shell scripts
- Chạy mỗi khi có push/PR

## Bước 8: Social Media (Optional)

### Twitter/X:
```
🚀 Giới thiệu NDC OLS - Công cụ quản lý VPS miễn phí cho Node.js & React!

✅ Miễn phí 100%
✅ Cài đặt 1 dòng lệnh
✅ 30 tính năng toàn diện
✅ SSL tự động
✅ Backup cloud

Thay thế ServerPilot, Runcloud, Ploi

GitHub: https://github.com/YOUR_USERNAME/ndc-ols

#nodejs #reactjs #vps #devops #opensource
```

### Facebook Groups:
Đăng vào các groups:
- Node.js Việt Nam
- ReactJS Việt Nam
- DevOps Việt Nam
- Linux/Ubuntu Việt Nam

### Reddit:
- r/node
- r/reactjs
- r/devops
- r/selfhosted

## 🎯 Checklist

- [ ] Tạo repository trên GitHub
- [ ] Push code lên GitHub
- [ ] Thêm topics/tags
- [ ] Enable Issues & Discussions
- [ ] Tạo first release (v1.0.0)
- [ ] Test installation URL trên VPS
- [ ] Update README với URL chính xác
- [ ] Share lên social media

## 📞 Support

Nếu cần hỗ trợ:
- GitHub Issues: https://github.com/YOUR_USERNAME/ndc-ols/issues
- GitHub Discussions: https://github.com/YOUR_USERNAME/ndc-ols/discussions

---

**Chúc mừng! 🎉 Dự án NDC OLS đã sẵn sàng cho cộng đồng!**
```