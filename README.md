# SVN+SSH Docker Container

Dockerized Subversion server

## Features

- **SVN repository** with per-user access control
- **SSH access** (svn+ssh://) with password or public key authentication
- **Permission control**: users with read or write access
- **Persistence**: external volumes for `/home` (users) and `/var/svn` (repository)
- **Automatic restore**: users and permissions are rebuilt when the container starts

## Quick Start

Create volumes on first run

```bash
docker volume create svn-root
docker volume create svn-homes
```

Build image

```bash
docker build ./build -t jcrespoc311/svn-ssh:latest
```

or download from <a href="https://hub.docker.com/repository/docker/jcrespoc311/svn-ssh/general">DockerHub</a>

```bash
docker pull jcrespoc311/svn-ssh:latest
```

### Start the container

By command line:
```bash
docker run \
    --name my-svn-ssh-server  \
    --rm \
    --detach \
    --volume svn-root:/var/svn \
    --volume svn-homes:/home \
    --env SVN_UID=1001 \
    --env SVN_GID=1001 \
    --env START_NATIVE=1 \
    jcrespoc311/svn-ssh:latest
```

Or by docker-compose:
```bash
docker compose up -d
```

### Add a user

```bash
docker exec -it svn-ssh add-user <username> [<password>] [read|write]
```

- `username`: user name
- `password`: password (optional; if omitted, a random one is generated)
- `read|write`: access level (default: read)

Examples:
```bash
docker exec -it svn-ssh add-user alice micontraseña write
docker exec -it svn-ssh add-user bob read
```

### Delete a user

```bash
docker exec -it svn-ssh del-user <username>
```

### List users

```bash
docker exec -it svn-ssh list-users
```

## Configuration

Define values in `.env` or pass variables to `docker compose up`:

| Variable | Default | Description |
|----------|---------|-------------|
| `SSH_PORT` | 22 | Exposed SSH port |
| `SVN_PORT` | 3690 | Native SVN port (svn://) |
| `SVN_UID` | 1001 | SVN user UID |
| `SVN_GID` | 1001 | SVN user GID |
| `START_NATIVE` | (empty) | Set to `1` to start `svnserve` |

Example with a custom SSH port:

```bash
SSH_PORT=65022 docker compose up -d
```

## Repository Access

### Via SSH (recommended)

```bash
# With password
svn ls svn+ssh://usuario@host:65022/repo

# With SSH key
SVN_SSH="ssh -i ~/.ssh/id_rsa -p 65022" svn ls svn+ssh://usuario@host/repo
```

### Via native protocol (if START_NATIVE=1)

```bash
svn ls svn://localhost:3690/repo
```

## Volume Layout

- **svn-homes**: `/home` - user directories for public key configuration in `.ssh/authorized_keys`
- **svn-root**: `/var/svn` - SVN repository

Both volumes are **external** (must be created manually) and persistent.

## Important Files

- `build/setup.sh` - Container initialization
- `build/functions.sh` - User management functions
- `build/add-ssh-user.sh` - Script to add users
- `build/del-ssh-user.sh` - Script to delete users
- `build/list-ssh-user.sh` - Script to list users
- `build/wrapper.sh` - Wrapper used by SSH ForceCommand

## Security Notes

- **PermitTTY no** - SSH users cannot open interactive shell sessions
- **ForceCommand** - All SSH commands are routed through `wrapper.sh` (svn+ssh)
- **SSH_PORT** - Change from default port 22 when possible
- **authorized_keys** - Mount public keys in `/home/<user>/.ssh/` for passwordless authentication

## Troubleshooting

### Container does not start
Check external volumes:
```bash
docker volume ls | grep svn
```

If they do not exist:
```bash
docker volume create svn-homes
docker volume create svn-root
```
