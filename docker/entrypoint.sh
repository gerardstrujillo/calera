#!/bin/bash
set -e

# Cambiar a directorio de trabajo
cd /var/www/html

# Generar APP_KEY si no existe
if [ -z "$APP_KEY" ]; then
    echo "Generando APP_KEY..."
    php artisan key:generate --force
fi

# Limpiar caché
echo "Limpiando cachés..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear

# Ejecutar migraciones
echo "Ejecutando migraciones..."
php artisan migrate --force

# Crear enlace simbólico para storage (si es necesario)
if [ ! -L /var/www/html/public/storage ]; then
    echo "Creando enlace simbólico para storage..."
    php artisan storage:link || true
fi

# Establecer permisos correctos
chown -R www-data:www-data /var/www/html/storage
chown -R www-data:www-data /var/www/html/bootstrap/cache
chmod -R 755 /var/www/html/storage
chmod -R 755 /var/www/html/bootstrap/cache

echo "✓ Inicialización completada"

# Ejecutar el comando pasado (supervisord o lo que sea)
exec "$@"
