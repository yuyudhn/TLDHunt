#!/bin/bash

# Color definitions
: "${blue:=\033[0;34m}"
: "${cyan:=\033[0;36m}"
: "${reset:=\033[0m}"
: "${red:=\033[0;31m}"
: "${green:=\033[0;32m}"
: "${orange:=\033[0;33m}"
: "${bold:=\033[1m}"
: "${b_green:=\033[1;32m}"
: "${b_red:=\033[1;31m}"
: "${b_orange:=\033[1;33m}"

# Default values
nreg=false
update_tld=false
tld_file="tlds.txt"
tld_url="https://data.iana.org/TLD/tlds-alpha-by-domain.txt"

# Check if whois is installed
command -v whois &> /dev/null || { echo "whois not installed. You must install whois to use this tool." >&2; exit 1; }

# Check if curl is installed (needed for TLD update)
command -v curl &> /dev/null || { echo "curl not installed. You must install curl to use this tool." >&2; exit 1; }

# Banner
cat << "EOF"
 _____ _    ___  _  _          _   
|_   _| |  |   \| || |_  _ _ _| |_ 
  | | | |__| |) | __ | || | ' \  _|
  |_| |____|___/|_||_|\_,_|_||_\__|
        Domain Availability Checker
EOF

usage() {
    echo "Usage: $0 -k <keyword> [-e <tld> | -E <tld-file>] [-x] [--update-tld]"
    echo "Example: $0 -k linuxsec -E tlds.txt"
    echo "       : $0 --update-tld"
    exit 1
}

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -k|--keyword) keyword="$2"; shift ;;
        -e|--tld) tld="$2"; shift ;;
        -E|--tld-file) exts="$2"; shift ;;
        -x|--not-registered) nreg=true ;;
        --update-tld) update_tld=true ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Update TLD list if requested
if [[ "$update_tld" = true ]]; then
    echo "Fetching TLD data from $tld_url..."
    curl -s "$tld_url" | \
        grep -v '^#' | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/^/./' > "$tld_file"
    echo "TLDs have been saved to $tld_file."
    exit 0
fi

# Validate arguments
[[ -z $keyword ]] && { echo "Keyword is required."; usage; }
[[ -n $tld && -n $exts ]] && { echo "You can only specify one of -e or -E options."; usage; }
[[ -z $tld && -z $exts ]] && { echo "Either -e or -E option is required."; usage; }
[[ -n $exts && ! -f $exts ]] && { echo "TLD file $exts not found."; usage; }

# Load TLDs
tlds=()
if [[ -n $exts ]]; then
    readarray -t tlds < "$exts"
else
    tlds=("$tld")
fi

# Function to check domain availability
check_domain() {
    local domain="$1"
    local whois_output
    whois_output=$(whois "$domain" 2>/dev/null)
    local result
    result=$(echo "$whois_output" | grep -iE "Name Server|nserver|nameservers|status: active")

    if [[ -n $result ]]; then
        if [[ "$nreg" = false ]]; then
            local expiry_date
            expiry_date=$(echo "$whois_output" | grep -iE "Expiry Date|Expiration Date|Registry Expiry Date|Expiration Time" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | uniq)
            if [[ -n $expiry_date ]]; then
                echo -e "[${b_red}taken${reset}] $domain - Exp Date: ${orange}$expiry_date${reset}"
            else
                echo -e "[${b_red}taken${reset}] $domain - No expiry date found"
            fi
        fi
    else
        echo -e "[${b_green}avail${reset}] $domain"
    fi
}

# Process TLDs
for ext in "${tlds[@]}"; do
    domain="$keyword$ext"
    check_domain "$domain" &
    if (( $(jobs -r -p | wc -l) >= 30 )); then
        wait -n
    fi
done
wait