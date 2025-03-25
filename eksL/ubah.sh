#!/bin/bash

# Define input and output file pairs as arrays
input_files=("mycustom_trojan.yaml" "mycustom_ss.yaml" "mycustom_vless.yaml")
output_files=("Troj_allProxy.yaml" "SSl_Proxy.yaml" "Vless_allProxy.yaml")

# Process each file pair
for i in "${!input_files[@]}"; do
    input_file="${input_files[$i]}"
    output_file="${output_files[$i]}"
    
    echo "Processing: $input_file -> $output_file"
    
    # Check if the input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' not found."
        continue
    fi

    # Extract the content between specified patterns
    start_pattern="external-ui: ./dashboard"
    end_pattern="proxy-groups:"

    # Use head -1 to take only the first occurrence of each pattern
    start_line=$(grep -n "$start_pattern" "$input_file" | head -1 | cut -d':' -f1)
    end_line=$(grep -n "$end_pattern" "$input_file" | head -1 | cut -d':' -f1)

    if [ -z "$start_line" ] || [ -z "$end_line" ]; then
        echo "Error: Could not find start or end pattern in '$input_file'."
        continue
    fi

    start=$((start_line + 1))
    end=$((end_line - 1))

    # Extract the lines and save to the output file
    sed -n "${start},${end}p" "$input_file" > "$output_file"

    echo "Successfully extracted content and saved to '$output_file'."
done

echo "All files processed."