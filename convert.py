import yaml
import os
import requests

def convert_ambil_to_byurule(telegram_bot_token=None, telegram_chat_id=None):
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
                
                # Collect proxy names for fallback groups
                if 'name' in proxy:
                    proxy_names.append(proxy['name'])
        
        # Add fallback proxy group
        if proxy_names:
            new_data['proxy-groups'] = [
                {
                    'name': 'Fallback',
                    'type': 'fallback',
                    'url': 'http://www.gstatic.com/generate_204',
                    'interval': 300,
                    'proxies': proxy_names
                },
                {
                    'name': 'Selector',
                    'type': 'select',
                    'proxies': ['Fallback'] + proxy_names
                }
            ]
            
            # Add fallback rule
            new_data['rules'] = ['MATCH,Fallback']
        
        # Write to newbyurule.yaml
        with open('newbyurule.yaml', 'w') as file:
            yaml.dump(new_data, file, default_flow_style=False, sort_keys=False)
        
        print("Successfully converted ambil.yml to newbyurule.yaml with fallback mechanism")
        
        # Send to Telegram if credentials are provided
        if telegram_bot_token and telegram_chat_id:
            send_to_telegram(telegram_bot_token, telegram_chat_id, 'newbyurule.yaml')
        
        return True
    
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        return False

def send_to_telegram(bot_token, chat_id, file_path):
    """Send a file to a Telegram chat using Telegram Bot API"""
    try:
        url = f"https://api.telegram.org/bot{bot_token}/sendDocument"
        
        with open(file_path, 'rb') as file:
            files = {'document': file}
            data = {'chat_id': chat_id}
            
            response = requests.post(url, files=files, data=data)
            
            if response.status_code == 200:
                print(f"Successfully sent {file_path} to Telegram")
            else:
                print(f"Failed to send file to Telegram. Status code: {response.status_code}")
                print(f"Response: {response.text}")
    
    except Exception as e:
        print(f"Error sending file to Telegram: {str(e)}")

if __name__ == "__main__":
    # Enter your Telegram bot token and chat ID here
    BOT_TOKEN = "6560425395:AAHnNDWkKzqTpKUeeiH-XsGO2hF2poI9Reo"
    CHAT_ID = "28075319"
    
    convert_ambil_to_byurule(BOT_TOKEN, CHAT_ID)

# To install the required packages, run:
# pip install pyyaml requests