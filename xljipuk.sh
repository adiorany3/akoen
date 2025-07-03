#!/bin/bash

# Script to download VPN configuration and save as ambil.yaml
# Version: 2.0 - Enhanced with better error handling and validation

set -e  # Exit on any error
trap 'echo "Error occurred at line $LINENO. Exit code: $?" >&2' ERR

# Configuration
OUTPUT_FILE="ambil.yaml"
BACKUP_FILE="${OUTPUT_FILE}.backup"
API_URL="https://nautica.foolvpn.me/api/v1/sub/?cc=ID&format=clash&limit=10&vpn=trojan,vless&port=443&domain=104.17.72.206"

echo "=== VPN Configuration Downloader v2.0 ==="
echo "Target file: $OUTPUT_FILE"

# Backup existing file if it exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Backing up existing file to $BACKUP_FILE"
    cp "$OUTPUT_FILE" "$BACKUP_FILE"
fi

echo "Downloading VPN configuration from API..."

# Download with proper SSL verification and error handling
if ! curl -f -s --ssl-reqd --connect-timeout 30 --max-time 60 \
    --user-agent "VPNDownloader/2.0" \
    "$API_URL" -o "$OUTPUT_FILE"; then
    echo "Error: Failed to download configuration from API"
    # Restore backup if download failed and backup exists
    if [ -f "$BACKUP_FILE" ]; then
        echo "Restoring backup file..."
        mv "$BACKUP_FILE" "$OUTPUT_FILE"
    fi
    exit 1
fi

# Check if download was successful and file is not empty
if [ ! -s "$OUTPUT_FILE" ]; then
    echo "Error: Downloaded file is empty"
    # Restore backup if available
    if [ -f "$BACKUP_FILE" ]; then
        echo "Restoring backup file..."
        mv "$BACKUP_FILE" "$OUTPUT_FILE"
    fi
    exit 1
fi

echo "Download successful! File saved as $OUTPUT_FILE"
echo "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"

# Enhanced YAML validation for Clash configuration
echo "Validating Clash configuration..."
if grep -q -E "^(mixed-port|port|socks-port|allow-lan|mode|log-level):" "$OUTPUT_FILE" && \
   grep -q -E "^(proxies|proxy-groups|rules):" "$OUTPUT_FILE"; then
    echo "✅ File appears to be valid Clash configuration"
    
    # Show basic stats
    PROXY_COUNT=$(grep -c "^  - name:" "$OUTPUT_FILE" 2>/dev/null || echo "0")
    echo "📊 Found $PROXY_COUNT proxy configurations"
else
    echo "⚠️  Warning: File might not be a valid Clash configuration"
    echo "First 5 lines of file:"
    head -5 "$OUTPUT_FILE"
fi

# Wait for 5 seconds with countdown
echo "Waiting 5 seconds before conversion..."
for i in {5..1}; do
    echo -n "$i... "
    sleep 1
done
echo "0"

# Check if conversion script exists and run it
CONVERT_SCRIPT="convertxl.py"
if [ -f "$CONVERT_SCRIPT" ]; then
    echo "Running conversion script: $CONVERT_SCRIPT"
    
    # Run Python script with proper error handling
    if python3 "$CONVERT_SCRIPT"; then
        echo "✅ Conversion completed successfully"
        # Remove backup file only if conversion successful
        [ -f "$BACKUP_FILE" ] && rm "$BACKUP_FILE"
    else
        echo "❌ Error: Conversion script failed"
        # Restore backup if conversion failed
        if [ -f "$BACKUP_FILE" ]; then
            echo "Restoring original file due to conversion failure..."
            mv "$BACKUP_FILE" "$OUTPUT_FILE"
        fi
        exit 1
    fi
else
    echo "⚠️  Warning: $CONVERT_SCRIPT not found, skipping conversion"
    echo "Available Python files:"
    find . -name "*.py" -type f | head -5
    # Keep backup file as conversion was skipped
fi

echo "🎉 Process completed successfully!"