# SVN+SSH Docker Container

Servidor subversion dockerizado

## Características

- **Repositorio SVN** con control de acceso por usuarios
- **Acceso vía SSH** (svn+ssh://) con autenticación por contraseña o clave pública
- **Control de permisos**: usuarios con acceso lectura o escritura
- **Persistencia**: volúmenes externos para `/home` (usuarios) y `/var/svn` (repositorio)
- **Restauración automática**: usuarios y permisos se reconstruyen al levantar el contenedor

## Quick Start

### Levantar el contenedor

```bash
docker compose up -d
```

### Agregar un usuario

```bash
docker exec -it svn-ssh add-user <username> [<password>] [read|write]
```

- `username`: nombre del usuario
- `password`: contraseña (opcional; si no se proporciona, se genera una aleatoria)
- `read|write`: nivel de acceso (defecto: read)

Ejemplos:
```bash
docker exec -it svn-ssh add-user alice micontraseña write
docker exec -it svn-ssh add-user bob read
```

### Eliminar un usuario

```bash
docker exec -it svn-ssh del-user <username>
```

### Listar usuarios

```bash
docker exec -it svn-ssh list-users
```

## Configuración

Define en el `.env` o pasa variables a `docker compose up`:

| Variable | Defecto | Descripción |
|----------|---------|-------------|
| `SSH_PORT` | 22  | Puerto SSH expuesto |
| `SVN_PORT` | 3690 | Puerto SVN nativo (svn://) |
| `SVN_UID` | 1001 | UID del usuario SVN |
| `SVN_GID` | 1001 | GID del usuario SVN |
| `START_NATIVE` | (vacío) | '1' Inicia svnserve |

Ejemplo con puerto SSH personalizado:

```bash
SSH_PORT=65022 docker compose up -d
```

## Acceso al repositorio

### Vía SSH (recomendado)

```bash
# Con contraseña
svn ls svn+ssh://usuario@host:65022/repo

# Con clave SSH
SVN_SSH="ssh -i ~/.ssh/id_rsa -p 65022" svn ls svn+ssh://usuario@host/repo
```

### Vía protocolo nativo (si START_NATIVE=1)

```bash
svn ls svn://localhost:3690/repo
```

## Estructura de volúmenes

- **svn-homes**: `/home` - directorios de usuarios para configuracion de claves publicas `.ssh/authorized_keys`
- **svn-root**: `/var/svn` - repositorio SVN

Ambos volúmenes son **externos** (se han de crear manualmente) y persistentes.

## Archivos importantes

- `build/setup.sh` - Inicialización del contenedor
- `build/functions.sh` - Funciones para gestión de usuarios
- `build/add-ssh-user.sh` - Script para agregar usuarios
- `build/del-ssh-user.sh` - Script para eliminar usuarios
- `build/list-ssh-user.sh` - Script para listar usuarios
- `build/wrapper.sh` - Envoltorio para ForceCommand de SSH

## Notas de seguridad

- **PermitTTY no** - Los usuarios SSH no pueden abrir sesiones interactivas
- **ForceCommand** - Todos los comandos SSH se rutean a través de `wrapper.sh` (svn+ssh)
- **SSH_PORT** - Cambia del puerto 22 por defecto si es posible
- **authorized_keys** - Monta claves públicas en `/home/<usuario>/.ssh/` para autenticación sin contraseña

## Resolución de problemas

### El contenedor no inicia
Revisa los volúmenes externos:
```bash
docker volume ls | grep svn
```

Si no existen:
```bash
docker volume create svn-homes
docker volume create svn-root
```
