import yaml
import os
import requests
import argparse
import logging
import sys
from datetime import datetime
from pathlib import Path

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Server configurations
SERVER_CONFIGS = {
    "Bug1-": {"ip": "172.67.5.14", "prefix": "Bug1-"},
    "Bug2-": {"ip": "172.66.0.145", "prefix": "Bug2-"},
    "Bug3-": {"ip": "104.22.5.240", "prefix": "Bug3-"},
    "Bug4-": {"ip": "104.17.72.206", "prefix": "Bug4-"},
    "Bug5-": {"ip": "104.17.155.243", "prefix": "Bug5-"},
    "RG": {"ip": "104.22.21.245", "prefix": "RG-"},
    "Ilped": {"ip": "172.67.74.70", "prefix": "Ilped-"},
    "GGWP": {"ip": "104.19.143.108", "prefix": "GGWP-"}
}

def generate_proxies(original_proxies, server_type, template_proxy):
    """Generate proxies for a specific server type"""
    config = SERVER_CONFIGS.get(server_type)
    if not config:
        logger.error(f"Unknown server type: {server_type}")
        return [], []
    
    server_ip = config["ip"]
    name_prefix = config["prefix"]
    proxies = []
    names = []
    
    # Add regular proxies
    for original in original_proxies:
        new_proxy = original.copy()
        new_proxy['server'] = server_ip
        
        # Add prefix to name if needed
        if 'name' in new_proxy and name_prefix:
            new_proxy['name'] = name_prefix + new_proxy['name']
            
        # Convert port from string to integer if needed
        if 'port' in new_proxy and new_proxy['port'] == '443':
            new_proxy['port'] = 443
            
        proxies.append(new_proxy)
        
        if 'name' in new_proxy:
            names.append(new_proxy['name'])
    
    # Add dedicated proxy
    dedicated_proxy = template_proxy.copy()
    dedicated_proxy['name'] = f"{server_type} WS TLS"
    dedicated_proxy['server'] = server_ip
    proxies.append(dedicated_proxy)
    names.append(dedicated_proxy['name'])
    
    return proxies, names

