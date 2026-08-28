# Multi-stage build para optimizar la imagen
FROM php:8.2-fpm AS builder

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    zip \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensiones PHP requeridas
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    zip \
    gd

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establecer directorio de trabajo
WORKDIR /var/www/html

# Copiar archivos de dependencias
COPY composer.json composer.lock ./
COPY package.json package-lock.json ./

# Instalar dependencias PHP
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Instalar Node.js para compilar assets
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm ci

# Copiar todo el proyecto
COPY . .

# Copiar certificado SSL de Aiven
COPY ca.pem ./ca.pem

# Compilar assets con Vite
RUN npm run build

# Limpiar cache de npm
RUN npm cache clean --force

# Stage final - imagen de producción
FROM php:8.2-fpm

# Instalar dependencias del sistema (solo las necesarias en runtime)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip4 \
    libpng16-16 \
    libjpeg62-turbo \
    libfreetype6 \
    nginx \
    supervisor \
    curl \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensiones PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    zip \
    gd

# Configurar PHP-FPM para producción
RUN echo "pm = dynamic" >> /usr/local/etc/php-fpm.conf \
    && echo "pm.max_children = 20" >> /usr/local/etc/php-fpm.conf \
    && echo "pm.start_servers = 5" >> /usr/local/etc/php-fpm.conf \
    && echo "pm.min_spare_servers = 3" >> /usr/local/etc/php-fpm.conf \
    && echo "pm.max_spare_servers = 10" >> /usr/local/etc/php-fpm.conf

# Copiar configuración de PHP
COPY docker/php.ini /usr/local/etc/php/conf.d/app.ini

# Configurar Nginx
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/sites-available/default
RUN mkdir -p /etc/nginx/sites-enabled && \
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Configurar Supervisor
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Establecer directorio de trabajo
WORKDIR /var/www/html

# Copiar archivos compilados desde builder
COPY --from=builder /var/www/html /var/www/html

# Crear directorios necesarios y establecer permisos
RUN mkdir -p storage/logs storage/app storage/framework/{sessions,views,cache} bootstrap/cache \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache

# Script de inicialización
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Exponer puerto
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Ejecutar el script de entrada
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
