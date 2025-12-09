# Jak wyłączyć S3 dla testów

## Problem
Aplikacja domyślnie używa S3 do przechowywania plików, co wymaga konfiguracji AWS. Dla testów lokalnych możesz użyć lokalnego filesystem.

## Rozwiązanie

Dodaj do pliku `.env` w katalogu `backend`:

```bash
# Użyj lokalnego filesystem zamiast S3
FILESYSTEM_PUBLIC_DISK=public
FILESYSTEM_PRIVATE_DISK=local
```

## Pełna konfiguracja dla testów

Dla kompletnej konfiguracji testowej dodaj do `.env`:

```bash
# Filesystem - lokalny zamiast S3
FILESYSTEM_PUBLIC_DISK=public
FILESYSTEM_PRIVATE_DISK=local

# Mail - log zamiast SMTP
MAIL_MAILER=log
```

## Szybka komenda

```bash
cd backend
echo "FILESYSTEM_PUBLIC_DISK=public" >> .env
echo "FILESYSTEM_PRIVATE_DISK=local" >> .env
echo "MAIL_MAILER=log" >> .env
```

## Weryfikacja

Po zmianie `.env` możesz sprawdzić czy działa:

```bash
cd backend
php artisan config:clear
php artisan cache:clear
```

Teraz aplikacja będzie używać lokalnego filesystem (`storage/app/public`) zamiast S3.


