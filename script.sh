#!/bin/bash

# Пути к инструментам
SYFT="./syft"
GRYPE="./grype"

# Каталог с .so файлами
TARGET_DIR="./"

# Каталоги для результатов
RESULTS_DIR="./results"
SBOM_DIR="./sboms"

mkdir -p "$RESULTS_DIR"
mkdir -p "$SBOM_DIR"

for file in "$TARGET_DIR"/*.so; do
    [ -f "$file" ] || continue

    filename=$(basename "$file")
    name="${filename%.so}"

    result="$RESULTS_DIR/${name}.txt"
    sbom="$SBOM_DIR/${name}.json"

    echo "[+] Processing: $filename"

    # Генерация SBOM
    echo "[+] Generating SBOM..."
    "$SYFT" "$file" -o syft-json > "$sbom"

    if [ $? -ne 0 ]; then
        echo "[!] Syft failed for $filename"
        echo "Syft failed" > "$result"
        continue
    fi

    # Сканирование SBOM через Grype
    echo "[+] Running Grype..."
    "$GRYPE" "sbom:$sbom" > "$result"

    if [ $? -ne 0 ]; then
        echo "[!] Grype failed for $filename"
        continue
    fi

    echo "[+] Done:"
    echo "    SBOM:   $sbom"
    echo "    Result: $result"
    echo
done

echo "[+] All files processed."