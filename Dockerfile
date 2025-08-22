FROM rust:1.83-bookworm AS agnos

RUN cargo install agnos

FROM debian:bookworm-slim

ARG BUILD_SERIES=dev
ARG BUILD_ID=0

VOLUME ["/snikket"]

ENTRYPOINT ["/usr/bin/tini"]
CMD ["/bin/bash", "/entrypoint.sh"]

COPY --from=agnos /usr/local/cargo/bin/agnos /usr/bin/agnos
COPY --from=agnos /usr/local/cargo/bin/agnos-generate-accounts-keys /usr/bin/agnos-generate-accounts-keys

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        certbot tini anacron idn2 jq libcap2-bin \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && rm -rf /var/cache/* \
    && mv /etc/cron.daily/0anacron /tmp \
    && rm /etc/cron.daily/* /etc/cron.d/* \
    && mv /tmp/0anacron /etc/cron.daily

RUN setcap 'cap_net_bind_service=+ep' /usr/bin/agnos

# Required for idn2 to work, and probably generally good
ENV LANG=C.UTF-8

ADD entrypoint.sh /entrypoint.sh
ADD certbot.cron /etc/cron.daily/certbot
ADD sendmail /usr/sbin/sendmail
ADD wait_for_http.py /usr/local/bin/wait_for_http.py
ADD tools/report-error.sh /usr/local/bin/report-error.sh
RUN chmod 555 /etc/cron.daily/certbot
RUN useradd -md /snikket/letsencrypt letsencrypt
