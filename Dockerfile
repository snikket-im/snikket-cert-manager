FROM debian:bookworm-slim

ARG BUILD_SERIES=dev
ARG BUILD_ID=0

VOLUME ["/snikket"]

ENTRYPOINT ["/usr/bin/tini"]
CMD ["/bin/bash", "/entrypoint.sh"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        certbot tini anacron jq \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && rm -rf /var/cache/* \
    && mv /etc/cron.daily/0anacron /tmp \
    && rm /etc/cron.daily/* /etc/cron.d/* \
    && mv /tmp/0anacron /etc/cron.daily

ADD entrypoint.sh /entrypoint.sh
ADD certbot.cron /etc/cron.daily/certbot
ADD sendmail /usr/sbin/sendmail
ADD wait_for_http.py /usr/local/bin/wait_for_http.py
RUN chmod 555 /etc/cron.daily/certbot
RUN useradd -md /snikket/letsencrypt letsencrypt
