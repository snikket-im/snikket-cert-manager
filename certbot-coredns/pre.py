#!/usr/bin/env python3

# validate the NS and CNAME records
#   A/AAAA records for the name server are not validated
# start the DNS server with only basic records
#   will not contain any TXT records until auth.py is run

import os
import subprocess
import sys
import time
from textwrap import dedent

from common import write_or_update_master_file


def write_core_file( domain ):
    core_file = """
    . {{
      file /snikket/coredns/db.snikket.{domain} snikket.{domain} {{
        reload 1s
      }}
    }}
    """
    f = open( "/snikket/coredns/Corefile", "w" )
    f.write( dedent( core_file.format( domain = domain, ) ) )
    f.close()


def validate_dns_record( domain, record_name, expected_value, hint = "" ):
    print(
        "[PreHook] Validating '{}' record for '{}': "
        "expecting value of '{}'".format(
            record_name.upper(),
            domain,
            expected_value
        )
    )
    result = subprocess.run(
        [ "dig",
          domain,
          record_name.lower(),
          "+short" ],
        stdout = subprocess.PIPE
    )
    value = result.stdout.decode( "utf-8" ).strip()
    if value != expected_value:
        print(
            "[PreHook] '{}' record for '{}' needs to be "
            "set to '{}' but got '{}'".format(
                record_name.upper(),
                domain,
                expected_value,
                value
            )
        )
        if hint:
            print( hint )
        sys.exit( 1 )
    print(
        "[PreHook] Validated '{}' record for '{}'".format(
            record_name.upper(),
            domain,
        )
    )


def validate_cname_record( domain ):
    validate_dns_record(
        "_acme-challenge.{}".format( domain ),
        "cname",
        "cert.snikket.{}.".format( domain )
    )


def validate_ns_record( domain ):
    validate_dns_record(
        "snikket.{}".format( domain ),
        "ns",
        "ns-snikket.{}.".format( domain ),
        "[PreHook] Is the A/AAAA record of "
        "ns-snikket.{} correctly set?".format( domain )
    )


def validate_a_or_aaaa_record( domain ):
    if "SNIKKET_EXTERNAL_IP" in os.environ:
        validate_dns_record(
            "ns-snikket.{}".format( domain ),
            "aaaa" if ":" in os.environ[ "SNIKKET_EXTERNAL_IP" ] else "a",
            os.environ[ "SNIKKET_EXTERNAL_IP" ]
        )
    else:
        print(
            "[PreHook] Skipping A/AAAA check as "
            "SNIKKET_EXTERNAL_IP is not available"
        )


def main():
    domain = os.environ[ "SNIKKET_TWEAK_XMPP_DOMAIN" ]
    print( "[PreHook] Running for domain {}".format( domain ) )
    validate_a_or_aaaa_record( domain )
    validate_cname_record( domain )
    write_or_update_master_file( delete = True )
    write_core_file( domain )
    print( "[PreHook] Starting DNS server" )
    with open( "/dev/null", "w" ) as devnull:
        process = subprocess.Popen(
            [ "/usr/sbin/coredns",
              "--conf",
              "/snikket/coredns/Corefile" ],
            stdin = None,
            stdout = devnull,
            stderr = devnull,
            close_fds = True
        )
    print( "[PreHook] Writing PID" )
    with open( "/snikket/coredns/pid", "w" ) as f:
        f.write( str( process.pid ) )
    print( "[PreHook] Sleeping for 25s to ensure everything is up" )
    time.sleep( 25 )
    # now that the CoreDNS server is running
    # check for NS value
    validate_ns_record( domain )


if __name__ == "__main__":
    main()
