#!/usr/bin/env python
from scapy.all import *
import sys
import threading


big_lock = threading.Lock()


class Receiver(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True

    def received(self, p):
        if p.haslayer(UDP):  # Ignore all other packets
            big_lock.acquire()
            print "Received one"
            big_lock.release()

    def run(self):
        sniff(iface="s1-eth2", prn=lambda x: self.received(x))


def main():
    try:
        packet_int = int(sys.argv[1])
        print "Sending packet with interval", packet_int
    except:
        print "Usage: sudo python send_and_receive.py <packet_int (seconds)>"
        sys.exit(1)

    Receiver().start()

    p = Ether(src="aa:aa:aa:aa:aa:aa") / IP(dst="10.0.1.2") / UDP()

    while True:
        big_lock.acquire()
        sendp(p, iface="s1-eth1", verbose=0)
        print "Sent one"
        big_lock.release()
        time.sleep(packet_int)


if __name__ == '__main__':
    main()
