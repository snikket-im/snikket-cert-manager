#!/usr/bin/env python3

import os
import signal


def main():
    if os.path.exists( "/snikket/coredns/pid" ):
        print( "[PostHook] Killing CoreDNS" )
        with open( "/snikket/coredns/pid" ) as f:
            pid = f.read()
        os.kill( int( pid ), signal.SIGTERM )
    else:
        print(
            "[PostHook] Did not find CoreDNS PID, likely due to error in PreHook"
        )
    print( "[PostHook] Removing config files" )
    os.remove( "/snikket/coredns/pid" )
    os.remove( "/snikket/coredns/Corefile" )
    os.remove(
        "/snikket/coredns/db.snikket.{}".format(
            os.environ[ "SNIKKET_TWEAK_XMPP_DOMAIN" ]
        )
    )


if __name__ == "__main__":
    main()
