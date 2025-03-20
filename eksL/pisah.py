# cara pakai
# python3 pisah.py --trojan-output mycustom_trojan.yaml --vless-output mycustom_vless.yaml

import yaml, os, argparse, logging, sys, glob
from datetime import datetime
from pathlib import Path

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s',
                    handlers=[logging.StreamHandler(sys.stdout)])
logger = logging.getLogger(__name__)

# Server configurations
SERVER_CONFIGS = {
    "Bug1": {"ip": "172.67.5.14", "prefix": "Bug1-"},
    "Bug2": {"ip": "172.66.0.145", "prefix": "Bug2-"},
    "Bug3": {"ip": "104.22.5.240", "prefix": "Bug3-"},
    "Bug4": {"ip": "104.17.72.206", "prefix": "Bug4-"},
    "Bug5": {"ip": "104.17.155.243", "prefix": "Bug5-"},
    "RG": {"ip": "104.22.21.245", "prefix": "RG-"},
    "Ilped": {"ip": "172.67.74.70", "prefix": "Ilped-"},
    "GGWP": {"ip": "104.19.143.108", "prefix": "GGWP-"}
}

# Additional static proxies - IFLIX configs
def create_iflix_proxy(num, sni):
    """Create an IFLIX proxy with specific SNI domain"""
    return {
        "name": f"BUG-IFLIX {num}",
        "server": "sg-d6.2esge.web.id",
        "port": 443,
        "type": "trojan",
        "password": "f165d6d8-0552-4423-a0d8-3ab3f2ab3ee2",
        "network": "ws",
        "sni": f"{sni}.iflix.com",
        "skip-cert-verify": True,
        "udp": True,
        "ws-opts": {
            "path": "/trojan",
            "headers": {"Host": "sg-d6.2esge.web.id"}
        }
    }

# Define the IFLIX proxy configurations
ADDITIONAL_PROXIES = [
    create_iflix_proxy(1, "live"),
    create_iflix_proxy(2, "upload"),
    create_iflix_proxy(3, "vplay")
]

# Helper function to get available ambil yaml files
def get_ambil_files():
    """Get all ambil*.yaml files in the current directory"""
    files = sorted(glob.glob("ambil*.yaml"))
    if files:
        logger.info(f"Found {len(files)} ambil files: {', '.join(files)}")
    else:
        logger.warning("No ambil*.yaml files found in current directory")
    return files

def generate_proxies(original_proxies, server_type, template_proxy):
    """Generate proxies for a specific server type"""
    if server_type not in SERVER_CONFIGS:
        logger.error(f"Unknown server type: {server_type}")
        return [], []
    
    config = SERVER_CONFIGS[server_type]
    proxies, names = [], []
    
    # Add regular proxies
    for original in original_proxies:
        new_proxy = original.copy()
        new_proxy['server'] = config["ip"]
        if 'name' in new_proxy:
            new_proxy['name'] = config["prefix"] + new_proxy['name']
            names.append(new_proxy['name'])
        if 'port' in new_proxy and new_proxy['port'] == '443':
            new_proxy['port'] = 443
        proxies.append(new_proxy)
    
    # Add dedicated proxy
    dedicated = template_proxy.copy()
    dedicated['name'] = f"{server_type} WS TLS"
    dedicated['server'] = config["ip"]
    proxies.append(dedicated)
    names.append(dedicated['name'])
    
    return proxies, names