def convert_ambil_to_byurule(input_files=['combined_proxies.yaml'], template_file='combine.yaml', 
                           output_file='dualvlesscombine.yaml', telegram_bot_token=None, 
                           telegram_chat_id=None, telegram_enabled=True):
    """Convert multiple YAML input files to dualvlesscombine.yaml with enhanced proxy configurations"""
    
    # Ensure input_files is a list
    if isinstance(input_files, str):
        input_files = [input_files]
    
    # Check if template file exists
    if not os.path.exists(template_file):
        logger.error(f"Error: {template_file} file (template) not found")
        return False
    
    # Check if at least one input file exists
    valid_input_files = []
    for file_name in input_files:
        if os.path.exists(file_name):
            valid_input_files.append(file_name)
        else:
            logger.warning(f"Input file {file_name} not found, skipping")
    
    if not valid_input_files:
        logger.error("No valid input files found")
        return False
    
    try:
        # Read all input files and collect all proxies
        all_proxies = []
        for input_file in valid_input_files:
            with open(input_file, 'r') as file:
                data = yaml.safe_load(file)
            
            if not isinstance(data, dict):
                logger.error(f"Invalid YAML format in {input_file}")
                continue
                
            if 'proxies' not in data or not data['proxies']:
                logger.warning(f"No proxies found in {input_file}")
                continue
                
            logger.info(f"Loaded {len(data['proxies'])} proxies from {input_file}")
            all_proxies.extend(data['proxies'])
        
        if not all_proxies:
            logger.error("No proxies found in any input files")
            return False
        
        # Read template file
        with open(template_file, 'r') as file:
            byurule_template = yaml.safe_load(file)
        
        # Create new data structure with only essential elements
        new_data = {}
        
        # Define essential keys to keep from the template
        essential_keys = [
            'port', 'socks-port', 'redir-port', 'mixed-port', 'tproxy-port', 
            'ipv6', 'mode', 'log-level', 'allow-lan', 'external-controller',
            'secret', 'bind-address', 'unified-delay', 'profile', 'general', 'dns'
        ]
        
        # Copy essential keys
        for key in essential_keys:
            if key in byurule_template:
                new_data[key] = byurule_template[key]
        
        # Add external UI configuration
        new_data['external-ui'] = './dashboard'
        
        proxy_names = []
        server_names = {server_type: [] for server_type in SERVER_CONFIGS}
        
        # Find a proxy to use as template
        template_proxy = None
        for proxy in all_proxies:
            if all(key in proxy for key in ['server', 'port', 'name']):
                template_proxy = proxy.copy()
                break
                
        if not template_proxy:
            logger.error("No suitable proxy template found")
            return False
        
        # Initialize the proxies list
        new_data['proxies'] = []
        
        # Generate proxies for each server type
        for server_type in SERVER_CONFIGS:
            proxies, names = generate_proxies(all_proxies, server_type, template_proxy)
            new_data['proxies'].extend(proxies)
            proxy_names.extend(names)
            server_names[server_type] = names
        
        # Add proxy groups
        if proxy_names:
            new_data['proxy-groups'] = [
                {
                    'name': 'Selector',
                    'type': 'select',
                    'proxies': ['Fallback', 'URL-Test', 'Load-Balance', 'Terbaik', 'Bug1', 'Bug2', 'Bug3', 'Bug4', 'Bug5', 'RG', 'Ilped', 'GGWP'] + proxy_names
                },
                {
                    'name': 'Fallback',
                    'type': 'fallback',
                    'url': 'http://www.gstatic.com/generate_204',
                    'interval': 300,
                    'proxies': proxy_names
                },
                {
                    'name': 'URL-Test',
                    'type': 'url-test',
                    'url': 'http://www.gstatic.com/generate_204',
                    'interval': 300,
                    'tolerance': 50,
                    'proxies': proxy_names
                },
                {
                    'name': 'Load-Balance',
                    'type': 'load-balance',
                    'url': 'http://www.gstatic.com/generate_204',
                    'interval': 300,
                    'strategy': 'round-robin',
                    'proxies': proxy_names
                },
                {
                    'name': 'Terbaik',
                    'type': 'load-balance',
                    'url': 'http://www.gstatic.com/generate_204',
                    'interval': 300,
                    'strategy': 'round-robin',
                    'proxies': ['Bug1', 'Bug2', 'Bug3', 'Bug4', 'Bug5', 'URL-Test']
                }
            ]
            
            # Add specialized groups for each server type
            for server_type, names in server_names.items():
                if names:
                    group = {
                        'name': server_type,
                        'type': 'url-test',
                        'url': 'http://www.gstatic.com/generate_204',
                        'interval': 300,
                        'tolerance': 50,
                        'proxies': names
                    }
                    new_data['proxy-groups'].append(group)
            
            # Add ad-blocking and fallback rules
            new_data['rules'] = [
                'DOMAIN-SUFFIX,adservice.google.com,REJECT',
                'DOMAIN-SUFFIX,googlesyndication.com,REJECT',
                'DOMAIN-SUFFIX,doubleclick.net,REJECT',
                'DOMAIN-SUFFIX,g.doubleclick.net,REJECT',
                'DOMAIN-SUFFIX,googleadservices.com,REJECT',
                'DOMAIN-SUFFIX,admob.com,REJECT',
                'DOMAIN-SUFFIX,pubmatic.com,REJECT',
                'DOMAIN-SUFFIX,rubiconproject.com,REJECT',
                'DOMAIN-SUFFIX,criteo.com,REJECT',
                'DOMAIN-SUFFIX,openx.net,REJECT',
                'DOMAIN-SUFFIX,amazon-adsystem.com,REJECT',
                'DOMAIN-SUFFIX,adserver.yahoo.com,REJECT',
                'DOMAIN-SUFFIX,adtech.com,REJECT',
                'DOMAIN-SUFFIX,advertising.com,REJECT',
                'DOMAIN-SUFFIX,taboola.com,REJECT',
                'DOMAIN-SUFFIX,outbrain.com,REJECT',
                'DOMAIN-SUFFIX,revcontent.com,REJECT',
                'DOMAIN-SUFFIX,inmobi.com,REJECT',
                'DOMAIN-SUFFIX,moat.com,REJECT',
                'DOMAIN-SUFFIX,smartadserver.com,REJECT',
                'DOMAIN-SUFFIX,adcolony.com,REJECT',
                'DOMAIN-SUFFIX,unityads.unity3d.com,REJECT',
                'DOMAIN-SUFFIX,chartboost.com,REJECT',
                'DOMAIN-SUFFIX,flurry.com,REJECT',
                'DOMAIN-SUFFIX,adform.com,REJECT',
                'DOMAIN-SUFFIX,adnxs.com,REJECT',
                'DOMAIN-SUFFIX,adsafeprotected.com,REJECT',
                'DOMAIN-SUFFIX,adobedtm.com,REJECT',
                'DOMAIN-SUFFIX,adroll.com,REJECT',
                'DOMAIN-SUFFIX,appnexus.com,REJECT',
                'DOMAIN-SUFFIX,bidswitch.com,REJECT',
                'DOMAIN-SUFFIX,brightcove.com,REJECT',
                'DOMAIN-SUFFIX,casalemedia.com,REJECT',
                'DOMAIN-SUFFIX,conversantmedia.com,REJECT',
                'DOMAIN-SUFFIX,districtm.ca,REJECT',
                'DOMAIN-SUFFIX,exoclick.com,REJECT',
                'DOMAIN-SUFFIX,exponential.com,REJECT',
                'DOMAIN-SUFFIX,free-counter.co.uk,REJECT',
                'DOMAIN-SUFFIX,ft.com,REJECT',
                'DOMAIN-SUFFIX,gravity.com,REJECT',
                'DOMAIN-SUFFIX,imrworldwide.com,REJECT',
                'DOMAIN-SUFFIX,innovid.com,REJECT',
                'DOMAIN-SUFFIX,ipredictive.com,REJECT',
                'DOMAIN-SUFFIX,lijit.com,REJECT',
                'DOMAIN-SUFFIX,loopme.me,REJECT',
                'DOMAIN-SUFFIX,mathtag.com,REJECT',
                'DOMAIN-SUFFIX,media.net,REJECT',
                'DOMAIN-SUFFIX,mediavine.com,REJECT',
                'DOMAIN-SUFFIX,mgid.com,REJECT',
                'DOMAIN-SUFFIX,mydas.mobi,REJECT',
                'DOMAIN-SUFFIX,nativo.com,REJECT',
                'DOMAIN-SUFFIX,nexage.com,REJECT',
                'DOMAIN-SUFFIX,openx.com,REJECT',
                'DOMAIN-SUFFIX,optimatic.com,REJECT',
                'DOMAIN-SUFFIX,plista.com,REJECT',
                'DOMAIN-SUFFIX,quantcast.com,REJECT',
                'DOMAIN-SUFFIX,rfihub.com,REJECT',
                'DOMAIN-SUFFIX,scorecardresearch.com,REJECT',
                'DOMAIN-SUFFIX,serving-sys.com,REJECT',
                'DOMAIN-SUFFIX,sizmek.com,REJECT',
                'DOMAIN-SUFFIX,spotxchange.com,REJECT',
                'DOMAIN-SUFFIX,steelhousemedia.com,REJECT',
                'DOMAIN-SUFFIX,stickyadstv.com,REJECT',
                'DOMAIN-SUFFIX,tapad.com,REJECT',
                'DOMAIN-SUFFIX,teads.tv,REJECT',
                'DOMAIN-SUFFIX,tidaltv.com,REJECT',
                'DOMAIN-SUFFIX,trustx.org,REJECT',
                'DOMAIN-SUFFIX,turn.com,REJECT',
                'DOMAIN-SUFFIX,undertone.com,REJECT',
                'DOMAIN-SUFFIX,unrulymedia.com,REJECT',
                'DOMAIN-SUFFIX,verizonmedia.com,REJECT',
                'DOMAIN-SUFFIX,vidible.tv,REJECT',
                'DOMAIN-SUFFIX,weborama.com,REJECT',
                'DOMAIN-SUFFIX,yieldlab.net,REJECT',
                'DOMAIN-SUFFIX,yieldmo.com,REJECT',
                'DOMAIN-SUFFIX,yieldoptimizer.com,REJECT',
                'DOMAIN-SUFFIX,yieldr.com,REJECT',
                'DOMAIN-SUFFIX,zedo.com,REJECT',
                'DOMAIN-SUFFIX,instagram.com,Selector',
                'DOMAIN-SUFFIX,cdninstagram.com,Selector',
                'DOMAIN-SUFFIX,fbcdn.net,Selector',
                'DOMAIN-SUFFIX,whatsapp.com,Selector',
                'DOMAIN-SUFFIX,whatsapp.net,Selector',
                'IP-CIDR,3.0.0.0/8,Selector',
                'IP-CIDR,13.0.0.0/8,Selector',
                'IP-CIDR,52.0.0.0/8,Selector',
                'IP-CIDR,54.0.0.0/8,Selector',
                'MATCH,Fallback'
            ]
        
        # Write to output file
        with open(output_file, 'w') as file:
            yaml.dump(new_data, file, default_flow_style=False, sort_keys=False)
        
        logger.info(f"Successfully converted {', '.join(valid_input_files)} to {output_file}")
        
        # Send to Telegram if enabled and credentials are provided
        if telegram_enabled and telegram_bot_token and telegram_chat_id:
            send_to_telegram(telegram_bot_token, telegram_chat_id, output_file)
        elif telegram_enabled and (not telegram_bot_token or not telegram_chat_id):
            logger.warning("Telegram notifications enabled but missing bot token or chat ID")
        
        return True
    
    except Exception as e:
        logger.error(f"Error during conversion: {str(e)}")
        return False

