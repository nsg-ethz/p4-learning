#!/usr/bin/env python3
import sys
import struct
import os

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet, IPOption, Ether, IP, raw
from scapy.all import ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.layers.inet import _IPOption_HDR

class CpuHeader(Packet):
    name = 'CpuPacket'
    fields_desc = [BitField("device_id",0,16), BitField('reason',0,16), BitField('counter', 0, 80)]

bind_layers(CpuHeader, Ether)

def handle_pkt(pkt):
    print("Controller got a packet")

    cpu_header = CpuHeader(raw(pkt))

    if cpu_header.reason == 200:
        cpu_header.show()

    sys.stdout.flush()

def main():
    if len(sys.argv) < 2:
        iface = 's1-cpu-eth1'
    else:
        iface = sys.argv[1]

    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
