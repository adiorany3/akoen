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
        
        # Create new data structure with only essential elements
        new_data = {}
        
        # Define essential keys to keep from the template
        essential_keys = [
            'port', 'socks-port', 'redir-port', 'mixed-port', 'tproxy-port', 
            'ipv6', 'mode', 'log-level', 'allow-lan', 'external-controller',
            'secret', 'bind-address', 'unified-delay', 'profile', 'general', 'dns'
        ]
        
        # Copy only essential keys
        for key in essential_keys:
            if key in byurule_template:
                new_data[key] = byurule_template[key]
        
        # Copy proxies from ambil_data
        if 'proxies' in ambil_data:
            new_data['proxies'] = ambil_data['proxies']
        
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
        
        # Write to newbyurule.yaml
        with open('newbyurule.yaml', 'w') as file:
            yaml.dump(new_data, file, default_flow_style=False, sort_keys=False)
        
        print("Successfully converted ambil.yml to newbyurule.yaml with clean format")
        return True
    
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        return False

if __name__ == "__main__":
    convert_ambil_to_byurule()

# To install the required package, run:
# pip install pyyaml