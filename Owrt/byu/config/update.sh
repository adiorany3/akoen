#!/bin/bash

# URL file yang akan diunduh
URL="https://raw.githubusercontent.com/adiorany3/akoen/refs/heads/main/newbyurule.yaml"

# Lokasi penyimpanan file
OUTPUT_FILE="newbyurule.yaml"

# Mengunduh file menggunakan wget
echo "Mengunduh file dari $URL..."
wget -O "$OUTPUT_FILE" "$URL"

# Memeriksa apakah unduhan berhasil
if [ $? -eq 0 ]; then
    echo "File berhasil diunduh dan disimpan sebagai $OUTPUT_FILE"
    
    # Menunggu 5 detik
    echo "Menunggu 5 detik sebelum menjalankan time.sh..."
    sleep 5

    # Menjalankan time.sh
    echo "Menjalankan time.sh..."
    ./time.sh
    
    # Menunggu selama 5 detik
    echo "Menunggu 5 detik sebelum merestart OpenClash..."
    sleep 5
    
    # Menjalankan perintah restart OpenClash
    /etc/init.d/openclash restart 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "OpenClash berhasil direstart."
    else
        echo "Gagal merestart OpenClash."
    fi
else
    echo "Gagal mengunduh file."
fi