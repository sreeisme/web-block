#!/usr/bin/env bash

# Script Name: web_block.sh
# Description: Block or unblock websites by modifying the hosts file.
#
# Usage: sudo ./web_block.sh [--add|--remove] domain1 [domain2 ... domainN]
#
# Options:
#   --add       Block the specified domain(s).
#   --remove    Unblock the specified domain(s).

HOSTS_FILE="/etc/hosts"

function show_help {
    echo "Usage: sudo $0 [--add|--remove] domain1 [domain2 ... domainN]"
    echo "  --add       Block the specified domain(s)."
    echo "  --remove    Unblock the specified domain(s)."
    exit 1
}

function validate_domain {
    local domain="$1"
    local domain_regex='^([a-zA-Z0-9](-?[a-zA-Z0-9])*\.)+[a-zA-Z]{2,}$'
    if ! [[ $domain =~ $domain_regex ]]; then
        echo "Error: Invalid domain name '$domain'."
        exit 1
    fi
}

function modify_hosts {
    local action="$1"
    shift
    local domains=("$@")

    for domain in "${domains[@]}"; do
        validate_domain "$domain"
        local entry="127.0.0.1 $domain"
        case "$action" in
            add)
                if grep -qF "$entry" "$HOSTS_FILE"; then
                    echo "Domain '$domain' is already blocked."
                else
                    echo "$entry" >> "$HOSTS_FILE"
                    echo "Blocked domain '$domain'."
                fi
                ;;
            remove)
                if grep -qF "$entry" "$HOSTS_FILE"; then
                    sed -i "/^127\.0\.0\.1 $domain$/d" "$HOSTS_FILE"
                    echo "Unblocked domain '$domain'."
                else
                    echo "Domain '$domain' is not currently blocked."
                fi
                ;;
            *)
                echo "Error: Invalid operation."
                exit 1
                ;;
        esac
    done
}

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

if [ "$#" -lt 2 ]; then
    show_help
fi

OPERATION="$1"
shift

case "$OPERATION" in
    --add)
        modify_hosts add "$@"
        ;;
    --remove)
        modify_hosts remove "$@"
        ;;
    *)
        show_help
        ;;
esac

exit 0
