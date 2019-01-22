#!/usr/bin/env python
import sys
import os

from scapy.all import sniff, get_if_list, Ether, get_if_hwaddr, IP, Raw, Packet, BitField, bind_layers

def get_if():
    iface=None
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface

class Telemetry(Packet):
   fields_desc = [ BitField("enq_depth", 0, 16),
                   #BitField("deq_depth", 0, 16),
                   BitField("nextHeaderType", 0, 16)]

def isNotOutgoing(my_mac):
    my_mac = my_mac
    def _isNotOutgoing(pkt):
        return pkt[Ether].src != my_mac

    return _isNotOutgoing

def handle_pkt(pkt):

    ether = pkt.getlayer(Ether)

    telemetry = pkt.getlayer(Telemetry)
    print "Queue Info:"
    print "enq_depth", telemetry.enq_depth
    #print "deq_depth", telemetry.deq_depth
    print

bind_layers(Ether, Telemetry, type=0x7777)


def main():
    ifaces = filter(lambda i: 'eth' in i, os.listdir('/sys/class/net/'))
    iface = ifaces[0]
    print "sniffing on %s" % iface
    sys.stdout.flush()

    my_filter = isNotOutgoing(get_if_hwaddr(get_if()))

    sniff(filter="ether proto 0x7777", iface = iface,
          prn = lambda x: handle_pkt(x), lfilter=my_filter)

if __name__ == '__main__':
    main()