#!/bin/bash

# Definición de variables predeterminadas
MAX_ATTEMPTS=3
CURRENT_LINE=0

# Función para mostrar el uso del script
show_usage() {
    echo "Uso: $0 --archivo=<archivo_sql> --usuario=<usuario> --contraseña=<contraseña> --host=<host_basedatos> --basedatos=<nombre_basedatos>"
}

# Función para mostrar la barra de progreso
show_progress() {
    local -i porcentaje=$((100 * $1 / $2))
    local caracter_vacio="."
    local caracter_lleno="█"
    local barra_progreso=""

    for i in $(seq 1 50); do
        if [ $i -le $((porcentaje / 2)) ]; then
            barra_progreso="$barra_progreso$caracter_lleno"
        else
            barra_progreso="$barra_progreso$caracter_vacio"
        fi
    done
    printf "Ejecutando línea %s de %s. Progreso: %s%% %s\r" $1 $2 $porcentaje "$barra_progreso"
}

# Parseo de argumentos
for arg in "$@"; do
    case $arg in
    --archivo=*)
        SQL_FILE="${arg#*=}"
        shift
        ;;
    --usuario=*)
        USER="${arg#*=}"
        shift
        ;;
    --contraseña=*)
        PASSWORD="${arg#*=}"
        shift
        ;;
    --host=*)
        HOST="${arg#*=}"
        shift
        ;;
    --basedatos=*)
        DATABASE="${arg#*=}"
        shift
        ;;
    *)
        show_usage
        exit 1
        ;;
    esac
done

# Verificación de los argumentos
if [[ -z $SQL_FILE || -z $USER || -z $PASSWORD || -z $HOST || -z $DATABASE ]]; then
    echo "Todos los argumentos son obligatorios."
    show_usage
    exit 1
fi

LINE_COUNT=$(wc -l <"$SQL_FILE")

# Leer el archivo SQL línea por línea
while IFS= read -r line; do
    # Bucle para realizar los intentos
    attempts=0
    while [ $attempts -lt $MAX_ATTEMPTS ]; do
        ((attempts++))

        # Ejecuta la línea SQL
        echo "$line" | mysql -u $USER -p$PASSWORD -h $HOST $DATABASE >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            ((CURRENT_LINE++))
            show_progress $CURRENT_LINE $LINE_COUNT
            break
        else
            echo "Error al ejecutar la línea SQL."
            if [ $attempts -lt $MAX_ATTEMPTS ]; then
                echo "Reintentando en 5 segundos..."
                sleep 5
            else
                echo "Se alcanzó el número máximo de intentos. Por favor, revise la línea SQL y los errores mostrados."
                exit 1
            fi
        fi
    done
done <"$SQL_FILE"

echo # Nueva línea al final para mantener la salida limpia
