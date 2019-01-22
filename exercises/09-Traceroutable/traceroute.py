#!/usr/bin/python
import socket
import random
import os
import struct
import fcntl

class TimeoutError(Exception):
    pass

#### DEFINITION OF TCP,UDP,ICMP, AND IP CLASSES. I use them to parse headers.
class iphdr(object):
    """
    This represents an IP packet header.
    @assemble packages the packet
    @disassemble disassembles the packet
    """
    def __init__(self, proto=socket.IPPROTO_ICMP, src="0.0.0.0", dst=None):
        self.version = 4
        self.hlen = 5
        self.tos = 128
        self.length = 20
        self.id = random.randint(2 ** 10, 2 ** 16)
        self.frag = 0
        self.ttl = 255
        self.proto = proto
        self.cksum = 0
        self.src = src
        self.saddr = socket.inet_aton(src)
        self.dst = dst or "0.0.0.0"
        self.daddr = socket.inet_aton(self.dst)
        self.data = ""

    @classmethod
    def disassemble(self, data):
        # DATA has to be the first 20 bytes of the received packet
        # packet[:20]
        #or packet[28:48] if this is the referenced ip header


        ip = iphdr()
        pkt = struct.unpack('!BBHHHBBH', data[:12])
        ip.version = (pkt[0] >> 4 & 0x0f)
        ip.hlen = (pkt[0] & 0x0f)
        ip.tos, ip.length, ip.id, ip.frag, ip.ttl, ip.proto, ip.cksum = pkt[1:]
        ip.saddr = data[12:16]
        ip.daddr = data[16:20]
        ip.src = socket.inet_ntoa(ip.saddr)
        ip.dst = socket.inet_ntoa(ip.daddr)
        return ip

class tcphdr(object):
    def __init__(self, data="", dport=4242, sport=4242):
        self.seq = 0
        self.hlen = 44
        self.flags = 2
        self.wsize = 200
        self.cksum = 123
        self.options = 0
        self.mss = 1460
        self.dport = dport
        self.sport = sport
        self.data = data

    @classmethod
    def disassemble(self, data):

        tcp = tcphdr()
        #pkt = struct.unpack("!HHLLBBHHH", data)
        pkt = struct.unpack("!HHL", data)

        tcp.sport, tcp.dport, tcp.seq = pkt[0],pkt[1], pkt[2]
        #tcp.ack = pkt[3]

        return tcp


class udphdr(object):
    def __init__(self, data="", dport=4242, sport=4242):
        self.dport = dport
        self.sport = sport
        self.cksum = 0
        self.length = 0
        self.data = data

    @classmethod
    def disassemble(self, data):
        udp = udphdr()
        pkt = struct.unpack("!HHHH", data)
        udp.sport, udp.dport, udp.length, udp.cksum = pkt
        return udp

class icmphdr(object):
    def __init__(self, data=""):
        self.type = 8
        self.code = 0
        self.cksum = 0
        self.id = random.randint(2 ** 10, 2 ** 16)
        self.sequence = 0
        self.data = data

    @classmethod
    def disassemble(self, data):

        # this has to be used from 20:28 if its the first icmp header

        icmp = icmphdr()
        pkt = struct.unpack("!BBHHH", data)
        icmp.type, icmp.code, icmp.cksum, icmp.id, icmp.sequence = pkt
        return icmp


# checksum functions needed for calculation checksum
def checksum(msg):
    s = 0
    # loop taking 2 characters at a time
    for i in range(0, len(msg), 2):
        w = (ord(msg[i]) << 8) + ( ord(msg[i+1]) )
        s = s + w

    s = (s>>16) + (s & 0xffff)
    #s = s + (s >> 16)    #complement and mask to 4 byte short
    s = ~s & 0xffff

    return s


def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])


