import streamlit as st
import yaml
import os
import copy
import datetime
import io
import logging
from pathlib import Path

# Configure logging to memory
log_stream = io.StringIO()
handler = logging.StreamHandler(log_stream)
handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(handler)

def convert_yaml(input_yaml, template_yaml):
    """Convert uploaded YAML files"""
    try:
        # Parse YAML content
        ambil_data = yaml.safe_load(input_yaml)
        template_data = yaml.safe_load(template_yaml)
        
        # Start with a deep copy of the template
        new_data = copy.deepcopy(template_data)
        
        # Extract proxies
        if 'proxies' in ambil_data and ambil_data['proxies']:
            proxy_names = []
            ff_names = []
            ilped_names = []
            wlg_names = []
            
            # Replace proxies in the template
            new_data['proxies'] = []
            
            # Process and add proxies
            for proxy in ambil_data.get('proxies', []):
                # Update server values where needed
                if proxy.get('server') == '104.17.72.206':
                    # Rotate through the new server IPs
                    new_server_ips = ['172.67.5.14', '172.66.0.145', '104.22.5.240', 
                                     '172.67.5.14', '104.17.72.206', '104.17.155.243']
                    proxy['server'] = new_server_ips[len(new_data['proxies']) % len(new_server_ips)]
                
                # Convert port from string to integer if needed
                if 'port' in proxy and isinstance(proxy['port'], str) and proxy['port'].isdigit():
                    proxy['port'] = int(proxy['port'])
                
                # Add the proxy to the new data
                new_data['proxies'].append(proxy)
                
                # Record proxy name for groups
                if 'name' in proxy:
                    proxy_names.append(proxy['name'])
            
            # Add specialized proxies if template available
            if len(new_data['proxies']) > 0:
                # Find a suitable template proxy
                template_proxy = None
                for proxy in new_data['proxies']:
                    if 'server' in proxy and 'port' in proxy and 'name' in proxy:
                        template_proxy = copy.deepcopy(proxy)
                        break
                
                if template_proxy:
                    # Add FF proxies
                    ff_proxy1 = copy.deepcopy(template_proxy)
                    ff_proxy1['name'] = "FF-1 Cloudflare WS TLS"
                    ff_proxy1['server'] = '104.17.255.156'
                    new_data['proxies'].append(ff_proxy1)
                    proxy_names.append(ff_proxy1['name'])
                    ff_names.append(ff_proxy1['name'])
                    
                    ff_proxy2 = copy.deepcopy(template_proxy)
                    ff_proxy2['name'] = "FF-2 Cloudflare WS TLS"
                    ff_proxy2['server'] = '104.16.16.243'
                    new_data['proxies'].append(ff_proxy2)
                    proxy_names.append(ff_proxy2['name'])
                    ff_names.append(ff_proxy2['name'])
                    
                    # Add Ilped proxies
                    ilped_proxy1 = copy.deepcopy(template_proxy)
                    ilped_proxy1['name'] = "Ilped-1 WS TLS"
                    ilped_proxy1['server'] = '104.26.7.171'
                    new_data['proxies'].append(ilped_proxy1)
                    proxy_names.append(ilped_proxy1['name'])
                    ilped_names.append(ilped_proxy1['name'])
                    
                    ilped_proxy2 = copy.deepcopy(template_proxy)
                    ilped_proxy2['name'] = "Ilped-2 WS TLS"
                    ilped_proxy2['server'] = '104.16.66.85'
                    new_data['proxies'].append(ilped_proxy2)
                    proxy_names.append(ilped_proxy2['name'])
                    ilped_names.append(ilped_proxy2['name'])
                    
                    ilped_proxy3 = copy.deepcopy(template_proxy)
                    ilped_proxy3['name'] = "Ilped-3 WS TLS"
                    ilped_proxy3['server'] = '104.17.3.81'
                    new_data['proxies'].append(ilped_proxy3)
                    proxy_names.append(ilped_proxy3['name'])
                    ilped_names.append(ilped_proxy3['name'])
                    
                    # Add WLG proxies
                    wlg_proxy1 = copy.deepcopy(template_proxy)
                    wlg_proxy1['name'] = "WLG-1 WS TLS"
                    wlg_proxy1['server'] = '104.18.214.235'
                    new_data['proxies'].append(wlg_proxy1)
                    proxy_names.append(wlg_proxy1['name'])
                    wlg_names.append(wlg_proxy1['name'])
                    
                    wlg_proxy2 = copy.deepcopy(template_proxy)
                    wlg_proxy2['name'] = "WLG-2 WS TLS"
                    wlg_proxy2['server'] = '104.18.213.235'
                    new_data['proxies'].append(wlg_proxy2)
                    proxy_names.append(wlg_proxy2['name'])
                    wlg_names.append(wlg_proxy2['name'])
                    
                    wlg_proxy3 = copy.deepcopy(template_proxy)
                    wlg_proxy3['name'] = "WLG-3 WS TLS"
                    wlg_proxy3['server'] = 'ava.game.naver.com'
                    new_data['proxies'].append(wlg_proxy3)
                    proxy_names.append(wlg_proxy3['name'])
                    wlg_names.append(wlg_proxy3['name'])
            
            # Update proxy groups
            if 'proxy-groups' in new_data and proxy_names:
                # Create or update groups
                if 'proxy-groups' not in new_data:
                    new_data['proxy-groups'] = []
                else:
                    # Update existing groups
                    for group in new_data['proxy-groups']:
                        if group.get('type') in ['select', 'fallback', 'url-test', 'load-balance']:
                            if 'proxies' in group:
                                special_groups = [p for p in group['proxies'] if p in ['DIRECT', 'REJECT', 'Fallback']]
                                group['proxies'] = special_groups + proxy_names
                            
                            # Update URL for health checks
                            if 'url' in group and group['url'] == 'http://www.gstatic.com/generate_204':
                                group['url'] = 'http://cp.cloudflare.com/generate_204'
                
                # Add specialized groups
                ff_group = {
                    'name': 'FF',
                    'type': 'select',
                    'proxies': ff_names
                }
                new_data['proxy-groups'].append(ff_group)
                
                ilped_group = {
                    'name': 'Ilped',
                    'type': 'select',
                    'proxies': ilped_names
                }
                new_data['proxy-groups'].append(ilped_group)
                
                wlg_group = {
                    'name': 'WLG',
                    'type': 'select',
                    'proxies': wlg_names
                }
                new_data['proxy-groups'].append(wlg_group)
                
                # Add fallback group if not exists
                fallback_exists = False
                for group in new_data['proxy-groups']:
                    if group.get('name') == 'Fallback':
                        fallback_exists = True
                        break
                
                if not fallback_exists:
                    fallback_group = {
                        'name': 'Fallback',
                        'type': 'fallback',
                        'url': 'http://cp.cloudflare.com/generate_204',
                        'interval': 300,
                        'proxies': proxy_names
                    }
                    new_data['proxy-groups'].append(fallback_group)
        
        # Convert to YAML
        result_yaml = yaml.dump(new_data, default_flow_style=False, sort_keys=False, allow_unicode=True)
        
        return result_yaml
    
    except Exception as e:
        logger.error(f"Error during conversion: {str(e)}", exc_info=True)
        return None

