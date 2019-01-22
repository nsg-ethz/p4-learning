#!/usr/bin/env python
import sys
from p4utils.utils.tcp_utils import *

import time

def main(port=5000):

    receiver = Receiver(port)
    receiver.listen()

    #if it managed to connect it is already 2 packets (if no failure...)
    print "Received 1"
    print "Received 2"

    msg = receiver.recv()
    n=3
    try:
        while msg:
            print "Received ", n
            n +=1
            msg = receiver.recv()
    except KeyboardInterrupt:
        receiver.close()


if __name__ == '__main__':

    if len(sys.argv) != 2:
        print "Invalid number of arguments. Run as receive.py <port_number>"

    main(int(sys.argv[1]))
