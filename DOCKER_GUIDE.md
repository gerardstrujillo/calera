# 🐳 Control de Asistencias - Guía Docker

Esta guía te ayuda a ejecutar el proyecto **Control de Asistencias** con Docker de forma segura y sin inconvenientes.

## 📋 Requisitos

- **Docker** >= 20.10 ([Descargar](https://www.docker.com/products/docker-desktop))
- **Docker Compose** >= 1.29 (generalmente viene con Docker Desktop)
- **Git** para clonar el repositorio
- **2GB de RAM** mínimo disponible
- **5GB de espacio en disco**

Verifica que Docker esté instalado:
```bash
docker --version
docker-compose --version
```

## 🚀 Inicio rápido

### 1️⃣ Clonar el repositorio
```bash
git clone https://github.com/gerardstrujillo/calera.git
cd control_asistencias-main
```

### 2️⃣ Configurar variables de entorno
```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar .env con tus datos (contraseña de Aiven, etc.)
# Asegúrate que tenga estos valores:
# DB_HOST=calera-calera.d.aivencloud.com
# DB_PORT=13361
# DB_PASSWORD=tu_password_aqui
# MYSQL_ATTR_SSL_CA=/var/www/html/ca.pem
```

### 3️⃣ Construir y ejecutar
**Opción A: Con Docker Compose (Recomendado)**
```bash
docker-compose up -d
```

**Opción B: Con script helper**
```bash
./docker/build.sh run
```

### 4️⃣ Verificar que esté funcionando
```bash
# Ver logs
docker-compose logs -f app

# O con el script
./docker/build.sh logs
```

Accede a: **http://localhost:8080**

## 📝 Comandos útiles

### Con Docker Compose
```bash
# Iniciar
docker-compose up -d

# Ver logs
docker-compose logs -f app

# Parar
docker-compose down

# Ejecutar comando
docker-compose exec app php artisan migrate

# Ver estado
docker-compose ps
```

### Con el script helper
```bash
# Construir imagen
./docker/build.sh build

# Ejecutar y construir
./docker/build.sh run

# Ver logs
./docker/build.sh logs

# Ejecutar migraciones
./docker/build.sh migrate

# Ejecutar seeders
./docker/build.sh seed

# Acceder a bash
./docker/build.sh exec bash

# Detener
./docker/build.sh stop

# Limpiar todo
./docker/build.sh clean
```

## 🛠️ Tareas comunes

### ✅ Ejecutar migraciones
```bash
docker-compose exec app php artisan migrate --force
```

### ✅ Ejecutar seeders
```bash
docker-compose exec app php artisan db:seed --force
```

### ✅ Acceder a la consola Laravel (Tinker)
```bash
docker-compose exec app php artisan tinker
```

### ✅ Ver logs de aplicación
```bash
docker-compose logs -f app
```

### ✅ Acceder a bash dentro del contenedor
```bash
docker-compose exec app bash
```

### ✅ Verificar conectividad a BD
```bash
docker-compose exec app php artisan tinker
# Luego en tinker:
>>> DB::connection('mysql')->getPdo()
```

### ✅ Generar APP_KEY si falta
```bash
docker-compose exec app php artisan key:generate
```

### ✅ Limpiar caché de Laravel
```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan view:clear
```

## 🔍 Troubleshooting

### ❌ "Error: No such container"
```bash
# Solución: Construir nuevamente
docker-compose down
docker-compose up -d
```

### ❌ "SQLSTATE[HY000] [2002] Connection refused"
```bash
# Verificar credenciales en .env:
# - DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD
# - MYSQL_ATTR_SSL_CA debe ser /var/www/html/ca.pem

# Probar conexión:
docker-compose exec app php artisan tinker
>>> DB::connection('mysql')->getPdo()
```

### ❌ "Permission denied" en storage o bootstrap/cache
```bash
# Solución:
docker-compose exec app chown -R www-data:www-data /var/www/html/storage
docker-compose exec app chown -R www-data:www-data /var/www/html/bootstrap/cache
```

### ❌ Puerto 8080 ya está en uso
```bash
# Cambiar puerto en docker-compose.yml:
# ports:
#   - "8081:8080"  # Cambiar 8081 por el puerto que quieras

docker-compose down
docker-compose up -d
```

### ❌ La imagen no se construye
```bash
# Ver logs detallados
docker-compose build --no-cache

# Limpiar y reintentar
docker system prune -a
docker-compose build --no-cache
docker-compose up -d
```

## 📁 Estructura Docker

```
proyecto/
├── Dockerfile              # Imagen multi-stage optimizada
├── docker-compose.yml      # Orquestación de contenedores
├── docker/
│   ├── build.sh           # Script helper
│   ├── php.ini            # Configuración PHP
│   ├── nginx.conf         # Configuración Nginx
│   ├── default.conf       # Virtual host
│   ├── supervisord.conf   # Gestor de procesos
│   ├── entrypoint.sh      # Script de inicialización
│   └── README.md          # Documentación Docker
├── ca.pem                 # Certificado SSL de Aiven ⭐
└── .env.example           # Ejemplo de variables
```

## 🔐 Variables de entorno importantes

```env
# Aplicación
APP_NAME=ControlAsistencias
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost:8080

# Base de datos (Aiven)
DB_HOST=calera-calera.d.aivencloud.com
DB_PORT=13361
DB_DATABASE=defaultdb
DB_USERNAME=avnadmin
DB_PASSWORD=tu_password_aqui
MYSQL_ATTR_SSL_CA=/var/www/html/ca.pem  # ⭐ IMPORTANTE

# Cache y sesiones
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
```

## 📊 Monitoreo

### Ver recursos usados
```bash
docker stats
```

### Ver procesos dentro del contenedor
```bash
docker-compose exec app ps aux
```

### Ver puertos abiertos
```bash
docker-compose port app
```

## 🧹 Limpieza

### Detener todos los contenedores
```bash
docker-compose down
```

### Eliminar imágenes
```bash
docker image rm control-asistencias:latest
```

### Limpiar sistema completo
```bash
docker system prune -a  # Advertencia: elimina imágenes no usadas
```

## 📚 Documentación adicional

- [Docker Docs](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Laravel on Docker](https://laravel.com/docs/9.x/installation#getting-started-on-windows)
- [Nginx Configuration](https://nginx.org/en/docs/)

## ✨ Características incluidas

✅ Multi-stage Docker build (imagen optimizada)
✅ PHP 8.2 FPM
✅ Nginx web server
✅ Supervisor para gestión de procesos
✅ SSL con Aiven automatizado
✅ Migraciones auto-ejecutadas
✅ Assets compilados con Vite
✅ Healthcheck automático
✅ Permisos correctos de archivos
✅ Configuración de producción
✅ Logs centralizados

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los **logs**: `docker-compose logs -f app`
2. Verifica las **variables de entorno** en `.env`
3. Asegúrate que el **certificado CA** (`ca.pem`) esté presente
4. Intenta **limpiar y reconstruir**: `docker system prune -a && docker-compose up -d --build`

---

**Última actualización:** Agosto 2026
**Versión Docker:** Dockerfile optimizado multi-stage
**PHP Version:** 8.2
