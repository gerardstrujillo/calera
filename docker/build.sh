#!/bin/bash

# Script para buildear y ejecutar Docker localmente
# Uso: ./docker/build.sh [comando]

set -e

PROJECT_NAME="control-asistencias"
IMAGE_NAME="${PROJECT_NAME}:latest"
CONTAINER_NAME="${PROJECT_NAME}-app"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Build de la imagen
build() {
    print_info "Construyendo imagen Docker..."
    docker build -t "$IMAGE_NAME" -f Dockerfile .
    print_success "Imagen construida: $IMAGE_NAME"
}

# Ejecutar contenedor
run() {
    print_info "Verificando si el contenedor ya existe..."
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_info "Deteniendo contenedor existente..."
        docker stop "$CONTAINER_NAME" || true
        docker rm "$CONTAINER_NAME" || true
    fi
    
    print_info "Iniciando contenedor..."
    docker run -d \
        -p 8080:8080 \
        --name "$CONTAINER_NAME" \
        --env-file .env \
        -v "$(pwd):/var/www/html" \
        -v "$(pwd)/storage:/var/www/html/storage" \
        "$IMAGE_NAME"
    
    print_success "Contenedor iniciado: $CONTAINER_NAME"
    print_info "Esperando inicialización (10s)..."
    sleep 10
    print_info "Accede a: http://localhost:8080"
}

# Ver logs
logs() {
    print_info "Mostrando logs..."
    docker logs -f "$CONTAINER_NAME"
}

# Ejecutar comando en el contenedor
exec() {
    if [ -z "$1" ]; then
        print_error "Debe proporcionar un comando"
        return 1
    fi
    docker exec -it "$CONTAINER_NAME" "$@"
}

# Detener contenedor
stop() {
    print_info "Deteniendo contenedor..."
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    print_success "Contenedor detenido"
}

# Limpiar (remove image)
clean() {
    print_info "Limpiando..."
    docker stop "$CONTAINER_NAME" || true
    docker rm "$CONTAINER_NAME" || true
    docker rmi "$IMAGE_NAME" || true
    print_success "Limpieza completa"
}

# Salud del contenedor
health() {
    print_info "Verificando salud del contenedor..."
    docker inspect --format='{{json .State.Health}}' "$CONTAINER_NAME" | jq .
}

# Migraciones
migrate() {
    print_info "Ejecutando migraciones..."
    exec php artisan migrate --force
}

# Seed
seed() {
    print_info "Ejecutando seeders..."
    exec php artisan db:seed --force
}

# Help
show_help() {
    cat << EOF
${GREEN}Control de Asistencias - Docker Helper${NC}

Uso: $0 [comando]

Comandos:
    build       - Construir imagen Docker
    run         - Ejecutar contenedor
    stop        - Detener contenedor
    logs        - Ver logs en tiempo real
    exec        - Ejecutar comando (ej: exec php artisan tinker)
    health      - Ver estado de salud
    migrate     - Ejecutar migraciones
    seed        - Ejecutar seeders
    clean       - Limpiar todo (imagen + contenedor)
    help        - Mostrar esta ayuda

Ejemplos:
    $0 build
    $0 run
    $0 logs
    $0 exec php artisan migrate --fresh
    $0 migrate
    $0 seed
    $0 stop
    $0 clean

EOF
}

# Main
case "${1:-help}" in
    build)
        build
        ;;
    run)
        build
        run
        ;;
    stop)
        stop
        ;;
    logs)
        logs
        ;;
    exec)
        shift
        exec "$@"
        ;;
    health)
        health
        ;;
    migrate)
        migrate
        ;;
    seed)
        seed
        ;;
    clean)
        clean
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Comando desconocido: $1"
        show_help
        exit 1
        ;;
esac
