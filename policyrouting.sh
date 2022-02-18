#!/bin/sh
#Ivan Garnizov 18.03.2019
# expects entries in the iproute2/rt_tables for the interface with NETIF_source
# expects configured IP addresses for interfaces
# works even, if only IPv4 or IPv6 is configured
# integrates well only with Debian
NETIF=$1
CMD=$2
prio=$( awk "/^[0-9]+\s${NETIF}_source/ {print \$1}" /etc/iproute2/rt_tables )
if [ -n "$prio" ]; then
  case $CMD in 
  up)
    ipcmd=$(ip addr show dev ${NETIF} | sed -n '/scope global/p' | sed -e "s!\s\+inet \([^/]\+\)/[0-9]\+ .\+!/sbin/ip -4 route add table ${NETIF}_source default via \1; /sbin/ip -4 rule add prio $prio from \1 lookup ${NETIF}_source !g;" -e "s!\s\+inet6 \([^/]\+\)/[0-9]\+ .\+!/sbin/ip -6 route add table ${NETIF}_source default via \1; /sbin/ip -6 rule add prio $prio from \1 lookup ${NETIF}_source!g;" -e "s/ default via \([^ ]\+\)\([.:]\)[0-9]\+/ default via \1\21/g")
  ;;
  down)
    ipcmd=$(ip addr show dev ${NETIF} | sed -n '/scope global/p' | sed -e "s!\s\+inet \([^/]\+\)/[0-9]\+ .\+!/sbin/ip -4 route del default table ${NETIF}_source;/sbin/ip -4 rule del from \1 lookup ${NETIF}_source !g;" -e "s!\s\+inet6 \([^/]\+\)/[0-9]\+ .\+!/sbin/ip -6 route del default table ${NETIF}_source;/sbin/ip -6 rule del from \1 lookup ${NETIF}_source!g;" -e "s/ default via \([^ ]\+\)\([.:]\)[0-9]\+/ default via \1\21/g")
  ;;
  esac  
  IFS=';'
  for cmd in $ipcmd; do eval $cmd;  done
  
else
 /usr/bin/logger -p local0.notice -t ${0##*/}[$$] $1 interface has no routing policy config
 exit 0
fi
