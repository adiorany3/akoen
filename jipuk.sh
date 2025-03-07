#!/bin/bash

# jipuk.sh - Script to download VPN configuration and convert it using conversion scripts
# Usage: ./jipuk.sh

# Set output filename
OUTPUT_FILE="ambil.yaml"
CONVERT_SCRIPT1="convert.py"
CONVERT_SCRIPT2="convertxl.py"

# Define multiple user agents
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
)

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

# Check if conversion scripts exist
script1_exists=false
script2_exists=false

if [ -f "$CONVERT_SCRIPT1" ]; then
    script1_exists=true
else
    echo "Warning: $CONVERT_SCRIPT1 not found in current directory."
fi

if [ -f "$CONVERT_SCRIPT2" ]; then
    script2_exists=true
else
    echo "Warning: $CONVERT_SCRIPT2 not found in current directory."
fi

if [ "$script1_exists" = false ] && [ "$script2_exists" = false ]; then
    echo "Error: No conversion scripts found. At least one is required."
    exit 1
fi

# Download the file with retries
echo "Downloading VPN configuration..."
MAX_RETRIES=3
retry_count=0
download_success=false

while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success" = false ]; do
    echo "Download attempt $(($retry_count + 1))/$MAX_RETRIES..."
    
    # Select a random user agent
    random_index=$((RANDOM % ${#USER_AGENTS[@]}))
    selected_user_agent="${USER_AGENTS[$random_index]}"
    echo "Using user agent: ${selected_user_agent:0:30}..."

    echo "Checking if server is reachable..."
    if wget --spider --timeout=10 --quiet "https://nautica.foolvpn.me" 2>/dev/null; then
        echo "✓ Server is reachable"
        
        # Use the randomly selected user agent
        wget --quiet --user-agent="$selected_user_agent" \
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

# Process the downloaded file
if [ "$download_success" = true ]; then
    echo "✓ Download successful! File saved as $OUTPUT_FILE"
    echo "✓ File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    
    # Check if the file is a valid YAML
    if python3 -c "import yaml; yaml.safe_load(open('$OUTPUT_FILE'))" &> /dev/null; then
        echo "✓ File validated as proper YAML format"
        
        # Wait for 5 seconds
        echo "Waiting for 5 seconds before conversion..."
        sleep 5
        
        # Choose which conversion script to run
        if [ "$script1_exists" = true ] && [ "$script2_exists" = true ]; then
            echo "Select conversion script to run:"
            echo "1) $CONVERT_SCRIPT1"
            echo "2) $CONVERT_SCRIPT2"
            echo "3) Run both scripts"
            read -p "Enter your choice (1-3): " script_choice
            
            case "$script_choice" in
                1)
                    echo "Running $CONVERT_SCRIPT1..."
                    if python3 "$CONVERT_SCRIPT1"; then
                        echo "✓ Conversion with $CONVERT_SCRIPT1 completed successfully!"
                    else
                        echo "✗ Error: Conversion with $CONVERT_SCRIPT1 failed."
                        exit 1
                    fi
                    ;;
                2)
                    echo "Running $CONVERT_SCRIPT2..."
                    if python3 "$CONVERT_SCRIPT2"; then
                        echo "✓ Conversion with $CONVERT_SCRIPT2 completed successfully!"
                    else
                        echo "✗ Error: Conversion with $CONVERT_SCRIPT2 failed."
                        exit 1
                    fi
                    ;;
                3)
                    echo "Running both conversion scripts..."
                    
                    echo "Running $CONVERT_SCRIPT1..."
                    if python3 "$CONVERT_SCRIPT1"; then
                        echo "✓ Conversion with $CONVERT_SCRIPT1 completed successfully!"
                    else
                        echo "✗ Error: Conversion with $CONVERT_SCRIPT1 failed."
                    fi
                    
                    echo "Running $CONVERT_SCRIPT2..."
                    if python3 "$CONVERT_SCRIPT2"; then
                        echo "✓ Conversion with $CONVERT_SCRIPT2 completed successfully!"
                    else
                        echo "✗ Error: Conversion with $CONVERT_SCRIPT2 failed."
                    fi
                    ;;
                *)
                    echo "Invalid choice. Running default script $CONVERT_SCRIPT1..."
                    if python3 "$CONVERT_SCRIPT1"; then
                        echo "✓ Conversion with $CONVERT_SCRIPT1 completed successfully!"
                    else
                        echo "✗ Error: Conversion with $CONVERT_SCRIPT1 failed."
                        exit 1
                    fi
                    ;;
            esac
        elif [ "$script1_exists" = true ]; then
            echo "Running conversion script $CONVERT_SCRIPT1..."
            if python3 "$CONVERT_SCRIPT1"; then
                echo "✓ Conversion completed successfully!"
            else
                echo "✗ Error: Conversion failed."
                exit 1
            fi
        elif [ "$script2_exists" = true ]; then
            echo "Running conversion script $CONVERT_SCRIPT2..."
            if python3 "$CONVERT_SCRIPT2"; then
                echo "✓ Conversion completed successfully!"
            else
                echo "✗ Error: Conversion failed."
                exit 1
            fi
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