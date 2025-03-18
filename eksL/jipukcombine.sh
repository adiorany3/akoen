#!/bin/bash

# jipuk.sh - Script to download VPN configuration and convert it using conversion scripts
# Usage: ./jipuk.sh

# Set output filename
OUTPUT_FILE="ambil.yaml"
OUTPUT_FILE2="ambil2.yaml"  # Added Indonesia proxy output file
OUTPUT_FILE3="ambil3.yaml"  # Added Singapore proxy output file
OUTPUT_FILE4="ambil4.yaml"  # Added Israel proxy output file
OUTPUT_FILE5="ambil5.yaml"  # Added Japan proxy output file
CONVERT_SCRIPT1="convertcombine.py"
CONVERT_SCRIPT2="convertxlcombine.py"

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

# Download the first file with retries
echo "Downloading primary VPN configuration..."
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

# Download the second file from the API
echo "Downloading secondary VPN configuration from API..."
retry_count=0
download_success2=false

while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success2" = false ]; do
    echo "Download attempt $(($retry_count + 1))/$MAX_RETRIES..."
    
    # Select a random user agent
    random_index=$((RANDOM % ${#USER_AGENTS[@]}))
    selected_user_agent="${USER_AGENTS[$random_index]}"
    echo "Using user agent: ${selected_user_agent:0:30}..."

    # Use the randomly selected user agent
    wget --quiet --user-agent="$selected_user_agent" \
         --output-document="$OUTPUT_FILE2" \
         "https://prod-test.jdevcloud.com/api/vless?cc=id&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=50&format=clash-provider"
    
    if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE2" ]; then
        download_success2=true
        echo "✓ Secondary VPN configuration download successful! File saved as $OUTPUT_FILE2"
        echo "✓ File size: $(du -h "$OUTPUT_FILE2" | cut -f1)"
        
        # Check if the file is a valid YAML
        if python3 -c "import yaml; yaml.safe_load(open('$OUTPUT_FILE2'))" &> /dev/null; then
            echo "✓ File validated as proper YAML format"
        else
            echo "⚠️ Warning: Downloaded file may not be valid YAML, but will continue processing."
        fi
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            echo "Download failed. Retrying in 5 seconds..."
            sleep 5
        fi
    fi
done

if [ "$download_success2" = false ]; then
    echo "✗ Error: Failed to download the secondary file."
    [ -f "$OUTPUT_FILE2" ] && rm "$OUTPUT_FILE2"  # Clean up empty file if it exists
fi

# Download the third file - Singapore proxy configuration
echo "Downloading Singapore VPN configuration..."
retry_count=0
download_success3=false

while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success3" = false ]; do
    echo "Download attempt $(($retry_count + 1))/$MAX_RETRIES..."
    
    # Select a random user agent
    random_index=$((RANDOM % ${#USER_AGENTS[@]}))
    selected_user_agent="${USER_AGENTS[$random_index]}"
    echo "Using user agent: ${selected_user_agent:0:30}..."

    # Use the randomly selected user agent
    wget --quiet --user-agent="$selected_user_agent" \
         --output-document="$OUTPUT_FILE3" \
         "https://prod-test.jdevcloud.com/api/vless?cc=sg&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=300&format=clash-provider"
    
    if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE3" ]; then
        download_success3=true
        echo "✓ Singapore VPN configuration download successful! File saved as $OUTPUT_FILE3"
        echo "✓ File size: $(du -h "$OUTPUT_FILE3" | cut -f1)"
        
        # Check if the file is a valid YAML
        if python3 -c "import yaml; yaml.safe_load(open('$OUTPUT_FILE3'))" &> /dev/null; then
            echo "✓ File validated as proper YAML format"
        else
            echo "⚠️ Warning: Downloaded file may not be valid YAML, but will continue processing."
        fi
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            echo "Download failed. Retrying in 5 seconds..."
            sleep 5
        fi
    fi
done

if [ "$download_success3" = false ]; then
    echo "✗ Error: Failed to download the Singapore proxy configuration."
    [ -f "$OUTPUT_FILE3" ] && rm "$OUTPUT_FILE3"  # Clean up empty file if it exists
fi

# Download the fourth file - Israel proxy configuration
echo "Downloading Israel VPN configuration..."
retry_count=0
download_success4=false

while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success4" = false ]; do
    echo "Download attempt $(($retry_count + 1))/$MAX_RETRIES..."
    
    # Select a random user agent
    random_index=$((RANDOM % ${#USER_AGENTS[@]}))
    selected_user_agent="${USER_AGENTS[$random_index]}"
    echo "Using user agent: ${selected_user_agent:0:30}..."

    # Use the randomly selected user agent
    wget --quiet --user-agent="$selected_user_agent" \
         --output-document="$OUTPUT_FILE4" \
         "https://prod-test.jdevcloud.com/api/vless?cc=il&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=40&format=clash-provider"
    
    if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE4" ]; then
        download_success4=true
        echo "✓ Israel VPN configuration download successful! File saved as $OUTPUT_FILE4"
        echo "✓ File size: $(du -h "$OUTPUT_FILE4" | cut -f1)"
        
        # Check if the file is a valid YAML
        if python3 -c "import yaml; yaml.safe_load(open('$OUTPUT_FILE4'))" &> /dev/null; then
            echo "✓ File validated as proper YAML format"
        else
            echo "⚠️ Warning: Downloaded file may not be valid YAML, but will continue processing."
        fi
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            echo "Download failed. Retrying in 5 seconds..."
            sleep 5
        fi
    fi
done

if [ "$download_success4" = false ]; then
    echo "✗ Error: Failed to download the Israel proxy configuration."
    [ -f "$OUTPUT_FILE4" ] && rm "$OUTPUT_FILE4"  # Clean up empty file if it exists
fi

# Download the fifth file - Japan proxy configuration
echo "Downloading Japan VPN configuration..."
retry_count=0
download_success5=false

while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success5" = false ]; do
    echo "Download attempt $(($retry_count + 1))/$MAX_RETRIES..."
    
    # Select a random user agent
    random_index=$((RANDOM % ${#USER_AGENTS[@]}))
    selected_user_agent="${USER_AGENTS[$random_index]}"
    echo "Using user agent: ${selected_user_agent:0:30}..."

    # Use the randomly selected user agent
    wget --quiet --user-agent="$selected_user_agent" \
         --output-document="$OUTPUT_FILE5" \
         "https://prod-test.jdevcloud.com/api/vless?cc=jp&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=50&format=clash-provider"
    
    if [ $? -eq 0 ] && [ -s "$OUTPUT_FILE5" ]; then
        download_success5=true
        echo "✓ Japan VPN configuration download successful! File saved as $OUTPUT_FILE5"
        echo "✓ File size: $(du -h "$OUTPUT_FILE5" | cut -f1)"
        
        # Check if the file is a valid YAML
        if python3 -c "import yaml; yaml.safe_load(open('$OUTPUT_FILE5'))" &> /dev/null; then
            echo "✓ File validated as proper YAML format"
        else
            echo "⚠️ Warning: Downloaded file may not be valid YAML, but will continue processing."
        fi
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            echo "Download failed. Retrying in 5 seconds..."
            sleep 5
        fi
    fi
done

if [ "$download_success5" = false ]; then
    echo "✗ Error: Failed to download the Japan proxy configuration."
    [ -f "$OUTPUT_FILE5" ] && rm "$OUTPUT_FILE5"  # Clean up empty file if it exists
fi

# Process the downloaded file
if [ "$download_success" = true ]; then
    echo "✓ Primary download successful! File saved as $OUTPUT_FILE"
    echo "✓ File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    
    # Check if the file is a valid YAML
    if python3 -c "import yaml; yaml.safe_load(open('$OUTPUT_FILE'))" &> /dev/null; then
        echo "✓ File validated as proper YAML format"
        
        # Create combined proxy file with URL test group
        echo "Creating combined proxy configuration with URL test group..."
        COMBINED_FILE="combined_proxies.yaml"
        
        # Create Python script to combine proxies and add URL test group
        cat > combine_proxies.py << 'EOF'
import yaml
import os
import sys

# Files to process
files = ["ambil.yaml", "ambil2.yaml", "ambil3.yaml", "ambil4.yaml", "ambil5.yaml"]
output_file = "combined_proxies.yaml"

# Initialize combined structure
combined_data = {"proxies": [], "proxy-groups": []}
all_proxy_names = []

# Process each file if it exists
for file in files:
    if os.path.exists(file) and os.path.getsize(file) > 0:
        try:
            with open(file, 'r') as f:
                data = yaml.safe_load(f)
                
                # Extract proxies if they exist in standard format
                if data and "proxies" in data:
                    for proxy in data["proxies"]:
                        if "name" in proxy:
                            combined_data["proxies"].append(proxy)
                            all_proxy_names.append(proxy["name"])
                    print(f"Added {len(data['proxies'])} proxies from {file}")
                # Handle clash-provider format
                elif data and "providers" in data:
                    for provider_name, provider in data["providers"].items():
                        if "proxies" in provider:
                            for proxy in provider["proxies"]:
                                if "name" in proxy:
                                    combined_data["proxies"].append(proxy)
                                    all_proxy_names.append(proxy["name"])
                            print(f"Added {len(provider['proxies'])} proxies from provider in {file}")
        except Exception as e:
            print(f"Error processing {file}: {str(e)}")

# Create URL test proxy group
if all_proxy_names:
    url_test_group = {
        "name": "🚀 Auto Select",
        "type": "url-test",
        "proxies": all_proxy_names,
        "url": "http://www.gstatic.com/generate_204",
        "interval": 300,  # Test every 300 seconds
        "tolerance": 50   # 50ms tolerance
    }
    
    # Create select group with all proxies
    select_group = {
        "name": "🌐 Manual Select",
        "type": "select",
        "proxies": ["🚀 Auto Select"] + all_proxy_names
    }
    
    # Add proxy groups
    combined_data["proxy-groups"] = [url_test_group, select_group]
    
    # Write combined data to output file
    with open(output_file, 'w') as f:
        yaml.dump(combined_data, f, sort_keys=False, allow_unicode=True)
    
    print(f"Successfully created {output_file} with {len(combined_data['proxies'])} total proxies")
    print(f"Added URL test group and select group with all proxies")
else:
    print("No proxies found in any of the files")
EOF
        
        # Run the Python script to combine proxies
        if python3 combine_proxies.py; then
            echo "✓ Combined proxy configuration created as $COMBINED_FILE"
            echo "✓ File size: $(du -h "$COMBINED_FILE" | cut -f1)"
            
            # Check if the file is a valid YAML
            if python3 -c "import yaml; yaml.safe_load(open('$COMBINED_FILE'))" &> /dev/null; then
                echo "✓ Combined file validated as proper YAML format"
            else
                echo "⚠️ Warning: Combined file may not be valid YAML."
            fi
        else
            echo "✗ Error: Failed to create combined proxy configuration."
        fi
        
        # Wait for 5 seconds
        echo "Waiting for 5 seconds before conversion..."
        sleep 5
        
        # Choose which conversion script to run
        if [ "$script1_exists" = true ] && [ "$script2_exists" = true ]; then
            echo "Select conversion script to run:"
            echo "1) $CONVERT_SCRIPT1"
            echo "2) $CONVERT_SCRIPT2"
            echo "3) Run both scripts"
            echo "4) Cancel - exit without conversion"
            read -p "Enter your choice (1-4): " script_choice
            
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
                4)
                    echo "Operation canceled by user."
                    echo "Downloaded file $OUTPUT_FILE remains unchanged."
                    exit 0
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