#!/bin/bash

# jipuk.sh - Script to download VPN configurations and convert them
# Usage: ./jipuk.sh

# Set output filenames
CONVERT_SCRIPT1="convertcombine.py"
CONVERT_SCRIPT2="convertxlcombine.py"
COMBINED_FILE="combined_proxies.yaml"
MAX_RETRIES=3

# Define VPN configurations to download - Using arrays instead of associative arrays
OUTPUT_FILES=(
  "ambil.yaml"
  "ambil2.yaml"
  "ambil3.yaml"
  "ambil4.yaml"
  "ambil5.yaml"
  "ambil6.yaml"
  "ambil7.yaml"
  "ambil8.yaml"
  "ambil9.yaml"
  "ambil10.yaml"
)

URLS=(
  "https://nautica.foolvpn.me/api/v1/sub/?cc=SG&format=clash&limit=20&vpn=trojan,vless&port=443&domain=104.17.72.206"
  "https://prod-test.jdevcloud.com/api/vless?cc=id&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=20&format=clash-provider"
  "https://prod-test.jdevcloud.com/api/vless?cc=sg&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=20&format=clash-provider"
  "https://prod-test.jdevcloud.com/api/vless?cc=il&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=20&format=clash-provider"
  "https://prod-test.jdevcloud.com/api/vless?cc=jp&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=20&format=clash-provider"
  "https://prod-test.jdevcloud.com/api/vless?cc=my&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=20&format=clash-provider"
  "https://prod-test.jdevcloud.com/api/vless?cc=au&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=20&format=clash-provider"
  "https://prod-test.jdevcloud.com/api/vless?cc=gb&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=30&format=clash-provider"
  "https://prod-test.jdevcloud.com/api/vless?cc=hk&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=30&format=clash-provider"
  "https://prod-test.jdevcloud.com/api/vless?cc=ru&cdn=true&tls=true&bug=104.17.3.81&subdomain=zoomcares.gov&limit=30&format=clash-provider"
)

# Define multiple user agents
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/120.0.2210.144"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Brave Chrome/120.0.6099.217 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Brave Chrome/120.0.6099.217 Safari/537.36"
    "Mozilla/5.0 (Linux; Android 11; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.144 Mobile Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Mobile/15E148 Safari/604.1"
)

# Display banner
echo "====================================="
echo "VPN Configuration Download Utility"
echo "====================================="

# Check prerequisites
for cmd in python3 wget; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required but not installed."
        [[ $cmd == "wget" ]] && echo "Install with: brew install wget"
        exit 1
    fi
done

# Check if conversion scripts exist
script1_exists=false
script2_exists=false
for script in "$CONVERT_SCRIPT1" "$CONVERT_SCRIPT2"; do
    if [ -f "$script" ]; then
        [[ $script == "$CONVERT_SCRIPT1" ]] && script1_exists=true
        [[ $script == "$CONVERT_SCRIPT2" ]] && script2_exists=true
    else
        echo "Warning: $script not found in current directory."
    fi
done

if [ "$script1_exists" = false ] && [ "$script2_exists" = false ]; then
    echo "Error: No conversion scripts found. At least one is required."
    exit 1
fi

