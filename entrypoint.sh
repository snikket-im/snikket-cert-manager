#!/bin/bash

set -euo pipefail

PUID=${PUID:=$(stat -c %u /snikket)}
PGID=${PGID:=$(stat -c %g /snikket)}

if [ "$PUID" != 0 ] && [ "$PGID" != 0 ]; then
        usermod  -o -u "$PUID" letsencrypt
        groupmod -o -g "$PGID" letsencrypt
fi

if ! test -d /snikket/letsencrypt; then
        install -o letsencrypt -g letsencrypt -m 750 -d /snikket/letsencrypt;
fi

install -o letsencrypt -g letsencrypt -m 750 -d /var/lib/letsencrypt;
install -o letsencrypt -g letsencrypt -m 750 -d /var/log/letsencrypt;
install -o letsencrypt -g letsencrypt -m 755 -d /var/www/.well-known/acme-challenge;

chown -R letsencrypt:letsencrypt /snikket/letsencrypt

exec /bin/sh -c "/usr/sbin/anacron -d -n && sleep 3600"