# Load dualvless.yaml template
@st.cache_data
def load_template():
    try:
        with open('dualvless.yaml', 'r', encoding='utf-8') as file:
            return file.read()
    except Exception as e:
        logger.error(f"Error loading template file: {str(e)}")
        return None

# Streamlit UI
st.set_page_config(page_title="YAML Converter", page_icon="🔄")

st.title("YAML Converter App")
st.write("Upload your YAML file to convert it using the dualvless.yaml template")

with st.expander("How to use this tool", expanded=True):
    st.markdown("""
    1. Upload your `ambil.yaml` file (the input file with proxies)
    2. Click "Convert YAML" to process the files
    3. Download the converted file
    
    Note: The app uses the existing dualvless.yaml template file on the server.
    """)

# File upload
input_file = st.file_uploader("Upload Input YAML file (ambil.yaml)", type=["yaml", "yml"])

# Load template
template_content = load_template()
if template_content is None:
    st.error("Could not load the dualvless.yaml template file. Please make sure it exists in the same directory as this app.")

# Process button
if st.button("Convert YAML"):
    if input_file is not None and template_content is not None:
        with st.spinner("Converting YAML..."):
            # Read file content
            input_content = input_file.read().decode('utf-8')
            
            # Convert
            result = convert_yaml(input_content, template_content)
            
            if result:
                st.success("Conversion successful!")
                
                # Create download button
                timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
                st.download_button(
                    label="Download Converted YAML",
                    data=result,
                    file_name=f"newdualvless_{timestamp}.yaml",
                    mime="application/x-yaml"
                )
                
                # Show result preview
                with st.expander("Preview Converted YAML"):
                    st.code(result, language="yaml")
                
                # Show logs
                with st.expander("Conversion Logs"):
                    st.code(log_stream.getvalue())
            else:
                st.error("Conversion failed. Check the logs for details.")
                with st.expander("Error Logs"):
                    st.code(log_stream.getvalue())
    else:
        st.warning("Please upload an input file")

st.divider()

# Footer
current_year = datetime.datetime.now().year
st.markdown(f"""
<div style="text-align: center; padding-top: 20px;">
    © {current_year} Developed by: Galuh Adi Insani with ❤️. All rights reserved.
</div>
""", unsafe_allow_html=True)

hide_st_style = """
        <style>
        #MainMenu {visibility: hidden;}
        footer {visibility: hidden;}
        header {visibility: hidden;}
        </style>
        """
st.markdown(hide_st_style, unsafe_allow_html=True)