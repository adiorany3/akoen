import yaml
import os
import time

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
        # Starting with the template structure
        new_data = {}
        
        # Copy top-level keys that exist in both files
        for key in byurule_template:
            if key in ambil_data:
                new_data[key] = ambil_data[key]
            else:
                new_data[key] = byurule_template[key]
        
        # Special transformations - update server values
        proxy_names = []
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
                
                # Store proxy names for load balancing groups
                if 'name' in proxy:
                    proxy_names.append(proxy['name'])
        
        # Add load balancing proxy groups
        if proxy_names and 'proxy-groups' not in new_data:
            new_data['proxy-groups'] = []
        
        # Create load balance group
        loadbalance_group = {
            'name': 'LoadBalance',
            'type': 'load-balance',
            'strategy': 'round-robin',  # Options: round-robin, consistent-hashing
            'url': 'http://www.gstatic.com/generate_204',
            'interval': 300,
            'proxies': proxy_names
        }
        
        # Create fallback group
        urltest_group = {
            'name': 'Auto',
            'type': 'url-test',
            'url': 'http://www.gstatic.com/generate_204',
            'interval': 300,
            'tolerance': 50,
            'proxies': proxy_names
        }
        
        # Create selector group
        selector_group = {
            'name': 'Proxy',
            'type': 'select',
            'proxies': ['Auto', 'LoadBalance'] + proxy_names
        }
        
        # Add the groups
        if 'proxy-groups' in new_data:
            new_data['proxy-groups'] = [selector_group, loadbalance_group, urltest_group]
        
        # Make sure we have some basic rules
        if 'rules' not in new_data:
            new_data['rules'] = [
                'MATCH,Proxy'
            ]
        
        # Wait for 5 seconds before writing
        time.sleep(5)
        
        # Write to newbyurule.yaml
        with open('newbyurule.yaml', 'w') as file:
            yaml.dump(new_data, file, default_flow_style=False, sort_keys=False)
        
        print("Successfully converted ambil.yml to newbyurule.yaml based on byurule.yaml format with load balancing")
        return True
    
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        return False

if __name__ == "__main__":
    convert_ambil_to_byurule()

# To install the required package, run:
# pip install pyyaml