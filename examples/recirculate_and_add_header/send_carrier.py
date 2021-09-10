#!/usr/bin/env python3
from scapy.all import sendp, send, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet
from scapy.all import Ether, IP, UDP
from scapy.fields import *

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

class CARRIER(Packet):
    fields_desc = [BitField("length", 0, 8)]


bind_layers(Ether, CARRIER, type=0x1234)

def send_carrier(length):

    iface= get_if()

    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x1234);
    pkt = pkt/CARRIER(length=length)
    sendp(pkt, iface=iface, verbose=False)

if __name__ == '__main__':

    import sys
    send_carrier(int(sys.argv[1]))
