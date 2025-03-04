#!/bin/bash

# Pastikan script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo "Script ini harus dijalankan sebagai root."
    exit 1
fi

# Ambil header Date dari server
nistTime=$(curl -I --silent --insecure 'https://www.telkomsel.com/' | grep -i "Date:")

# Periksa apakah header Date ditemukan
if [ -z "$nistTime" ]; then
    echo "Gagal mendapatkan waktu dari server."
    exit 1
fi

# Proses string waktu
dateString=$(echo "$nistTime" | cut -d' ' -f2-7)
dayString=$(echo "$dateString" | cut -d' ' -f1)
dateValue=$(echo "$dateString" | cut -d' ' -f2)
monthValue=$(echo "$dateString" | cut -d' ' -f3)
yearValue=$(echo "$dateString" | cut -d' ' -f4)
timeValue=$(echo "$dateString" | cut -d' ' -f5)

# Konversi nama bulan ke angka
case $monthValue in
    "Jan") monthValue="01" ;;
    "Feb") monthValue="02" ;;
    "Mar") monthValue="03" ;;
    "Apr") monthValue="04" ;;
    "May") monthValue="05" ;;
    "Jun") monthValue="06" ;;
    "Jul") monthValue="07" ;;
    "Aug") monthValue="08" ;;
    "Sep") monthValue="09" ;;
    "Oct") monthValue="10" ;;
    "Nov") monthValue="11" ;;
    "Dec") monthValue="12" ;;
    *) 
        echo "Format bulan tidak dikenali."
        exit 1
        ;;
esac

# Format waktu untuk perintah date
formattedDate="$yearValue.$monthValue.$dateValue-$timeValue"

# Perbarui waktu sistem
echo "Memperbarui waktu sistem ke: $formattedDate"
date --utc --set="$formattedDate"

# Periksa status
if [ $? -eq 0 ]; then
    echo "Waktu sistem berhasil diperbarui."
else
    echo "Gagal memperbarui waktu sistem."
    exit 1
fi