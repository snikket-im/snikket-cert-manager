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

if ! chown -R letsencrypt:letsencrypt /snikket/letsencrypt; then
	echo "WW: Failed to adjust the permissions of some files/directories";
fi

export SNIKKET_DOMAIN_ASCII=$(idn2 "$SNIKKET_DOMAIN")

if [ "${SNIKKET_CERTS_WAIT-0}" = "1" ]; then
	/usr/local/bin/wait_for_http.py "http://${SNIKKET_DOMAIN_ASCII}";
fi

# Run once, now
/usr/sbin/anacron -d -n;

# Run every hour
while sleep 3600; do
	/usr/sbin/anacron -d -n;
done