def ip_header(src,dst,ttl,proto,id=0):

    # now start constructing the packet
    packet = ''
    # ip header fields
    ihl = 5
    version = 4
    tos = 128
    tot_len = 20 + 20   # python seems to correctly fill the total length, dont know how ??
    frag_off = 0
    if proto == "tcp":
        proto = socket.IPPROTO_TCP
    elif proto == "udp":
        proto = socket.IPPROTO_UDP
    else:
        print "proto unknown"
        return
    check = 10  # python seems to correctly fill the checksum
    saddr = socket.inet_aton ( src )  #Spoof the source ip address if you want to
    daddr = socket.inet_aton ( dst )

    ihl_version = (version << 4) + ihl

    # the ! in the pack format string means network order
    ip_header = struct.pack('!BBHHHBBH4s4s' , ihl_version, tos, tot_len, id, frag_off, ttl, proto, check, saddr, daddr)
    return ip_header

def tcp_header(src,dst,sport,dport):

    # tcp header fields
    source = sport #sourceport
    dest = dport  # destination port
    seq = 0
    ack_seq = 0
    doff = 5    #4 bit field, size of tcp header, 5 * 4 = 20 bytes
    #tcp flags
    fin = 0
    syn = 1
    rst = 0
    psh = 0
    ack = 0
    urg = 0
    window = socket.htons (5840)    #   maximum allowed window size
    check = 0
    urg_ptr = 0

    offset_res = (doff << 4) + 0
    tcp_flags = fin + (syn << 1) + (rst << 2) + (psh <<3) + (ack << 4) + (urg << 5)

    # the ! in the pack format string means network order
    tcp_header = struct.pack('!HHLLBBHHH' , source, dest, seq, ack_seq, offset_res, tcp_flags,  window, check, urg_ptr)

    # pseudo header fields
    source_address = socket.inet_aton( src )
    dest_address = socket.inet_aton(dst)
    placeholder = 0
    proto = socket.IPPROTO_TCP
    tcp_length = len(tcp_header)

    psh = struct.pack('!4s4sBBH' , source_address , dest_address , placeholder , proto , tcp_length)
    psh = psh + tcp_header

    tcp_checksum = checksum(psh)

    # make the tcp header again and fill the correct checksum
    tcp_header = struct.pack('!HHLLBBHHH' , source, dest, seq, ack_seq, offset_res, tcp_flags,  window, tcp_checksum , urg_ptr)

    # final full packet - syn packets dont have any data
    return tcp_header

def udp_header(sport,dport):

    sport = sport    # arbitrary source port
    dport = dport   # arbitrary destination port
    length = 8
    checksum = 0
    header = struct.pack('!HHHH', sport, dport, length, checksum)

    return header

def getInterfaceName():

    #assume it has eth0

    return [x for x in os.listdir('/sys/cla'
                                  'ss/net') if "eth0" in x][0]

def getICMPInfo(data):


    #we make the assumption its always a icmp packet

    icmp_pkt = icmphdr.disassemble(data[20:28])
    # check if type is 3 or 11
    # type 3 = destination unrechable
    # type 11 = time to live exceeded
    if icmp_pkt.type != 11:
        return -1,-1,-1,-1

    #check id and get protocol
    ref_ip_pkt = iphdr.disassemble(data[28:48])


    if ref_ip_pkt.tos != 128:
        return -1, -1, -1,-1

    original_header, id = bool(ref_ip_pkt.id & (1<<15)), ref_ip_pkt.id & 0x7fff

    #TCP
    if ref_ip_pkt.proto == 6:
        #we only unpack the first 8 bytes
        ref_tcp_pkt = tcphdr.disassemble(data[48:56])
        return (ref_ip_pkt.src,ref_ip_pkt.dst,"TCP"),id, (ref_tcp_pkt.sport, ref_tcp_pkt.dport),original_header

    elif ref_ip_pkt.proto == 17:
        ref_udp_pkt = udphdr.disassemble(data[48:56])
        return (ref_ip_pkt.src,ref_ip_pkt.dst,"UDP"),id, (ref_udp_pkt.sport, ref_udp_pkt.dport),original_header

    else:
        return -1,-1,-1,-1

