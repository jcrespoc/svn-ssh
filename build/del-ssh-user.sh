#!/bin/sh

. /usr/local/bin/functions.sh

set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: del-ssh-user <username>" >&2
  exit 1
fi

DEL_USER="${1:-}"

[ -n "$DEL_USER" ] || read -p "Username: " DEL_USER
if [ -z "$DEL_USER" ]; then  
  exit 1
fi


MINUID=$(id -u svn 2>/dev/null || echo 1000)
uid=$(id -u "$DEL_USER" 2>/dev/null || echo "")

if [ -n "$uid" ] && [ "$uid" -gt "$MINUID" ]; then
  userdel -r "$DEL_USER" 2>/dev/null 
else
  echo "User $DEL_USER does not exist"
  exit 1
fi

/usr/sbin/sshd -t
pkill -HUP sshd || true

# Update /var/svn/repo/conf/authz
remove_writer "$DEL_USER"
  
echo "$DEL_USER removed"
