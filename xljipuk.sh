#!/bin/bash

# Script to download VPN configuration and save as ambil.yaml
echo "Downloading VPN configuration..."

# Download the file from the specified URL and save as ambil.yaml
curl -s --connect-timeout 30 --max-time 60 "https://nautica.foolvpn.me/api/v1/sub/?cc=ID&format=clash&limit=10&vpn=trojan,vless&port=443&domain=104.17.72.206" > ambil.yaml

# Check if download was successful
if [ $? -eq 0 ] && [ -s ambil.yaml ]; then
    echo "Download successful! File saved as ambil.yaml"
    echo "File size: $(du -h ambil.yaml | cut -f1)"
    
    # Validate if file contains valid YAML content
    if head -1 ambil.yaml | grep -q "^mixed-port\|^port\|^socks-port"; then
        echo "File appears to be valid Clash configuration"
    else
        echo "Warning: File might not be a valid Clash configuration"
    fi
    
    # Wait for 5 seconds
    echo "Waiting for 5 seconds before conversion..."
    sleep 5
    
    # Check if conversion script exists
    if [ -f "convertxl.py" ]; then
        # Run the Python conversion script
        echo "Running conversion script..."
        python3 convertxl.py
    else
        echo "Warning: convertxl.py not found, skipping conversion."
    fi
else
    echo "Error: Failed to download the file or file is empty."
    exit 1
fi