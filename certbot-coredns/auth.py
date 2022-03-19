#!/usr/bin/env python3

import os
import subprocess
import time

from common import write_or_update_master_file


def main():
    # make sure certificates are being fetched for
    # the correct Snikket domain
    domain = os.environ[ "CERTBOT_DOMAIN" ]
    print( "[AuthHook] Obtaining certificates for {}".format( domain ) )
    if domain.startswith( "*." ):
        domain = domain[ 2 : ]
    assert ( domain == os.environ[ "SNIKKET_TWEAK_XMPP_DOMAIN" ] )
    token = os.environ[ "CERTBOT_VALIDATION" ]
    print( "[AuthHook] Writing TXT record {}".format( token ) )
    write_or_update_master_file( token )
    print( "[AuthHook] Waiting for 25s to propagate TXT record" )
    # below section does not seem to work well
    # that is, it gives old data
    # perhaps this needs to be done @1.1.1.1
    # but that is not good for privacy
    # so just do a sleep instead
    # fetched_tokens = []
    # while len(fetched_tokens) < 1:
    #     result = subprocess.run(["dig", "-t", "txt",
    #                         "cert.snikket.{}".format(domain),
    #                         "+short"],
    #                         stdout=subprocess.PIPE)
    #     fetched_tokens = result.stdout.decode("utf-8"). \
    #             replace('"', '').strip().split("\n")
    #     if token not in fetched_tokens:
    #         print(
    #             "[AuthHook] Got different record {}".format(
    #                 fetched_tokens
    #             )
    #         )
    #         fetched_tokens = []
    time.sleep( 25 )  # how long Certbot example waits
    print( "[AuthHook] Done waiting" )


if __name__ == "__main__":
    main()
