#!/bin/bash

# Script to download VPN configuration and save as ambil.yml
echo "Downloading VPN configuration..."

# Download the file from the specified URL and save as ambil.yml
curl -s "https://nautica.foolvpn.me/api/v1/sub/?cc=ID&format=clash&limit=10&vpn=trojan,vless&port=443&domain=104.17.72.206" > ambil.yml

# Check if download was successful
if [ $? -eq 0 ] && [ -s ambil.yml ]; then
    echo "Download successful! File saved as ambil.yml"
    echo "File size: $(du -h ambil.yml | cut -f1)"
    
    # Wait for 5 seconds
    echo "Waiting for 5 seconds before conversion..."
    sleep 5
    
    # Run the Python conversion script
    echo "Running conversion script..."
    python3 convert.py
else
    echo "Error: Failed to download the file or file is empty."
    exit 1
fi