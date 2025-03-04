#!/bin/bash

# Color definitions
: "${green:=\033[1;32m}"
: "${red:=\033[1;31m}"
: "${blue:=\033[0;34m}"
: "${orange:=\033[0;33m}"
: "${cyan:=\033[0;36m}"
: "${reset:=\033[0m}"

# Default value
nreg=false
nprem=false
error=false
quiet=false
sleep_time=0.5

# Check if whois installed
command -v whois >& /dev/null || { echo -e "${red}Whois not installed!${reset}" >&2; exit 1; }

# Banner
echo -e "${blue}"
cat << "EOF"
 _____ _    ___  _  _          _   
|_   _| |  |   \| || |_  _ _ _| |_ 
  | | | |__| |) | __ | || | ' \  _|
  |_| |____|___/|_||_|\_,_|_||_\__|
        Domain Availability Checker
EOF
echo -e "${reset}"

# Instruction
usage() {
    echo -e "${green}Usage:${reset} $0 [${blue}-k <keyword>${reset} | ${blue}-K <keyword-file>${reset}] [${blue}-t <tld>${reset} | ${blue}-T <tld-file>${reset}] [${blue}-d <time>${reset}] [${cyan}-q$reset] [${cyan}-x${reset}] [${cyan}-n${reset}] [${cyan}-xn${reset}] [${orange}-h${reset}]"
    echo -e "\n${green}Options:${reset}"
    echo -e "  ${blue}-k,  --keyword             <keyword>${reset}       Specify a single keyword."
    echo -e "  ${blue}-K,  --keyword-file        <file>${reset}          Use a file containing a list of keywords."
    echo -e "  ${blue}-t,  --tld                 <tld>${reset}           Specify a single top-level domain (TLD)."
    echo -e "  ${blue}-T,  --tld-file            <file>${reset}          Use a file containing a list of TLDs."
    echo -e "  ${blue}-d,  --delay               <time>${reset}          Set the delay time between requests. Default: 0.5s."
    echo -e "  ${cyan}-q,  --quiet                               ${reset}Suppress error messages and display only results."
    echo -e "  ${cyan}-x,  --not-registered                      ${reset}Show only unregistered domains."
    echo -e "  ${cyan}-n,  --no-premium                          ${reset}Show only non-premium domains."
    echo -e "  ${cyan}-xn, --unreg-noprem                        ${reset}Combination of -x and -n."
    echo -e "  ${orange}-h,  --help                                ${reset}Display this help message."
    echo -e "\n${green}Examples:${reset}"
    echo -e "  $0 ${blue}-K example.txt -t .com${reset}"
    echo -e "  $0 ${blue}-k example -t .com${reset}"
    echo -e "  $0 ${blue}-k example -T tlds.txt${reset}"
    echo -e "  $0 ${blue}-k example -T tlds.txt -x${reset}"
    echo -e "  $0 ${blue}-k example -T tlds.txt -n${reset}"
    echo -e "  $0 ${blue}-k example -T tlds.txt -xn${reset}"
    echo -e "  $0 ${blue}-k example -T tlds.txt -d 2${reset}\n"
    exit 1
}

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -k|--keyword) keyword="$2"; shift ;;
        -K|--keyword-file) keyword_file="$2"; shift ;;
        -t|--tld) tld="$2"; shift ;;
        -T|--tld-file) exts="$2"; shift ;;
        -d|--delay) sleep_time="$2"; shift ;;
        -q|--quiet) quiet=true ;;
        -x|--not-registered) nreg=true ;;
        -n|--no-premium) nprem=true ;;
        -xn|-nx|--unreg-noprem) nprem=true; nreg=true ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Argument validation
[[ -z $keyword && -z $keyword_file && -z $tld && -z $exts ]] && usage
[[ -n $keyword && -n $keyword_file ]] && { echo "You can only specify one of -k or -K options."; usage; }
[[ -z $keyword && -z $keyword_file ]] && { echo "Either -k or -K option is required."; usage; }
[[ -n $keyword_file && ! -f $keyword_file ]] && { echo "Keyword file (${keyword_file}) not found."; usage; }
[[ -n $tld && -n $exts ]] && { echo "You can only specify one of -t or -T options."; usage; }
[[ -z $tld && -z $exts ]] && { echo "Either -t or -T option is required."; usage; }
[[ -n $exts && ! -f $exts ]] && { echo "TLD file ($exts) not found."; usage; }
[[ ! $sleep_time =~ ^[0-9]+(\.[0-9]*)?$ ]] && { echo "Sleep time must be greater than or equal 0"; usage; }

# Load keywords
names=()
if [[ -n $keyword_file ]]; then
    readarray -t names < "${keyword_file}"
else
    names=("$keyword")
fi

# Load TLDs
tlds=()
if [[ -n $exts ]]; then
    readarray -t tlds < "$exts"
else
    tlds=("${tld}")
fi

# Function to check domain availability via whois
check_domain() {
    local domain="$1"
    local whois_output
    whois_output=$(whois "${domain}" 2>&1)
    if [[ $? -ge 1 ]]; then
        if [[ "$quiet" = false ]]; then
            echo -e "[${red}error${reset}] $domain - $whois_output"
        fi
        return 1
    else
        local result
        result=$(echo "${whois_output}" | grep -iE "Name server|nserver|nameservers|status: active")
    
        if [[ -n $result ]]; then
            if [[ "${nreg}" = false ]]; then
                local expiry_date
                expiry_date=$(echo "${whois_output}" | grep -iE "Expire Date|Expiration Date|Registry Expiry Date" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | uniq)
                if [[ -n $expiry_date ]]; then
                    echo -e "[${blue}taken${reset}] $domain - Exp Date: ${orange}${expiry_date}${reset}"
                else
                    echo -e "[${blue}taken${reset}] $domain - No expiry date found"
                fi
            fi
        else
            local premium_check
            premium_check=$(echo "${whois_output}" | grep premium)
            if [[ -n "${premium_check}" ]]; then
                if [[ "${nprem}" = false ]]; then
                    echo -e "[${cyan}avail${reset}] $domain - Premium"
                fi
            else
                echo -e "[${green}avail${reset}] $domain - Not premium"
            fi
        fi
    fi
}

# Process TLDs
for name in "${names[@]}"; do   
    for ext in "${tlds[@]}"; do
        domain="${name}${ext}"
        check_domain "${domain}" &
        if (( $(jobs -r -p | wc -l) >= 30 )); then
            wait -n
        fi
        sleep "$sleep_time"
    done
done
wait
