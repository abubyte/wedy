# Nginx va SSL Konfiguratsiya

## 📁 Fayl Tuzilishi

```
infra/nginx/
├── nginx.conf              # Asosiy nginx konfiguratsiya (HTTP + HTTPS)
├── nginx-http-only.conf    # Faqat HTTP uchun (SSL yo'q)
├── init-ssl.sh             # SSL sertifikat olish skripti
├── certbot/
│   ├── conf/               # Let's Encrypt sertifikatlar
│   └── www/                # ACME challenge fayllari
└── README.md               # Ushbu fayl
```

## 🚀 Ishga Tushirish

### 1. Development (SSL yo'q)

```bash
# Backend to'g'ridan-to'g'ri (nginx yo'q)
docker compose -f docker-compose.dev.yml up -d

# API: http://localhost:8000
# Docs: http://localhost:8000/docs
```

### 2. Production (HTTP only - SSL oldinidan)

Agar SSL sertifikati hali yo'q bo'lsa:

```bash
# HTTP-only nginx config ishlatish
cp infra/nginx/nginx-http-only.conf infra/nginx/nginx.conf

# Docker compose ishga tushirish
docker compose up -d

# API: http://api.wedy.uz
```

### 3. Production (HTTPS bilan)

```bash
# 1. SSL sertifikat olish
cd infra/nginx
./init-ssl.sh admin@wedy.uz api.wedy.uz

# 2. Asosiy nginx.conf ishlatish (HTTP + HTTPS)
# (nginx.conf allaqachon to'g'ri konfiguratsiya qilingan)

# 3. Docker compose qayta ishga tushirish
docker compose -f docker-compose.prod.yml up -d

# API: https://api.wedy.uz
```

## 🔐 SSL Sertifikat

### Yangi sertifikat olish

```bash
cd infra/nginx
./init-ssl.sh your-email@example.com api.wedy.uz
```

### Sertifikatni tekshirish

```bash
docker compose exec nginx nginx -t
openssl x509 -in infra/nginx/certbot/conf/live/api.wedy.uz/fullchain.pem -text -noout
```

### Manual yangilash

```bash
docker compose run --rm certbot renew
docker compose exec nginx nginx -s reload
```

## ⚙️ Nginx Konfiguratsiya

### Rate Limiting

| Zone | Limit | Burst |
|------|-------|-------|
| `api` | 10 req/s | 20 |
| `auth` | 5 req/s | 10 |

### Timeouts

| Setting | Value |
|---------|-------|
| Connect | 10s |
| Send | 60s |
| Read | 60s |

### Max Upload Size

```
client_max_body_size 10M;
```

## 🐳 Docker Compose Fayllar

| Fayl | Ishlatish |
|------|-----------|
| `docker-compose.yml` | Asosiy (nginx bilan) |
| `docker-compose.dev.yml` | Development (nginx yo'q) |
| `docker-compose.prod.yml` | Production (SSL + resource limits) |

## 🔧 Foydali Buyruqlar

```bash
# Nginx konfigni tekshirish
docker compose exec nginx nginx -t

# Nginx qayta yuklash
docker compose exec nginx nginx -s reload

# Nginx loglarni ko'rish
docker compose logs -f nginx

# Backend loglarni ko'rish
docker compose logs -f backend

# Barcha servislar holati
docker compose ps
```

## ⚠️ Muammolarni Hal Qilish

### 1. SSL sertifikat topilmadi

```bash
# HTTP-only config ishlatish
cp nginx-http-only.conf nginx.conf
docker compose up -d nginx
```

### 2. 502 Bad Gateway

```bash
# Backend sog'ligini tekshirish
curl http://localhost:8000/health

# Backend loglarni ko'rish
docker compose logs backend
```

### 3. Rate limit xatosi (429)

```bash
# Nginx config da rate limitni oshirish
limit_req zone=api burst=50 nodelay;
```

