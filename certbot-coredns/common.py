#!/usr/bin/env python3

import os
import time
from textwrap import dedent

# converts email address to an SOA format, that is,
# @ is replaced by .
# dots in the username are replaced by \.
# for example,
# hostmaster@example.com becomes hostmaster.example.com
# host.master@example.com becomes host\.master.example.com
def email_to_rname(email):
    username, domain = email.split("@", 1)
    username = username.replace(".", "\\.")  # escape . in username
    return ".".join((username, domain))

# Creates or updates the RFC-1035 compliant file at master_file_path
# note that CoreDNS only reloads the file if serial of SOA changes
# this is why we rewrite the entire file with new timestamp
# even when we are updating / adding just a single record
def write_or_update_master_file(token = ""):
    master_file_content = """\
    ; Zone: SNIKKET.{domain}.

    $ORIGIN SNIKKET.{domain}.
    $TTL 300

    ; SOA Record
    @	 		IN	SOA	NS-SNIKKET.{domain}.	{email}.	(
    {serial}    ;serial
    300         ;refresh
    600         ;retry
    600         ;expire
    300         ;minimum ttl
    )

    ; NS Records
    @	IN	NS	NS-SNIKKET.{domain}.

    ; TXT Records
    {last_line}
    """
    domain = os.environ["SNIKKET_TWEAK_XMPP_DOMAIN"]
    master_file_path = "/snikket/coredns/db.snikket.{}".format(
        domain
    )
    if os.path.exists(master_file_path):
        with open(master_file_path, "r") as f:
            existing_master_file_content = f.read()
        existing_last_line = existing_master_file_content.strip(). \
                                split("\n")[-1]
    else:
        existing_last_line = ""
    existing_last_line = existing_last_line if "cert" in \
                         existing_last_line else ""
    if existing_last_line:  # already had a TXT record
        assert(token)       # so we must be updating
        last_line = \
            "{}\n    cert    IN  TXT  {}\n".format(
            existing_last_line,
            token
        )
    elif token:             # add a new token
        last_line = "cert    IN  TXT  {}\n".format(
            token
        )
    else:                   # initial set up without TXT
        last_line = ""
    with open(master_file_path, "w") as f:
        f.write(
            dedent(
                master_file_content.format(
                    domain = domain.upper(),
                    serial = int(time.time()),
                    email = email_to_rname(
                            os.environ["SNIKKET_ADMIN_EMAIL"]
                        ).upper(),
                    last_line = last_line
                )
            )
        )