# Function to download a file with retries
download_file() {
    local output_file=$1
    local url=$2
    local retry_count=0
    local download_success=false
    local description=$3
    
    echo "Downloading ${description:-VPN configuration}..."
    
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success" = false ]; do
        echo "Download attempt $(($retry_count + 1))/$MAX_RETRIES..."
        
        # Select a random user agent
        local random_index=$((RANDOM % ${#USER_AGENTS[@]}))
        local selected_user_agent="${USER_AGENTS[$random_index]}"
        echo "Using agent: ${selected_user_agent:0:30}..."
        
        # Download the file
        wget --quiet --user-agent="$selected_user_agent" --output-document="$output_file" "$url"
        
        if [ $? -eq 0 ] && [ -s "$output_file" ]; then
            download_success=true
            echo "✓ Download successful! File saved as $output_file ($(du -h "$output_file" | cut -f1))"
            
            # Check if the file is a valid YAML
            if python3 -c "import yaml; yaml.safe_load(open('$output_file'))" &> /dev/null; then
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
    
    if [ "$download_success" = false ]; then
        echo "✗ Error: Failed to download the file."
        [ -f "$output_file" ] && rm "$output_file"  # Clean up empty file if it exists
        return 1
    fi
    
    return 0
}

# Download all VPN configurations
download_results=()
primary_success=false

for i in "${!OUTPUT_FILES[@]}"; do
    output_file="${OUTPUT_FILES[$i]}"
    url="${URLS[$i]}"
    
    # Get country code from URL
    country=$(echo "$url" | grep -o 'cc=[a-z][a-z]' | cut -c4- | tr '[:lower:]' '[:upper:]' || echo "")
    
    # Set description based on country
    description="${country:-Primary} VPN configuration"
    
    if download_file "$output_file" "$url" "$description"; then
        download_results[$i]=true
        [ "$output_file" = "ambil.yaml" ] && primary_success=true
    else
        download_results[$i]=false
    fi
done

# Process the downloaded files if primary download was successful
if [ "$primary_success" = true ]; then
    # Create combined proxy file with URL test group
    echo "Creating combined proxy configuration..."
    
    # Convert bash array to Python list string
    py_files_list="["
    for file in "${OUTPUT_FILES[@]}"; do
        py_files_list+="\"$file\", "
    done
    py_files_list="${py_files_list%, }]"  # Remove trailing comma and space, then close bracket
    
    # Create Python script to combine proxies and add URL test group
    cat > combine_proxies.py << EOF
import yaml
import os
import sys

# Files to process (automatically generated from OUTPUT_FILES array)
files = $py_files_list
output_file = "$COMBINED_FILE"

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
        
        # Wait for 5 seconds
        echo "Waiting for 5 seconds before conversion..."
        sleep 5
        
        # Handle conversion scripts
        run_conversion_script() {
            local script=$1
            echo "Running $script..."
            if python3 "$script"; then
                echo "✓ Conversion with $script completed successfully!"
                return 0
            else
                echo "✗ Error: Conversion with $script failed."
                return 1
            fi
        }
        
        if [ "$script1_exists" = true ] && [ "$script2_exists" = true ]; then
            echo "Select conversion script to run:"
            echo "1) $CONVERT_SCRIPT1"
            echo "2) $CONVERT_SCRIPT2"
            echo "3) Run both scripts"
            echo "4) Cancel - exit without conversion"
            read -p "Enter your choice (1-4): " script_choice
            
            case "$script_choice" in
                1) run_conversion_script "$CONVERT_SCRIPT1" ;;
                2) run_conversion_script "$CONVERT_SCRIPT2" ;;
                3) 
                    run_conversion_script "$CONVERT_SCRIPT1"
                    run_conversion_script "$CONVERT_SCRIPT2"
                    ;;
                4)
                    echo "Operation canceled by user."
                    echo "Downloaded file ambil.yaml remains unchanged."
                    exit 0
                    ;;
                *)
                    echo "Invalid choice. Running default script $CONVERT_SCRIPT1..."
                    run_conversion_script "$CONVERT_SCRIPT1"
                    ;;
            esac
        elif [ "$script1_exists" = true ]; then
            run_conversion_script "$CONVERT_SCRIPT1"
        elif [ "$script2_exists" = true ]; then
            run_conversion_script "$CONVERT_SCRIPT2"
        fi
    else
        echo "✗ Error: Failed to create combined proxy configuration."
        exit 1
    fi
else
    echo "✗ Error: Failed to download the primary file."
    exit 1
fi

echo "====================================="
echo "Process completed"
echo "====================================="