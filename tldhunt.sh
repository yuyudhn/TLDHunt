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

# Default value
nreg=false

# Check if whois is installed
command -v whois &>/dev/null || {
	echo "whois not installed. You must install whois to use this tool." >&2
	exit 1
}

# Banner
cat <<"EOF"
 _____ _    ___  _  _          _   
|_   _| |  |   \| || |_  _ _ _| |_ 
  | | | |__| |) | __ | || | ' \  _|
  |_| |____|___/|_||_|\_,_|_||_\__|
        Domain Availability Checker
EOF

usage() {
	echo "Usage: $0 [-k <keyword> | -K <keyword-file>] [-e <tld> | -E <tld-file>] [-x]"
	echo "Example: $0 -k linuxsec -E tlds.txt"
	exit 1
}

# Argument parsing
while [[ "$#" -gt 0 ]]; do
	case $1 in
	-k | --keyword)
		keyword="$2"
		shift
		;;
	-K | --keyword-file)
		keywords_file="$2"
		shift
		;;
	-e | --tld)
		tld="$2"
		shift
		;;
	-E | --tld-file)
		exts="$2"
		shift
		;;
	-x | --not-registered) nreg=true ;;
	*)
		echo "Unknown parameter passed: $1"
		usage
		;;
	esac
	shift
done

# Validate arguments
[[ -z $keyword && -z $keywords_file ]] && {
	echo "Keyword or keyword file is required."
	usage
}
[[ -n $keyword && -n $keywords_file ]] && {
	echo "You can only specify one of -k or -K options."
	usage
}
[[ -n $tld && -n $exts ]] && {
	echo "You can only specify one of -e or -E options."
	usage
}
[[ -z $tld && -z $exts ]] && {
	echo "Either -e or -E option is required."
	usage
}
[[ -n $exts && ! -f $exts ]] && {
	echo "TLD file $exts not found."
	usage
}

# Load TLDs
tlds=()
if [[ -n $exts ]]; then
	readarray -t tlds <"$exts"
else
	tlds=("$tld")
fi

keywords=()
if [[ -n $keywords_file ]]; then
	readarray -t keywords <"$keywords_file"
else
	keywords=("$keyword")
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
			expiry_date=$(echo "$whois_output" | grep -iE "Expiry Date|Expiration Date|Registry Expiry Date" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | uniq)
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
for keyword in "${keywords[@]}"; do
	echo -e "Check ${blue}${keyword}${reset}..."
	for ext in "${tlds[@]}"; do
		domain="$keyword$ext"
		check_domain "$domain" &
		if (($(jobs -r -p | wc -l) >= 30)); then
			wait -n
		fi
	done
	echo ""
done
wait
