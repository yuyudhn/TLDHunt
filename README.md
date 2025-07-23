# TLDHunt - Domain Availability Checker
TLDHunt is a command-line tool designed to help users find available domain names for their online projects or businesses. By providing a keyword and a list of TLD (top-level domain) extensions, TLDHunt checks the availability of domain names that match the given criteria. This tool is particularly useful for those who want to quickly find a domain name that is not already taken, without having to perform a manual search on a domain registrar website.

For red teaming or phishing purposes, this tool can help you to find similar domains with different extensions from the original domain.

> [!NOTE]  
> Tested on: **Kali GNU/Linux Rolling** with **whois v5.5.15**

# Dependencies
This tool is written in Bash and requires the following dependencies:
- **whois**: Used to check domain availability.
- **curl**: Used to fetch the latest TLD list from IANA.

Make sure these are installed on your system. In Debian-based systems, you can install them using the following command:
```
sudo apt install whois curl -y
```

# How It Works?
To detect whether a domain is registered or not, we search for the words "**Name Server**", "**nserver**", "**nameservers**", or "**status: active**" in the output of the WHOIS command, as this is a signature of a registered domain (thanks to [Alex Matveenko](https://github.com/Alex-Matveenko) for the suggestion). 

If you have a better signature or detection method, please feel free to submit a pull request.

# Domain Extension List
For the default Top Level Domain list (`tlds.txt`), we use data from https://data.iana.org. You can update this list directly using the `--update-tld` flag, which fetches the latest TLDs from IANA and saves them to `tlds.txt`.

You can also use a custom TLD list, but ensure it is formatted like this:
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
Usage: ./tldhunt.sh -k <keyword> [-e <tld> | -E <exts>] [-x] [--update-tld]
Example: ./tldhunt.sh -k linuxsec -E tlds.txt
       : ./tldhunt.sh --update-tld
```

### Examples
Update the default TLD list from IANA:
```bash
./tldhunt.sh --update-tld
```

Check domain availability using the default TLD list:
```bash
./tldhunt.sh -k linuxsec -E tlds.txt
```

Check domain availability using a custom TLD list:
```bash
./tldhunt.sh -k linuxsec -E custom-tld.txt
```

Show only unregistered domains:
```bash
./tldhunt.sh -k linuxsec -E tlds.txt --not-registered
```

# Screenshot
![TLDHunt](https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEiH2w600_IzO7BX6TmRECWzHu3aXlxsMVVBsvCk5cZ56x6v341edcGB3ByhhFiojjpkenLxShLVu5mpUeO9PO05Rv37fjylD2f5rpHodI8-6YelfVKXuvOcjbvlIgVteTtNpnaHYAm_xz9n7Q86ln6U9SAgUV6y65Dfg6UAdc-bb-vyHmuHvp63-Qlujlwx/s949/tldhunt.png "TLDHunt")