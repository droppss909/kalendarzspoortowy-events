#!/bin/bash

# Skrypt do naprawy uprawnień storage w Laravel
# Użycie: ./FIX_STORAGE_PERMISSIONS.sh

echo "Naprawianie uprawnień storage..."

# Utwórz katalogi jeśli nie istnieją
mkdir -p storage/app/htmlpurifier
mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/logs
mkdir -p bootstrap/cache

# Ustaw uprawnienia
chmod -R 775 storage
chmod -R 775 bootstrap/cache

# Ustaw właściciela (jeśli masz sudo)
CURRENT_USER=$(whoami)
if command -v sudo &> /dev/null; then
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" storage bootstrap/cache 2>/dev/null
    echo "✓ Ustawiono właściciela na $CURRENT_USER"
else
    chown -R "$CURRENT_USER:$CURRENT_USER" storage bootstrap/cache 2>/dev/null || echo "⚠ Uruchom z sudo dla zmiany właściciela"
fi

echo "✓ Uprawnienia naprawione!"
echo ""
echo "Sprawdź uprawnienia:"
ls -ld storage storage/app/htmlpurifier bootstrap/cache


