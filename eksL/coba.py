import json
import yaml
import os

os.chdir(
    os.path.dirname(
        os.path.abspath(
            __file__
        )
    )
)

with open('dualvlesscombine.yaml', 'r') as input:
    json_object: dict = json.loads(input.read())
    with open('config.json', 'w') as output:
        output.write(yaml.dump(json_object, allow_unicode=True, indent=4))

def fix_port_fields(data):
    """Fix the 'port' field issue by converting it to 'server_port'"""
    if isinstance(data, dict):
        # Convert port to server_port where needed
        if 'port' in data:
            data['server_port'] = data.pop('port')
        
        # Process all nested dictionaries
        for key, value in list(data.items()):
            if isinstance(value, (dict, list)):
                fix_port_fields(value)
    elif isinstance(data, list):
        # Process each item in the list
        for item in data:
            if isinstance(item, (dict, list)):
                fix_port_fields(item)
    return data

# Read from YAML
with open('dualvlesscombine.yaml', 'r') as input_file:
    yaml_object = yaml.safe_load(input_file)
    
    # Fix port fields to prevent the "unknown field port" error
    fixed_data = fix_port_fields(yaml_object)
    
    # Write to JSON with the new filename
    with open('xl.json', 'w') as output_file:
        json.dump(fixed_data, output_file, indent=4, ensure_ascii=False)

print("Successfully created xl.json")