AUTHZ_FILE="/var/svn/repo/conf/authz"
SHADOW_DB="/home/.users.shadow"

user_access_level() {
  user="$1"
  if grep "^writers = .*${user}" /var/svn/repo/conf/authz > /dev/null; then 
    echo write
  else
    echo read
  fi
}

access_type() {
  user="$1"
  KEY="no"
  PASSWORD="no"

  hash="$(getent shadow "$user" | cut -d: -f2)"
  if [ "$hash" != "!" ]; then
    PASSWORD="SI"
  fi

  if [ -s /home/$user/.ssh/authorized_keys ]; then
    KEY="SI"
  fi
}

add_writer() {
  user="$1"

  if grep -Eq "^writers = .*([,[:space:]])${user}([,[:space:]]|$)" "$AUTHZ_FILE"; then
    return 0
  fi

  if grep -q "^writers =" "$AUTHZ_FILE"; then
    sed -i -E "s|^(writers = .*)$|\1,${user}|" "$AUTHZ_FILE"
  else
    sed -i "/^\[groups\]/a writers = ${user}" "$AUTHZ_FILE"
  fi
}

remove_writer() {
  user="$1"

  sed -i -E "
    /^writers = /{
      s/(^writers = )([^#]*),${user}(,|$)/\1\2\3/
      s/(^writers = )${user}(,|$)/\1/
      s/,\s*,/,/g
      s/,\s*$//
    }
  " "$AUTHZ_FILE"
}

recreate_users_from_home() {
  for d in /home/*; do
    [ -d "$d" ] || continue
    u="$(basename "$d")"

    case "$u" in
      root|svn|lost+found) continue ;;
    esac

    if id -u "$u" >/dev/null 2>&1; then
      echo "User $u already exists"
      continue
    fi

    # Reusar UID/GID del directorio home persistido para evitar desajustes
    uid="$(stat -c %u "$d")"
    gid="$(stat -c %g "$d")"

    # Si el GID no existe, usar grupo svn
    if getent group "$gid" >/dev/null 2>&1; then
      grp="$gid"
    else
      grp="svn"
    fi

    grp="svn"

    # Intentar crear con UID original; si está ocupado, crear sin UID fijo
    if ! useradd -M -d "$d" -s /bin/bash -u "$uid" -g "$grp" "$u" 2>/dev/null; then
      useradd -M -d "$d" -s /bin/bash -g svn "$u"
    fi

    chown -R "$u:svn" "$d"

    # Si existe authorized_keys, reforzar permisos
    if [ -f "$d/.ssh/authorized_keys" ]; then
      chmod 700 "$d/.ssh" 2>/dev/null || true
      chmod 600 "$d/.ssh/authorized_keys" 2>/dev/null || true
      chown -R "$u:svn" "$d/.ssh" 2>/dev/null || true
    fi

    if [ -f "$SHADOW_DB" ]; then
      hash="$(awk -F: -v u="$u" '$1==u{print $2}' "$SHADOW_DB")"
      if [ -n "$hash" ]; then
        echo "Restoring $u"
        usermod -p "$hash" "$u"
        ACCESS_LEVEL="$(awk -F: -v u="$u" '$1==u{print $3}' "$SHADOW_DB")"
        if [ -n "$ACCESS_LEVEL" ]; then
          case "$ACCESS_LEVEL" in
            write)
              add_writer "$u"
              ;;
            read)
              remove_writer "$u"
              ;;
            *)
              echo "Invalid level $ACCESS_LEVEL" >&2
              ;;
          esac
        fi
      fi
    fi
  done
}
