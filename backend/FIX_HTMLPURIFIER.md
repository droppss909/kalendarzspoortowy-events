# Naprawa uprawnień dla htmlpurifier

## Problem
Katalog `storage/app/htmlpurifier` ma właściciela `82:82` (prawdopodobnie użytkownik www-data), a nie użytkownika, który uruchamia aplikację.

## Rozwiązanie

Uruchom w terminalu (wymaga sudo):

```bash
cd backend
sudo chown -R $(whoami):$(whoami) storage/app/htmlpurifier
sudo chmod -R 775 storage/app/htmlpurifier
```

Lub jeśli chcesz naprawić wszystkie katalogi storage:

```bash
cd backend
sudo chown -R $(whoami):$(whoami) storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

## Alternatywa (bez sudo)

Jeśli nie masz sudo, możesz spróbować:

```bash
cd backend
# Usuń stary katalog i utwórz nowy
rm -rf storage/app/htmlpurifier
mkdir -p storage/app/htmlpurifier
chmod 775 storage/app/htmlpurifier
```

## Weryfikacja

Sprawdź czy działa:

```bash
cd backend
ls -ld storage/app/htmlpurifier
# Powinno pokazać: drwxrwxr-x ... twoj_uzytkownik:twoj_uzytkownik
```