def send_to_telegram(bot_token, chat_id, file_path, max_retries=3):
    """Send a file to a Telegram chat using Telegram Bot API with retry logic"""
    for attempt in range(max_retries):
        try:
            url = f"https://api.telegram.org/bot{bot_token}/sendDocument"
            
            with open(file_path, 'rb') as file:
                files = {'document': file}
                data = {'chat_id': chat_id}
                
                response = requests.post(url, files=files, data=data)
                
                if response.status_code == 200:
                    logger.info(f"Successfully sent {file_path} to Telegram")
                    return True
                else:
                    logger.warning(f"Attempt {attempt+1}: Failed to send file to Telegram. Status code: {response.status_code}")
                    logger.debug(f"Response: {response.text}")
        
        except Exception as e:
            logger.error(f"Attempt {attempt+1}: Error sending file to Telegram: {str(e)}")
        
        if attempt < max_retries - 1:
            logger.info(f"Retrying in 2 seconds...")
            import time
            time.sleep(2)
    
    logger.error(f"Failed to send {file_path} to Telegram after {max_retries} attempts")
    return False

def main():
    """Main function to parse command line arguments and run the conversion"""
    parser = argparse.ArgumentParser(description='Convert Clash configuration files')
    parser.add_argument('--input', '-i', action='append', default=[], 
                        help='Input YAML file(s) (default: ambil.yaml, ambil2.yaml). Can be specified multiple times.')
    parser.add_argument('--template', '-t', default='byurule.yaml', help='Template YAML file (default: byurule.yaml)')
    parser.add_argument('--output', '-o', default='newbyurule.yaml', help='Output YAML file (default: newbyurule.yaml)')
    parser.add_argument('--token', help='Telegram Bot Token (optional)')
    parser.add_argument('--chat', help='Telegram Chat ID (optional)')
    parser.add_argument('--debug', action='store_true', help='Enable debug logging')
    parser.add_argument('--telegram', action='store_true', default=True, help='Enable Telegram notifications (default)')
    parser.add_argument('--no-telegram', action='store_false', dest='telegram', help='Disable Telegram notifications')
    
    args = parser.parse_args()
    
    # Set debug level if requested
    if args.debug:
        logger.setLevel(logging.DEBUG)
    
    # If no input files specified, use defaults
    input_files = args.input if args.input else ['ambil.yaml', 'ambil2.yaml', 'ambil3.yaml', 'ambil4.yaml', 'ambil5.yaml']
    
    # Get Telegram credentials from environment variables if not provided in args
    bot_token = args.token or os.environ.get('TELEGRAM_BOT_TOKEN')
    chat_id = args.chat or os.environ.get('TELEGRAM_CHAT_ID')
    
    # Run the conversion
    success = convert_ambil_to_byurule(
        input_files=input_files,
        template_file=args.template,
        output_file=args.output,
        telegram_bot_token=bot_token,
        telegram_chat_id=chat_id,
        telegram_enabled=args.telegram
    )
    
    return 0 if success else 1

if __name__ == "__main__":
    # Default bot token and chat ID - Consider using environment variables instead
    BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN', "6560425395:AAHnNDWkKzqTpKUeeiH-XsGO2hF2poI9Reo")
    CHAT_ID = os.environ.get('TELEGRAM_CHAT_ID', "28075319")
    
    # Use command line interface if arguments are provided, otherwise use defaults
    if len(sys.argv) > 1:
        sys.exit(main())
    else:
        # Add environment variable check for disabling Telegram
        telegram_enabled = os.environ.get('TELEGRAM_ENABLED', 'false').lower() != 'false'
        convert_ambil_to_byurule(
            input_files=['ambil.yaml', 'ambil2.yaml', 'ambil3.yaml', 'ambil4.yaml', 'ambil5.yaml'],
            telegram_bot_token=BOT_TOKEN, 
            telegram_chat_id=CHAT_ID, 
            telegram_enabled=telegram_enabled
        )