def getPortsICMP(data,id):


    #we make the assumption its always a icmp packet

    icmp_pkt = icmphdr.disassemble(data[20:28])
    # check if type is 3 or 11
    # type 3 = destination unrechable
    # type 11 = time to live exceeded
    if icmp_pkt.type != 11:
        return -1

    #check id and get protocol
    ref_ip_pkt = iphdr.disassemble(data[28:48])

    if ref_ip_pkt.id != id:
        return -1

    #TCP
    if ref_ip_pkt.proto == 6:
        ref_tcp_pkt = tcphdr.disassemble(data[48:56])
        return (ref_tcp_pkt.sport, ref_tcp_pkt.dport)

    elif ref_ip_pkt.proto == 17:
        ref_udp_pkt = udphdr.disassemble(data[48:56])
        return (ref_udp_pkt.sport, ref_udp_pkt.dport)

    else:
        return -1


def check_valid_icmp(src,dst,sport,dport,proto,data):

    #get the ip layer
    ip_pkt = iphdr.disassemble(data[:20])

    #check protocol

    if ip_pkt.proto != socket.IPPROTO_ICMP:
        return False

    icmp_pkt = icmphdr.disassemble(data[20:28])

    # check if type is 3 or 11
    # type 3 = destination unrechable
    # type 11 = time to live exceeded
    if icmp_pkt.type != 11 and icmp_pkt.type != 3:
        return False

    ref_ip_pkt = iphdr.disassemble(data[28:48])


    #now we check src, dst and protocol
    if ref_ip_pkt.src != src or ref_ip_pkt.dst != dst or ref_ip_pkt.proto != proto:
        return False

    #now we check differently if its tcp or udp

    #TCP
    if ref_ip_pkt.proto == 6:

        ref_tcp_pkt = tcphdr.disassemble(data[48:56])

        if ref_tcp_pkt.sport != sport or ref_tcp_pkt.dport != dport:
            return False

    elif ref_ip_pkt.proto == 17:
        #now we proceed to check ports
        ref_udp_pkt = udphdr.disassemble(data[48:56])

        if ref_udp_pkt.sport != sport or ref_udp_pkt.dport != dport:
            return False
    else:
        return False

    return True

def traceroute(src=None,dst=None,sport=5001,dport=5002):

    """
    Traceroute finds the ips along the path from src to dst, however it needs the amount of hops to work, otherwise
    does not know when to stop. This has to be done for a rapid execution so we do not have to wait until last router or
    dst host replies. However, we need to know beforehand the length
    :param src:
    :param dst:
    :param sport:
    :param dport:
    :param proto:
    :param hops:
    :param kwargs:
    :return:
    """

    #dest can be an ip or a domain name
    dst =  socket.gethostbyname(dst)
    icmp = socket.getprotobyname('icmp')
    proto = socket.getprotobyname('tcp')
    src_port = sport
    dst_port = dport
    #TODO: I FIXED THIS BECAUSE I CAN NOT SOLVE IT..
    max_hops = 50
    if src == None:
        interface_name = getInterfaceName()
        src = get_ip_address(interface_name)

    recv_socket = socket.socket(socket.AF_INET, socket.SOCK_RAW, icmp)
    recv_socket.settimeout(0.5)

    #route we return with routers interface IPS, we have to use the topology to get from which router is that ip,
    #since it could be from any of its interfaces
    route = []
    send_socket = socket.socket(socket.AF_INET, socket.SOCK_RAW, proto)
    # tell kernel not to put in headers, since we are providing it
    send_socket.setsockopt(socket.IPPROTO_IP, socket.IP_HDRINCL, 1)

    try:
        curr_addr = None
        tcp_h = tcp_header(src,dst,src_port,dst_port)
        for ttl in range(1,max_hops):
            packet = ip_header(src, dst, ttl,"tcp") + tcp_h
            send_socket.sendto(packet, (dst, 0))

            try:
                # gets data until its a valid icmp packet
                data, curr_addr = recv_socket.recvfrom(512)
                # if timeout already we return
                while not check_valid_icmp(src, dst, sport, dport, proto, data):
                    # if timeout already we return
                    data, curr_addr = recv_socket.recvfrom(512)

            except socket.error:
                #timeout!
                return route

            # if we are here and curr_addr is none it means that a timeout occurred
            if curr_addr:
                curr_addr = curr_addr[0]

                route.append(curr_addr)
                curr_addr = None


        send_socket.close()
        recv_socket.close()
        return route

    finally:
        send_socket.close()
        recv_socket.close()
