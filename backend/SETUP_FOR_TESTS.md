# Konfiguracja dla testów lokalnych

## Szybki start

### 1. Utwórz plik .env

```bash
cd backend
cp .env.example .env
```

### 2. Dodaj konfigurację dla testów

Dodaj na końcu pliku `.env`:

```bash
# Test configuration - use local filesystem instead of S3
FILESYSTEM_PUBLIC_DISK=public
FILESYSTEM_PRIVATE_DISK=local

# Test configuration - use log instead of SMTP
MAIL_MAILER=log
```

### 3. Wyczyść cache konfiguracji

```bash
php artisan config:clear
php artisan cache:clear
```

## Pełna komenda (kopiuj-wklej)

```bash
cd backend

# Utwórz .env jeśli nie istnieje
if [ ! -f .env ]; then
  cp .env.example .env
fi

# Dodaj konfigurację testową
cat >> .env << 'EOF'

# Test configuration - use local filesystem instead of S3
FILESYSTEM_PUBLIC_DISK=public
FILESYSTEM_PRIVATE_DISK=local

# Test configuration - use log instead of SMTP  
MAIL_MAILER=log
EOF

# Wyczyść cache
php artisan config:clear
php artisan cache:clear

echo "✓ Konfiguracja testowa dodana!"
```

## Co to robi?

- **FILESYSTEM_PUBLIC_DISK=public** - używa lokalnego dysku (`storage/app/public`) zamiast S3 dla plików publicznych
- **FILESYSTEM_PRIVATE_DISK=local** - używa lokalnego dysku zamiast S3 dla plików prywatnych
- **MAIL_MAILER=log** - zapisuje maile do logów zamiast wysyłać przez SMTP

## Weryfikacja

Po konfiguracji uruchom skrypt testowy:

```bash
./test_register_and_attendee.sh
```

Powinien działać bez błędów S3 i SMTP.


