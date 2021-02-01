FROM debian:buster-slim

ARG BUILD_SERIES=dev
ARG BUILD_ID=0

VOLUME ["/snikket"]

ENTRYPOINT ["/usr/bin/tini"]
CMD ["/bin/sh", "/entrypoint.sh"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        certbot tini anacron \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && rm -rf /var/cache/*

ADD entrypoint.sh /entrypoint.sh
ADD certbot.cron /etc/cron.daily/certbot
ADD sendmail /usr/sbin/sendmail
RUN chmod 555 /etc/cron.daily/certbot
RUN useradd -md /snikket/letsencrypt letsencrypt
