#!/usr/bin/env python
import sys
import struct

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet, IPOption
from scapy.all import IP, UDP, Raw, Ether
from scapy.layers.inet import _IPOption_HDR
from scapy.fields import *

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface


def handle_pkt(pkt):
    print "got a packet"
    pkt.show2()
#    hexdump(pkt)
    sys.stdout.flush()

class SourceRoute(Packet):
   fields_desc = [ BitField("last_header", 0, 1),
                   BitField("swid", 0, 7)]
class SourceRoutingTail(Packet):
   fields_desc = [ XShortField("etherType", 0x800)]

bind_layers(Ether, SourceRoute, type=0x1111)
bind_layers(SourceRoute, SourceRoute, last_header=0)
bind_layers(SourceRoute, SourceRoutingTail, last_header=1)

def main():
    iface = 'h2-eth0'
    print "sniffing on %s" % iface
    sys.stdout.flush()
    sniff(filter="udp and port 4321", iface = iface,
          prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
