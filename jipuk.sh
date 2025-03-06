#!/bin/bash

# jipuk.sh - Script to download VPN configuration and convert it using convert.py
# Usage: ./jipuk.sh

# Set output filename
OUTPUT_FILE="ambil.yaml"
CONVERT_SCRIPT="convert.py"

# Display banner
echo "====================================="
echo "VPN Configuration Download Utility"
echo "====================================="

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    exit 1
fi

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "Error: wget is required but not installed."
    echo "Install with: brew install wget"
    exit 1
fi

# Check if convert.py exists
if [ ! -f "$CONVERT_SCRIPT" ]; then
    echo "Error: $CONVERT_SCRIPT not found in current directory."
    exit 1
fi

# Download the file with retries
echo "Downloading VPN configuration..."
MAX_RETRIES=3
retry_count=0
download_success=false

while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success" = false ]; do
    echo "Download attempt $(($retry_count + 1))/$MAX_RETRIES..."

    echo "Checking if server is reachable..."
    if wget --spider --timeout=10 --quiet "https://nautica.foolvpn.me" 2>/dev/null; then
        echo "✓ Server is reachable"
        
        # Try with a user agent to avoid potential blocks
        wget --quiet --user-agent="Mozilla/5.0" \
             --output-document="$OUTPUT_FILE" \
             "https://nautica.foolvpn.me/api/v1/sub/?cc=ID&format=clash&limit=10&vpn=trojan,vless&port=443&domain=104.17.72.206"
        
        if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
            download_success=true
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                echo "Download failed. Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    else
        echo "✗ Error: Cannot reach the server."
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            echo "Retrying in 5 seconds..."
            sleep 5
        fi
    fi
done

# Rest of the script remains the same
if [ "$download_success" = true ]; then
    echo "✓ Download successful! File saved as $OUTPUT_FILE"
    echo "✓ File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    
    # Check if the file is a valid YAML
    if python3 -c "import yaml; yaml.safe_load(open('$OUTPUT_FILE'))" &> /dev/null; then
        echo "✓ File validated as proper YAML format"
        
        # Wait for 5 seconds
        echo "Waiting for 5 seconds before conversion..."
        sleep 5
        
        # Run the Python conversion script
        echo "Running conversion script..."
        if python3 "$CONVERT_SCRIPT"; then
            echo "✓ Conversion completed successfully!"
        else
            echo "✗ Error: Conversion failed."
            exit 1
        fi
    else
        echo "✗ Error: Downloaded file is not valid YAML."
        exit 1
    fi
else
    echo "✗ Error: Failed to download the file or file is empty."
    [ -f "$OUTPUT_FILE" ] && rm "$OUTPUT_FILE"  # Clean up empty file if it exists
    exit 1
fi

echo "====================================="
echo "Process completed"
echo "====================================="