#!/bin/bash

url="https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
output_file="tlds.txt"

# Fetch the TLD data, process it, and write to the output file
curl -s "$url" | \
    grep -v '^#' | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/^/./' > "$output_file"

echo "TLDs have been saved to $output_file."
