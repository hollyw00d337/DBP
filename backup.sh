#!/bin/bash

# Ruta a respaldar 
SOURCE_DIR=${1:-"/c/Users/$(whoami)/Documents"}
# Carpeta donde se guardarán los respaldos
BACKUP_ROOT="/c/Users/$(whoami)/Backups"

# Fecha actual
DATE=$(date +"%Y-%m-%d")
DAY_OF_WEEK=$(date +%u) 
WEEK_NUM=$(date +%Y-W%U)

# Carpeta diaria
DAILY_DIR="$BACKUP_ROOT/$WEEK_NUM/$DATE"
mkdir -p "$DAILY_DIR"

# ====== FUNCIÓN: Crear respaldo diario ======
backup_daily() {
    echo "Respaldando $SOURCE_DIR en $DAILY_DIR ..."
    rsync -av --delete "$SOURCE_DIR/" "$DAILY_DIR/"
    echo "✅ Respaldo completado: $DAILY_DIR"
}

# ====== FUNCIÓN: Generar ZIP semanal ======
backup_weekly() {
    WEEK_DIR="$BACKUP_ROOT/$WEEK_NUM"
    ZIP_FILE="$BACKUP_ROOT/${WEEK_NUM}.zip"

    if [ -d "$WEEK_DIR" ]; then
        echo "Generando ZIP semanal..."
        zip -r "$ZIP_FILE" "$WEEK_DIR"
        echo "✅ ZIP generado: $ZIP_FILE"

        echo "Eliminando carpetas diarias..."
        rm -rf "$WEEK_DIR"
        echo "✅ Carpeta semanal borrada."
    else
        echo "❌ No existe carpeta para esta semana."
    fi
}

# ====== FUNCIÓN: Restaurar respaldo ======
restore_backup() {
    ZIP_FILE="$BACKUP_ROOT/${WEEK_NUM}.zip"

    if [ ! -f "$ZIP_FILE" ]; then
        echo "❌ No se encontró el archivo: $ZIP_FILE"
        exit 1
    fi

    echo "¿Deseas restaurar un día específico o todos?"
    echo "1) Día específico"
    echo "2) Todos los días"
    read -p "Elige opción [1-2]: " choice

    TMP_DIR="$BACKUP_ROOT/tmp_restore"
    mkdir -p "$TMP_DIR"
    unzip -o "$ZIP_FILE" -d "$TMP_DIR"

    case $choice in
        1)
            echo "Ingresa la fecha a restaurar (ejemplo: 2025-09-01):"
            read DAY_TO_RESTORE
            if [ -d "$TMP_DIR/$WEEK_NUM/$DAY_TO_RESTORE" ]; then
                echo "Restaurando respaldo de $DAY_TO_RESTORE a $SOURCE_DIR ..."
                rsync -av "$TMP_DIR/$WEEK_NUM/$DAY_TO_RESTORE/" "$SOURCE_DIR/"
                echo "✅ Restauración completada."
            else
                echo "❌ No existe respaldo para ese día."
            fi
            ;;
        2)
            echo "Restaurando todos los días..."
            rsync -av "$TMP_DIR/$WEEK_NUM/" "$SOURCE_DIR/"
            echo "✅ Restauración completada."
            ;;
        *)
            echo "❌ Opción inválida."
            ;;
    esac

    rm -rf "$TMP_DIR"
}

# ====== MENÚ PRINCIPAL ======
echo "=== Sistema de Respaldos ==="
echo "1) Respaldo diario"
echo "2) Generar ZIP semanal"
echo "3) Restaurar respaldo"
read -p "Elige opción [1-3]: " option

case $option in
    1) backup_daily ;;
    2) backup_weekly ;;
    3) restore_backup ;;
    *) echo "❌ Opción inválida" ;;
esac
