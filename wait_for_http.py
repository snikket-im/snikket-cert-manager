#!/usr/bin/python3

import requests
import sys
import time
from datetime import datetime

url = sys.argv[1]

sys.stdout.write("Waiting for HTTP to be available")

time_start = datetime.now()

for i in range(1, 100):
    try:
        r = requests.head(url)
        r.raise_for_status()
    except requests.exceptions.HTTPError:
        sys.stdout.write(".")
    except requests.exceptions.ConnectionError:
        sys.stdout.write("!")
    else:
        time_taken = datetime.now() - time_start
        sys.stdout.write(
            f"\nHTTP is available after {time_taken.seconds:0.2f}s (attempt {i})\n"
        )
        sys.exit(0)
    finally:
        sys.stdout.flush()
        if not i % 10:
            sys.stdout.write("\n")

    time.sleep(i**0.8)

sys.exit(1)
