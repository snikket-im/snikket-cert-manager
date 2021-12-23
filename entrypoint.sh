#!/bin/bash

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

export SNIKKET_DNS_CHALLENGE=${SNIKKET_DNS_CHALLENGE:-0}
if [ $SNIKKET_DNS_CHALLENGE = 0 ]; then
        if [ -z $SNIKKET_TWEAK_XMPP_DOMAIN ]; then
          :
        else
          export SNIKKET_DNS_CHALLENGE=1
        fi
else
        if [ -z $SNIKKET_TWEAK_XMPP_DOMAIN ]; then
          export SNIKKET_TWEAK_XMPP_DOMAIN=$SNIKKET_DOMAIN
        fi
fi
if [ $SNIKKET_DNS_CHALLENGE = 1 ]; then
        if ! test -d /snikket/coredns; then
                install -o letsencrypt -g letsencrypt -m 750 -d /snikket/coredns;
        fi
        chown -R letsencrypt:letsencrypt /snikket/coredns
fi

exec /bin/sh -c "/usr/sbin/anacron -d -n && sleep 3600"
