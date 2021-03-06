#!/usr/bin/env python3
import socket
import random
import os
import struct
import fcntl
import time
import pickle
import codecs

# checksum functions needed for calculation checksum
def checksum(msg):
    s = 0
    # loop taking 2 characters at a time
    for i in range(0, len(msg), 2):
        w = (msg[i] << 8) + msg[i+1]
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


def eth_header(src, dst, proto=0x0800):
    src_bytes = b"".join([codecs.decode(x,'hex') for x in src.split(":")])
    dst_bytes = b"".join([codecs.decode(x,'hex') for x in dst.split(":")])
    return src_bytes + dst_bytes + struct.pack("!H", proto)

def ip_header(src,dst,ttl,proto,id=0, tos=0):

    # now start constructing the packet
    packet = ''
    # ip header fields
    ihl = 5
    version = 4
    tos = tos
    tot_len = 20 + 20   # python seems to correctly fill the total length, dont know how ??
    frag_off = 0
    if proto == 6:
        proto = socket.IPPROTO_TCP
    elif proto == 17:
        proto = socket.IPPROTO_UDP
    else:
        print("proto unknown")
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

def create_packet(eth_h, src_ip, dst_ip, sport, dport, proto, id, ttl):
    if proto == 6:
        transport_header = tcp_header(src_ip, dst_ip, sport, dport)
    elif proto == 17:
        transport_header = udp_header(sport, dport)
    return eth_h + ip_header(src_ip, dst_ip, ttl, proto,id) + transport_header

def get_random_flow():
    src_ip = socket.inet_ntoa(struct.pack("!I", random.randint(167772160, 4261412864)))
    dst_ip = socket.inet_ntoa(struct.pack("!I", random.randint(167772160, 4261412864)))
    sport = random.randint(1, 2 ** 16 - 2)
    dport = random.randint(1, 2 ** 16 - 2)
    ip_id = random.randint(1, 2 ** 16 - 2)
    protocol = random.choice([6])
    return (src_ip, dst_ip, sport, dport, protocol, ip_id)

def save_flows(flows):
    with open("sent_flows.pickle", "wb") as f:
        pickle.dump(flows, f)

def create_test(n_packets, n_drops, fail_hops):

    packets_to_send = []

    assert n_packets >= n_drops

    for i in range(int(n_packets-n_drops)):
        packets_to_send.append(get_random_flow() + (64,))

    for i in range(int(n_drops)):
        packets_to_send.append(get_random_flow() + (fail_hops,))

    return packets_to_send

def main(n_packets, n_drops, fail_hops):

    send_socket = socket.socket(socket.AF_PACKET, socket.SOCK_RAW)
    intf_name = getInterfaceName()
    send_socket.bind((intf_name, 0))

    eth_h = eth_header("01:02:20:aa:33:aa", "02:02:20:aa:33:aa", 0x800)

    flows = create_test(n_packets, n_drops, fail_hops)
    for flow in flows:
        if flow[-1] < 10:
            print(flow)
        packet = create_packet(eth_h, *flow)
        send_socket.send(packet)
        time.sleep(0.01)

    send_socket.close()


if __name__ == "__main__":

    import argparse
    parser = argparse.ArgumentParser()

    parser.add_argument('--n-pkt', help='number of packets', type=int, required=False, default=200)
    parser.add_argument('--n-drops', help='number of packts to drop',type=float, required=False, default=20)
    parser.add_argument('--fail-hops', help='Number of hops until packet is dropped, can be random', type=int, required=False, default=1)
    args= parser.parse_args()

    main(args.n_pkt, args.n_drops, int(args.fail_hops))


