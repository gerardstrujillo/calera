# Dockerfile para Control de Asistencias

Esta carpeta contiene toda la configuración Docker necesaria para ejecutar el proyecto Laravel.

## Archivos incluidos

- **Dockerfile** - Configuración multi-stage para producción
- **docker-compose.yml** - Orquestación de contenedores
- **nginx.conf** - Configuración del servidor web
- **default.conf** - Virtual host de Nginx
- **php.ini** - Configuración de PHP para producción
- **supervisord.conf** - Gestor de procesos
- **entrypoint.sh** - Script de inicialización

## Uso

### Build de la imagen

```bash
docker build -t control-asistencias:latest .
```

### Ejecutar con Docker Compose

```bash
# Desarrollo
docker-compose up -d

# Producción (con más replicas)
docker-compose -f docker-compose.yml up -d --scale app=2
```

### Construcción manual

```bash
# Build
docker build -t control-asistencias:latest .

# Run
docker run -d \
  -p 8080:8080 \
  -e DB_HOST=tu-host \
  -e DB_PASSWORD=tu-password \
  -v $(pwd)/storage:/var/www/html/storage \
  --name app \
  control-asistencias:latest
```

## Características

✅ **Multi-stage build** - Imagen optimizada y pequeña
✅ **PHP 8.2 FPM** - Última versión estable
✅ **Nginx** - Servidor web moderno
✅ **Supervisor** - Gestión de procesos
✅ **SSL con Aiven** - Soporta conexión segura a base de datos
✅ **Healthcheck** - Monitoreo automático
✅ **Assets compilados** - Vite integrado en el build
✅ **Migraciones automáticas** - Se ejecutan al iniciar

## Requisitos

- Docker >= 20.10
- Docker Compose >= 1.29 (opcional)
- 2GB de RAM mínimo
- 5GB de espacio en disco

## Variables de entorno

Configurar en `.env` o en `docker-compose.yml`:

```
APP_NAME=ControlAsistencias
APP_ENV=production
APP_DEBUG=false
DB_HOST=calera-calera.d.aivencloud.com
DB_PORT=13361
DB_DATABASE=defaultdb
DB_USERNAME=avnadmin
DB_PASSWORD=tu_password
```

## Puertos

- **8080** - Aplicación web (Nginx + PHP-FPM)

## Logs

```bash
# Ver logs
docker logs -f app

# Dentro del contenedor
docker exec -it app tail -f /var/log/nginx/error.log
docker exec -it app tail -f /var/log/php-fpm-error.log
```

## Troubleshooting

### Conexión a base de datos
```bash
# Verificar conectividad
docker exec app php artisan tinker
>>> DB::connection('mysql')->getPdo()
```

### Permisos de archivos
```bash
docker exec app chown -R www-data:www-data /var/www/html
```

### Ejecutar migraciones manualmente
```bash
docker exec app php artisan migrate --force
```

### Ejecutar seed
```bash
docker exec app php artisan db:seed
```

## Performance

- **Opcache** habilitado para mejor performance
- **Gzip compression** para assets
- **Worker processes** dinámicos en Nginx
- **PHP-FPM pool** configurado para producción
