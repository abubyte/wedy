# VPS Setup Guide - api.wedy.uz

## 1. DNS Sozlamalarini Tekshirish

Domain'ingizning DNS sozlamalarida quyidagi A record bo'lishi kerak:

```
Type: A
Name: api
Value: <VPS_IP_ADDRESS>
TTL: 3600 (yoki default)
```

Tekshirish:
```bash
# DNS'ni tekshirish
dig api.wedy.uz +short
# yoki
nslookup api.wedy.uz

# Natija VPS IP manzilingizni ko'rsatishi kerak
```

## 2. Firewall Portlarini Ochish

Port 80 (HTTP) va 443 (HTTPS) ochiq bo'lishi kerak:

```bash
# UFW ishlatilsa:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

# yoki iptables ishlatilsa:
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables-save
```

## 3. Docker va Docker Compose Tekshirish

```bash
# Docker versiyasini tekshirish
docker --version
docker compose version

# Agar yo'q bo'lsa, o'rnatish:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose-plugin -y
```

## 4. Project'ni VPS'ga Ko'chirish

Agar GitHub Actions orqali deploy qilinmasa:

```bash
# VPS'da:
cd /root
git clone <repository-url> wedy
cd wedy

# yoki GitHub Actions orqali deploy qilingan bo'lsa:
cd /root/wedy
```

## 5. Environment Variables Sozlash

```bash
cd /root/wedy

# Docker .env yaratish
cat > .env <<EOF
POSTGRES_DB=wedy_db
POSTGRES_USER=wedy_user
POSTGRES_PASSWORD=<strong_password>
EOF
chmod 600 .env

# Backend .env yaratish
cd backend
cp .env.example .env
nano .env  # Barcha kerakli o'zgaruvchilarni to'ldiring
```

## 6. Dummy SSL Sertifikatlarini Yaratish

Nginx ishga tushishi uchun:

```bash
cd /root/wedy
chmod +x infra/nginx/create-dummy-cert.sh
./infra/nginx/create-dummy-cert.sh
```

## 7. Container'larni Ishga Tushirish

```bash
cd /root/wedy

# Base image'larni yuklash
docker compose pull postgres redis

# Backend image'ni build qilish
docker compose build backend

# Barcha servislarni ishga tushirish
docker compose up -d

# Holatni tekshirish
docker compose ps
```

## 8. Let's Encrypt Sertifikatlarini Olish

**MUHIM:** Bu qadamni faqat DNS to'g'ri sozlangan va port 80 ochiq bo'lganda bajaring!

```bash
cd /root/wedy/infra/nginx

# Email'ni tekshirish (agar o'zgartirish kerak bo'lsa)
nano init-letsencrypt.sh
# email="abdurakhmon278@gmail.com" - bu allaqachon sozlangan

# Let's Encrypt sertifikatlarini olish
chmod +x init-letsencrypt.sh
./init-letsencrypt.sh
```

**Eslatma:** Agar birinchi marta ishga tushirilsa, staging mode'ni yoqib sinab ko'ring:

```bash
# init-letsencrypt.sh faylida:
staging=1  # Test uchun
# Keyin haqiqiy sertifikatlar uchun:
staging=0
```

## 9. Nginx va Backend Holatini Tekshirish

```bash
# Container loglarini ko'rish
docker compose logs nginx
docker compose logs backend

# Nginx holatini tekshirish
docker compose exec nginx nginx -t

# Backend health check
curl http://localhost:8000/health

# API'ni tashqaridan tekshirish
curl https://api.wedy.uz/health
```

## 10. Certbot Auto-Renewal Tekshirish

Certbot container avtomatik ravishda sertifikatlarni yangilaydi:

```bash
# Certbot loglarini ko'rish
docker compose logs certbot

# Manual yangilash (agar kerak bo'lsa)
docker compose exec certbot certbot renew
```

## 11. Database Migration'larni Ishga Tushirish

```bash
cd /root/wedy
docker compose exec backend poetry run alembic upgrade head
```

## 12. Muammolarni Tuzatish

### Nginx ishlamayapti:
```bash
# Loglarni ko'rish
docker compose logs nginx

# Nginx konfiguratsiyasini tekshirish
docker compose exec nginx nginx -t

# Qayta ishga tushirish
docker compose restart nginx
```

### SSL sertifikatlar muammosi:
```bash
# Dummy sertifikatlarni qayta yaratish
cd /root/wedy
./infra/nginx/create-dummy-cert.sh
docker compose restart nginx

# Let's Encrypt sertifikatlarini qayta olish
cd infra/nginx
./init-letsencrypt.sh
```

### Backend ishlamayapti:
```bash
# Loglarni ko'rish
docker compose logs backend

# Backend'ni qayta build qilish
docker compose build backend
docker compose up -d backend
```

## 13. Monitoring va Loglar

```bash
# Barcha container loglarini real-time ko'rish
docker compose logs -f

# Faqat nginx loglari
docker compose logs -f nginx

# Faqat backend loglari
docker compose logs -f backend
```

## 14. Security Checklist

- [ ] Firewall sozlangan (faqat 80, 443, 22 portlar ochiq)
- [ ] SSH key-based authentication ishlatilmoqda
- [ ] Environment variables xavfsiz saqlanmoqda
- [ ] Database parollari kuchli
- [ ] SSL sertifikatlar to'g'ri ishlayapti
- [ ] Nginx security headers sozlangan
- [ ] Rate limiting ishlayapti

## 15. Backup

```bash
# Database backup
docker compose exec postgres pg_dump -U wedy_user wedy_db > backup_$(date +%Y%m%d).sql

# SSL sertifikatlar backup
tar -czf ssl_backup_$(date +%Y%m%d).tar.gz infra/nginx/certbot/conf/
```

