#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet
from scapy.all import Ether, IP, UDP
from scapy.fields import *
import readline

def get_if():
    ifs=get_if_list()
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface


#bind_layers(SourceRoute, SourceRoute, last_header=0)
#bind_layers(SourceRoute, IP, last_header=1)

def main():

    iface = get_if()

    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x1234);
    #triggers the broadcast every second
    while True:
        sendp(pkt, iface=iface, verbose=False)
        time.sleep(1)

if __name__ == '__main__':
    main()
