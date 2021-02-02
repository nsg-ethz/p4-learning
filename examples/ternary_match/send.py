#!/usr/bin/env python
import sys
import socket
import random
from subprocess import Popen, PIPE
import re

from scapy.all import sendp, get_if_list, get_if_hwaddr
from scapy.all import Ether, IP, UDP, TCP

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

def get_dst_mac(ip):

    try:
        pid = Popen(["arp", "-n", ip], stdout=PIPE)
        s = pid.communicate()[0]
        mac = re.search(r"(([a-f\d]{1,2}\:){5}[a-f\d]{1,2})", s).groups()[0]
        return mac
    except:
        return None

def main():

    if len(sys.argv)<3:
        print 'pass 2 arguments: <destination> "<message>"'
        exit(1)

    addr = socket.gethostbyname(sys.argv[1])
    iface = get_if()

    if len(sys.argv) > 3:
        tos = int(sys.argv[3]) % 256
    else:
        tos = 0

    #ether_dst = get_dst_mac(addr)

    print "Sending on interface %s to %s" % (iface, str(addr))
    pkt =  Ether(src=get_if_hwaddr(iface), dst="01:01:01:01:01:01")
    pkt = pkt /IP(dst=addr,tos=tos) / sys.argv[2]
    sendp(pkt, iface=iface, verbose=False)


if __name__ == '__main__':
    main()