def convert_ambil_to_byurule(input_files=None, template_file='combine.yaml', 
                           trojan_output='trojanakun.yaml', vless_output='vlessakun.yaml'):
    """Convert YAML input files to enhanced proxy configurations split by account type"""
    
    # Validate files
    if input_files is None:
        input_files = get_ambil_files()
    elif isinstance(input_files, str):
        input_files = [input_files]
        
    if not os.path.exists(template_file):
        logger.error(f"Template {template_file} not found")
        return False
    
    valid_input_files = [f for f in input_files if os.path.exists(f)]
    if not valid_input_files:
        logger.error("No valid input files found")
        return False
    
    try:
        # Read all input files and collect proxies
        all_proxies = []
        for input_file in valid_input_files:
            try:
                with open(input_file, 'r') as file:
                    data = yaml.safe_load(file)
                if not isinstance(data, dict) or 'proxies' not in data or not data['proxies']:
                    logger.warning(f"No valid proxies in {input_file}")
                    continue
                logger.info(f"Loaded {len(data['proxies'])} proxies from {input_file}")
                all_proxies.extend(data['proxies'])
            except Exception as e:
                logger.error(f"Error reading {input_file}: {str(e)}")
        
        if not all_proxies:
            logger.error("No proxies found in any input files")
            return False
        
        # Read template file
        with open(template_file, 'r') as file:
            template = yaml.safe_load(file)
        
        # Create new data structure template
        essential_keys = ['port', 'socks-port', 'redir-port', 'mixed-port', 'tproxy-port', 
                         'ipv6', 'mode', 'log-level', 'allow-lan', 'external-controller',
                         'secret', 'bind-address', 'unified-delay', 'profile', 'general', 'dns']
        
        # Separate proxies by type
        trojan_proxies = [p for p in all_proxies if p.get('type') == 'trojan']
        vless_proxies = [p for p in all_proxies if p.get('type') == 'vless']
        
        logger.info(f"Found {len(trojan_proxies)} Trojan proxies and {len(vless_proxies)} VLESS proxies")
        
        for proxy_type, proxies, output_file in [
            ('Trojan', trojan_proxies, trojan_output),
            ('VLESS', vless_proxies, vless_output)
        ]:
            if not proxies:
                logger.warning(f"No {proxy_type} proxies found, skipping {output_file}")
                continue
                
            # Create data structure for this proxy type
            new_data = {k: template[k] for k in essential_keys if k in template}
            new_data['external-ui'] = './dashboard'
            
            # Find template proxy for this type
            template_proxy = next((p.copy() for p in proxies 
                                 if all(k in p for k in ['server', 'port', 'name'])), None)
            if not template_proxy:
                logger.error(f"No suitable {proxy_type} proxy template found")
                continue
            
            # Generate proxies for each server
            new_data['proxies'] = []
            proxy_names = []
            server_names = {server: [] for server in SERVER_CONFIGS}
            
            for server_type in SERVER_CONFIGS:
                type_proxies, names = generate_proxies(proxies, server_type, template_proxy)
                new_data['proxies'].extend(type_proxies)
                proxy_names.extend(names)
                server_names[server_type] = names
            
            # Add additional static proxies if they match this type
            iflix_names = []
            for proxy in ADDITIONAL_PROXIES:
                if proxy.get('type') == proxies[0].get('type'):
                    new_data['proxies'].append(proxy)
                    proxy_names.append(proxy['name'])
                    iflix_names.append(proxy['name'])
            
            if iflix_names:
                logger.info(f"Added {len(iflix_names)} static BUG-IFLIX {proxy_type} proxies")
            
            # Add proxy groups
            if proxy_names:
                # Main groups
                new_data['proxy-groups'] = [
                    {
                        'name': 'Selector', 'type': 'select',
                        'proxies': ['Fallback', 'URL-Test', 'Load-Balance', 'Terbaik', 'IFLIX', 
                                   'Bug1', 'Bug2', 'Bug3', 'Bug4', 'Bug5', 'RG', 'Ilped', 'GGWP'] + proxy_names
                    },
                    {
                        'name': 'Fallback', 'type': 'fallback',
                        'url': 'http://www.gstatic.com/generate_204', 'interval': 300,
                        'proxies': proxy_names
                    },
                    {
                        'name': 'URL-Test', 'type': 'url-test',
                        'url': 'http://www.gstatic.com/generate_204', 'interval': 300, 'tolerance': 50,
                        'proxies': proxy_names
                    },
                    {
                        'name': 'Load-Balance', 'type': 'load-balance',
                        'url': 'http://www.gstatic.com/generate_204', 'interval': 300, 'strategy': 'round-robin',
                        'proxies': proxy_names
                    },
                    {
                        'name': 'Terbaik', 'type': 'load-balance',
                        'url': 'http://www.gstatic.com/generate_204', 'interval': 300, 'strategy': 'round-robin',
                        'proxies': ['Bug1', 'Bug2', 'Bug3', 'Bug4', 'Bug5', 'URL-Test', 'RG', 'Ilped', 'GGWP']
                    }
                ]
                
                # Add IFLIX group if there are IFLIX proxies
                if iflix_names:
                    new_data['proxy-groups'].append({
                        'name': 'IFLIX', 'type': 'url-test',
                        'url': 'http://www.gstatic.com/generate_204', 
                        'interval': 300, 'tolerance': 50, 'proxies': iflix_names
                    })
                
                # Server-specific groups
                for server, names in server_names.items():
                    if names:
                        new_data['proxy-groups'].append({
                            'name': server, 'type': 'url-test',
                            'url': 'http://www.gstatic.com/generate_204', 
                            'interval': 30, 'tolerance': 50, 'proxies': names
                        })
                
                # Add rules
                new_data['rules'] = ['MATCH,Fallback']
            
            # Write to output file
            with open(output_file, 'w') as file:
                yaml.dump(new_data, file, default_flow_style=False, sort_keys=False)
            
            logger.info(f"Successfully wrote {proxy_type} configuration to {output_file}")
        
        return True
    
    except Exception as e:
        logger.error(f"Error during conversion: {str(e)}")
        return False

