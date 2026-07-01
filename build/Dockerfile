FROM debian:12-slim

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

ARG SVN_UID=1000
ARG SVN_GID=1000

RUN echo "LANG=C.UTF-8" >> /etc/environment && \
    echo "LC_ALL=C.UTF-8" >> /etc/environment

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
        apt-get install -q -y openssh-server subversion && \
        apt-get clean

COPY setup.sh /root/setup.sh
RUN chmod +x /root/setup.sh

COPY add-ssh-user.sh /usr/local/bin/add-user
COPY del-ssh-user.sh /usr/local/bin/del-user
COPY list-ssh-user.sh /usr/local/bin/list-users
COPY functions.sh /usr/local/bin
RUN chmod 700 /usr/local/bin/add-user /usr/local/bin/del-user /usr/local/bin/list-users /usr/local/bin/functions.sh

COPY wrapper.sh /usr/local/bin/wrapper.sh
RUN chmod 755 /usr/local/bin/wrapper.sh

CMD ["sh", "-c", "/root/setup.sh"]
