# TLDHunt - Domain Availability Checker
TLDHunt is a command-line tool designed to help users find available domain names for their online projects or businesses. By providing a keyword and a list of TLD (top-level domain) extensions, TLDHunt checks the availability of domain names that match the given criteria. This tool is particularly useful for those who want to quickly find a domain name that is not already taken, without having to perform a manual search on a domain registrar website.

For red teaming or phishing purposes, this tool can help you to find similar domains with different extensions from the original domain.

# Dependencies
This tool is written in Bash and the only dependency required is **whois**. Therefore, make sure that you have installed whois on your system. In Debian, you can install whois using the following command:
```
sudo apt install whois -y
```

# How It Works?
To detect whether a domain is registered or not, we search for the words "**Name Server**", "**nserver**", "**nameservers**", or "**status: active**" in the output of the WHOIS command, as this is a signature of a registered domain (thanks to [Alex Matveenko](https://github.com/Alex-Matveenko) for the suggestion). 

If you have a better signature or detection method, please feel free to submit a pull request.

# Domain Extension List
For default Top Level Domain list (tlds.txt), we use data from https://data.iana.org.
You can use your custom list, but make sure that it is formatted like this:
```
.aero
.asia
.biz
.cat
.com
.coop
.info
.int
.jobs
.mobi
```

# How to Use
```
➜  TLDHunt ./tldhunt.sh
 _____ _    ___  _  _          _   
|_   _| |  |   \| || |_  _ _ _| |_ 
  | | | |__| |) | __ | || | ' \  _|
  |_| |____|___/|_||_|\_,_|_||_\__|
        Domain Availability Checker

Keyword is required.
Usage: ./tldhunt.sh -k <keyword> [-e <tld> | -E <exts>] [-x]
Example: ./tldhunt.sh -k linuxsec -E tlds.txt
```
Example of TLDHunt usage:
Use default TLD list
```
./tldhunt.sh -k linuxsec
```
Use custom TLD list
```
./tldhunt.sh -k linuxsec -E custom-tld.txt
```
You can add -x flag to print only **Not Registered** domain. Example:
```
./tldhunt.sh -k linuxsec -x
```
# Screenshot
![TLDHunt](https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEg1mrljuonzhjuuPoc9Bn_rH1X-drfrPHm1fYew52STZw7sHf8Pa6oQflj1ZOcm9FQKw7wVlRPn6gZDQoKFpnzXEe6bjcQ6dF8cMnKIkhbSHx4Mt9Qz24NaXgfTifapzuO3_8qP-1c53N0jLdotvi9bmbfIx8VyjP_ukDv_bu49kxLOBPFSlgRXXRfgAg/s782/tldhunt.png "TLDHunt")