#!/bin/bash
# Color definition
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
exts="tlds.txt"

# Check if whois is installed
command -v whois &> /dev/null || { printf '%s\n' "whois not installed. You must install whois to use this tool." >&2 ; exit 1 ;}

#Banner
echo " _____ _    ___  _  _          _   ";
echo "|_   _| |  |   \| || |_  _ _ _| |_ ";
echo "  | | | |__| |) | __ | || | ' \  _|";
echo "  |_| |____|___/|_||_|\_,_|_||_\__|";
echo "        Domain Availability Checker";
echo "";
usage() {
  echo "Usage: $0 -k <keyword> [-e <tld> | -E <exts>] [-x]"
  echo "Example: $0 -k linuxsec -E tlds.txt"
  exit 1
}

# Argument Lists
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -k|--keyword) keyword="$2"; shift ;;
    -e|--tld) tld="$2"; shift ;;
    -E|--tld-file) exts="$2"; shift ;;
    -x|--not-registered) nreg=true ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Arguments Validator
if [[ -z $keyword ]]; then
    echo "Keyword is required."
    usage
fi

if [[ -n $tld && -n $exts ]]; then
    echo "You can only specify one of -e or -E options."
    usage
fi

if [[ -n $exts && ! -f $exts ]]; then
    echo "tld file $exts not found."
    usage
fi

if [[ -n $exts ]]; then
    tlds=$(cat "$exts")
else
    tlds=$tld
fi

# Domain tld Checker
processes=0
for ext in $tlds; do
    domain="$keyword$ext"
    {
        result=$(whois "$domain" 2>/dev/null | grep -i "Name Server")
        if [ -n "$result" ]; then
            if [ "$nreg" = false ]; then
                echo -e "[${b_red}taken${reset}] - $domain"
            fi
        else
            if [ "$nreg" = false ]; then
                echo -e "[${b_green}avail${reset}] - $domain"
            else
                echo -e "$domain"
            fi
        fi
    } &
    ((processes+=1))
    if ((processes >= 20)); then
        wait
        processes=0
    fi
done
wait
