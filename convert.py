import yaml
import os

def convert_ambil_to_byurule():
    # Check if required files exist
    if not os.path.exists('ambil.yml'):
        print("Error: ambil.yml file not found")
        return False
        
    if not os.path.exists('byurule.yaml'):
        print("Error: byurule.yaml file (template) not found")
        return False
    
    try:
        # Read ambil.yml
        with open('ambil.yml', 'r') as file:
            ambil_data = yaml.safe_load(file)
        
        # Read byurule.yaml to understand its format
        with open('byurule.yaml', 'r') as file:
            byurule_template = yaml.safe_load(file)
        
        # Create new data structure based on byurule format
        new_data = {}
        
        # Copy top-level keys that exist in both files
        for key in byurule_template:
            if key in ambil_data:
                new_data[key] = ambil_data[key]
            else:
                new_data[key] = byurule_template[key]
        
        # Remove template and configuration entries
        keys_to_remove = [
            'uuid', 'password', 'vless_host', 'trojan_host', 'path', 
            'path_trojan', 'vmess_uuid', 'vmess_host', 'vmess_path',
            'vless-template', 'trojan-template', 'vmess-template'
        ]
        
        for key in keys_to_remove:
            if key in new_data:
                del new_data[key]
        
        # Keep track of proxy names for load balancing
        proxy_names = []
        
        # Special transformations - update server values
        if 'proxies' in new_data:
            # Define new server IPs
            new_server_ips = ['104.22.21.245', '172.67.74.70', '104.19.143.108']
            ip_index = 0
            
            # Update server values in all proxies
            for proxy in new_data['proxies']:
                # Check if the current proxy has the old server IP
                if proxy.get('server') == '104.17.72.206':
                    # Assign one of the new IPs and rotate through them
                    proxy['server'] = new_server_ips[ip_index]
                    ip_index = (ip_index + 1) % len(new_server_ips)
                
                # Convert port from string to integer (remove quotes)
                if 'port' in proxy and proxy['port'] == '443':
                    proxy['port'] = 443
                
                # Collect proxy names for load balancing
                if 'name' in proxy:
                    proxy_names.append(proxy['name'])
        
        # Add load balancing configuration
        # Create proxy groups for load balancing
        new_data['proxy-groups'] = [
            {
                'name': 'LoadBalance',
                'type': 'load-balance',
                'strategy': 'round-robin',
                'url': 'http://www.gstatic.com/generate_204',
                'interval': 300,
                'proxies': proxy_names
            },
            {
                'name': 'UrlTest',
                'type': 'url-test',
                'url': 'http://www.gstatic.com/generate_204',
                'interval': 300,
                'tolerance': 50,
                'proxies': proxy_names
            },
            {
                'name': 'PROXY',
                'type': 'select',
                'proxies': ['LoadBalance', 'UrlTest'] + proxy_names
            }
        ]
        
        # Add rules if not present
        if 'rules' not in new_data:
            new_data['rules'] = ['MATCH,PROXY']
        
        # Write to newbyurule.yaml
        with open('newbyurule.yaml', 'w') as file:
            yaml.dump(new_data, file, default_flow_style=False, sort_keys=False)
        
        print("Successfully converted ambil.yml to newbyurule.yaml with load balancing")
        return True
    
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        return False

if __name__ == "__main__":
    convert_ambil_to_byurule()

# To install the required package, run:
# pip install pyyaml