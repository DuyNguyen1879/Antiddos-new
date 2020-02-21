#!/bin/sh
# IP that will be blocked, as detected by mod_evasive
IP=$1
# Full path to iptables
IPTABLES="/sbin/iptables"
# mod_evasive lock directory
MOD_EVASIVE_LOGDIR=/var/log/httpd/mod_evasive
# Add the following firewall rule (block all traffic coming from $IP)
$IPTABLES -I INPUT -s $IP -j DROP
# Remove lock file for future checks
rm -f "$MOD_EVASIVE_LOGDIR"/dos-"$IP"
