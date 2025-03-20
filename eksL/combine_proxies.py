import yaml
import os
import sys

# Files to process (automatically generated from OUTPUT_FILES array)
files = ["ambil.yaml", "ambil2.yaml", "ambil3.yaml", "ambil4.yaml", "ambil5.yaml", "ambil6.yaml", "ambil7.yaml", "ambil8.yaml", "ambil9.yaml", "ambil10.yaml", "ambil11.yaml", "ambil12.yaml", "ambil13.yaml", "ambil14.yaml", "ambil15.yaml", "ambil16.yaml", "ambil17.yaml", "ambil18.yaml", "ambil19.yaml", "ambil20.yaml", "ambil21.yaml"]
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
