#!/bin/sh

. /usr/local/bin/functions.sh

printf "%-10s %-8s %-3s %-8s\n" "usuario" "level" "key" "password"
printf "%-10s %-8s %-3s %-8s\n" "----------------------------------------------"

for d in /home/*; do
  [ -d "$d" ] || continue
  u="$(basename "$d")"

  case "$u" in
    root|svn|lost+found) continue ;;
  esac

  if id -u "$u" >/dev/null 2>&1; then
    ACCESS_LEVEL="$(user_access_level "$u")"
    access_type "$u"
    printf "%-10s %-8s %-3s %-8s\n" "$u" "$ACCESS_LEVEL" "$KEY" "$PASSWORD"
    continue
  fi
done