def send_to_telegram(bot_token, chat_id, file_path, max_retries=3):
    """Send file to Telegram"""
    for attempt in range(max_retries):
        try:
            with open(file_path, 'rb') as file:
                response = requests.post(
                    f"https://api.telegram.org/bot{bot_token}/sendDocument",
                    files={'document': file},
                    data={'chat_id': chat_id}
                )
                
                if response.status_code == 200:
                    logger.info(f"Sent {file_path} to Telegram")
                    return True
                else:
                    logger.warning(f"Attempt {attempt+1}: Failed to send. Status: {response.status_code}")
        
        except Exception as e:
            logger.error(f"Attempt {attempt+1}: Error: {str(e)}")
        
        if attempt < max_retries - 1:
            import time
            time.sleep(2)
    
    logger.error(f"Failed to send to Telegram after {max_retries} attempts")
    return False

def main():
    """Parse arguments and run conversion"""
    parser = argparse.ArgumentParser(description='Convert Clash configuration files')
    parser.add_argument('--input', '-i', action='append', default=[], 
                      help='Input YAML files (default: all ambil*.yaml files)')
    parser.add_argument('--template', '-t', default='byurule.yaml', 
                      help='Template YAML file (default: byurule.yaml)')
    parser.add_argument('--trojan-output', default='trojanakun.yaml', 
                      help='Output YAML file for Trojan accounts (default: trojanakun.yaml)')
    parser.add_argument('--vless-output', default='vlessakun.yaml', 
                      help='Output YAML file for VLESS accounts (default: vlessakun.yaml)')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    
    args = parser.parse_args()
    if args.debug: logger.setLevel(logging.DEBUG)
    
    # Use defaults if no input files specified
    input_files = args.input if args.input else get_ambil_files()
    
    # Run conversion
    success = convert_ambil_to_byurule(
        input_files=input_files,
        template_file=args.template,
        trojan_output=args.trojan_output,
        vless_output=args.vless_output
    )
    
    return 0 if success else 1

if __name__ == "__main__":
    if len(sys.argv) > 1:
        sys.exit(main())
    else:
        convert_ambil_to_byurule()