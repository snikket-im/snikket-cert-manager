FROM coredns/coredns:latest AS coredns
# this image is only used for copying coredns binary
# ca-certificates are added by apt below

FROM debian:buster-slim
COPY --from=coredns /coredns /usr/sbin/coredns

ARG BUILD_SERIES=dev
ARG BUILD_ID=0

VOLUME ["/snikket"]

EXPOSE 53 53/udp

ENTRYPOINT ["/usr/bin/tini"]
CMD ["/bin/sh", "/entrypoint.sh"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        certbot tini anacron ca-certificates python3 dnsutils \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && rm -rf /var/cache/* \
    && mv /etc/cron.daily/0anacron /tmp \
    && rm /etc/cron.daily/* \
    && mv /tmp/0anacron /etc/cron.daily

ADD entrypoint.sh /entrypoint.sh
ADD certbot.cron /etc/cron.daily/certbot
ADD sendmail /usr/sbin/sendmail
RUN chmod 555 /etc/cron.daily/certbot
RUN useradd -md /snikket/letsencrypt letsencrypt
COPY certbot-coredns /certbot-coredns
