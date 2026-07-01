#!/bin/bash
set -e

. /usr/local/bin/functions.sh

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

REPO_ROOT="/var/svn"
REPO_NAME="repo"
REPO_PATH="${REPO_ROOT}/${REPO_NAME}"

if ! id -u svn >/dev/null 2>&1; then
  echo "Creating svn user..."
  groupadd --gid ${SVN_GID:-1000} -r svn
  useradd --uid ${SVN_UID:-1000} -m -s /bin/bash -g svn svn
fi
chown -R svn:svn /home/svn
find /home/svn -type d -exec chmod 770 {} \;
find /home/svn -type f -exec chmod 660 {} \;
echo

if [ -d "${REPO_PATH}/conf" ]; then
  echo "Volume mounted in /var/svn already contains a repository"
else
  echo
  echo "********************************"
  echo "WARNING: No SVN repository exists"
  echo "WARNING: Creating a new empty repository"
  echo "********************************"
  echo
  svnadmin create "${REPO_PATH}"

  echo "Creating conf files"
  cat > "${REPO_PATH}/conf/svnserve.conf" <<EOF
[general]
anon-access = none
auth-access = write
password-db = passwd
authz-db = authz
EOF

cat > "${REPO_PATH}/conf/authz" <<EOF
[groups]
writers = svn
readers = 

[/]
* = r
@writers = rw
EOF
fi

chown -R svn:svn "${REPO_ROOT}"
find "${REPO_ROOT}" -type d -exec chmod 770 {} \;
find "${REPO_ROOT}" -type f -exec chmod 660 {} \;
echo

echo "Setting up ssh access..."
ssh-keygen -A

cat > /etc/ssh/sshd_config.d/subversion.conf <<EOF
PasswordAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no
AllowTcpForwarding no
X11Forwarding no
AllowAgentForwarding no
PermitTTY no
ForceCommand /usr/local/bin/wrapper.sh
MaxAuthTries 3
LoginGraceTime 20
MaxStartups 3:30:10
EOF

#install -d -m 0700 -o svn -g svn /home/svn/.ssh

echo "Recreating users from volume mounted as /home..."
recreate_users_from_home
echo


if [ "$START_NATIVE" -eq 1 ]; then
  echo "Starting svnserve in native mode..."  

  mkdir -p /var/svn/log /run/svnserve
  chown -R svn:svn /var/svn /run/svnserve

  su svn -c "svnserve --daemon --listen-port ${SVN_PORT:-3690} --pid-file /run/svnserve/svnserve.pid --root /var/svn --log-file /var/svn/log/svnserve.log"
  echo
fi

#ps -efa

echo "Setup complete"
echo
if [ -n "${SSH_PORT}" ] && [ $SSH_PORT -ne 22 ]; then
  echo "SSH is running on port ${SSH_PORT}. Use the following commands to access the repository:"
  echo "SVN_SSH=\"ssh -p ${SSH_PORT:-22}\" svn ls svn+ssh://user@host/repo"  
  echo "SVN_SSH=\"ssh -p ${SSH_PORT:-22} -i ~/path_to_private_key\" svn ls svn+ssh://user@host/repo"  
  echo
fi
echo "*********************************************"
echo "To add a new user:"
echo "docker exec -it <container_name> add-user [<username>] [<password>] [read|write]"
echo ""
echo "To delete an user:"
echo "docker exec -it <container_name> del-user <username>"
echo ""
echo "To list users:"
echo "docker exec -it <container_name> list-users"
echo "*********************************************"
echo


echo "Starting sshd..."
install -d -m 0755 -o root -g root /run/sshd
exec /usr/sbin/sshd -4 -D -e -p "${SSH_PORT:-22}"

#while [ 1 -eq 1 ]; do sleep 10; done