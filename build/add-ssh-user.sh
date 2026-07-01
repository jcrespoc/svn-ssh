#!/bin/sh

. /usr/local/bin/functions.sh

set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

if [ "$#" -gt 3 ]; then
  echo "Usage: add-ssh-user <username> [<password>] [read|write]" >&2
  exit 1
fi

NEW_USER="${1:-}"
NEW_PASS="${2:-}"
ACCESS_LEVEL="${3:-}"

[ -n "$NEW_USER" ] || read -p "Username: " NEW_USER
if [ -z "$NEW_USER" ]; then  
  exit 1
fi

case "$NEW_USER" in
  *[!a-zA-Z0-9._-]*|"")
    echo "Invalid username: only [a-zA-Z0-9._-]" >&2
    exit 1
    ;;
esac

if id -u "$NEW_USER" >/dev/null 2>&1; then
  echo "Existing user: $NEW_USER"
  USERMOD=1
  [ -n "$NEW_PASS" ] || read -p "Enter password for [$NEW_USER] (press Enter to keep unchanged): " NEW_PASS
  NEW_PASS="${NEW_PASS:-"-"}"
else
  [ -n "$NEW_PASS" ] || read -p "Enter password for [$NEW_USER] (press Enter to disable password access): " NEW_PASS
  NEW_PASS="${NEW_PASS:-$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)}"

  useradd -m -s /bin/bash -g svn "$NEW_USER"
fi

if [ "$NEW_PASS" != "-" ]; then
  echo "$NEW_USER:$NEW_PASS" | chpasswd
fi

[ -n "$ACCESS_LEVEL" ] || read -p "Enter access level for [$NEW_USER] (read/write, default: write): " ACCESS_LEVEL
ACCESS_LEVEL=${ACCESS_LEVEL:-"write"}  # Default value: write

install -d -m 700 -o "$NEW_USER" -g svn "/home/$NEW_USER/.ssh"
touch "/home/$NEW_USER/.ssh/authorized_keys"
chown "$NEW_USER:svn" "/home/$NEW_USER/.ssh/authorized_keys"
chmod 600 "/home/$NEW_USER/.ssh/authorized_keys"

read -p "Do you want to add the public key for [$NEW_USER] to /home/svn/.ssh/authorized_keys? (y/N): " RESP
if [ "$RESP" = "y" ] || [ "$RESP" = "Y" ] || [ "$RESP" = "s" ] || [ "$RESP" = "S" ]; then
  read -p "Enter the public key for [$NEW_USER]: " PUB_KEY
  echo "$PUB_KEY" >> "/home/$NEW_USER/.ssh/authorized_keys"
fi

/usr/sbin/sshd -t
pkill -HUP sshd || true

hash="$(getent shadow "$NEW_USER" | cut -d: -f2)"
touch "$SHADOW_DB"
chmod 600 "$SHADOW_DB"
chown root:root "$SHADOW_DB"

if grep -q "^${NEW_USER}:" "$SHADOW_DB"; then
  sed -i "s|^${NEW_USER}:.*|${NEW_USER}:${hash}:${ACCESS_LEVEL}|" "$SHADOW_DB"
else
  echo "${NEW_USER}:${hash}:${ACCESS_LEVEL}" >> "$SHADOW_DB"
fi


# Update /var/svn/repo/conf/authz
case "$ACCESS_LEVEL" in
  write)
    add_writer "$NEW_USER"
    ;;
  read)
    remove_writer "$NEW_USER"
    ;;
  *)
    echo "Invalid level: use read or write" >&2
    exit 1
    ;;
esac

echo "$NEW_USER created/updated"
