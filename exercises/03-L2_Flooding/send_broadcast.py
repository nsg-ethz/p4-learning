#!/usr/bin/env python3
import sys
import socket
import random
import time
from threading import Thread, Event
from scapy.all import *


def get_if():
    ifs=get_if_list()
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break
    if not iface:
        print("Cannot find eth0 interface")
        exit(1)
    return iface

def send_packet(iface):

    input("Press the return key to send a packet:")
    print("Sending on interface %s\n" % (iface))
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff:ff')
    pkt = pkt
    sendp(pkt, iface=iface, verbose=False)

def main():

    iface = get_if()

    while True:
        send_packet(iface)
        time.sleep(0.1)


if __name__ == '__main__':
    main()