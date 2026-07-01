#!/bin/sh
exec svnserve -t --root /var/svn --log-file /var/svn/log/svnserve.log --tunnel-user="$(id -un)"