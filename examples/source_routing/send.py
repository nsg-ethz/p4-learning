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

class SourceRoute(Packet):
   fields_desc = [ BitField("last_header", 0, 1),
                   BitField("swid", 0, 7)]

bind_layers(Ether, SourceRoute, type=0x1111)
bind_layers(SourceRoute, SourceRoute, last_header=0)
bind_layers(SourceRoute, IP, last_header=1)

def main():

    if len(sys.argv)<2:
        print 'pass 2 arguments: <destination>'
        exit(1)

    addr = socket.gethostbyname(sys.argv[1])
    iface = get_if()
    print "sending on interface %s to %s" % (iface, str(addr))

    while True:
        print
        s = str(raw_input('Type space separated switch_ids nums '
                          '(example: "2 3 2 2 1") or "q" to quit: '))
        if s == "q":
            break;
        print

        i = 0
        pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff');
        for p in s.split(" "):
            try:
                pkt = pkt / SourceRoute(last_header=0, swid=int(p))
                i = i+1
            except ValueError:
                pass
        if pkt.haslayer(SourceRoute):
            pkt.getlayer(SourceRoute, i).last_header = 1

        pkt = pkt / IP(dst=addr) / UDP(dport=4321, sport=1234)
        pkt.show2()
        sendp(pkt, iface=iface, verbose=False)

    #pkt = pkt / SourceRoute(bos=0, port=2) / SourceRoute(bos=0, port=3);
    #pkt = pkt / SourceRoute(bos=0, port=2) / SourceRoute(bos=0, port=2);
    #pkt = pkt / SourceRoute(bos=1, port=1)


if __name__ == '__main__':
    main()
