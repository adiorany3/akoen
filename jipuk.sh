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

# Check if convert.py exists
if [ ! -f "$CONVERT_SCRIPT" ]; then
    echo "Error: $CONVERT_SCRIPT not found in current directory."
    exit 1
fi

# Download the file from the specified URL
echo "Downloading VPN configuration..."
curl -s -f "https://nautica.foolvpn.me/api/v1/sub/?cc=ID&format=clash&limit=10&vpn=trojan,vless&port=443&domain=104.17.72.206" -o "$OUTPUT_FILE"

# Check if download was successful
if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE" ]; then
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