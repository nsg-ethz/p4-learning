from scapy.all import Ether, IP, sendp, get_if_hwaddr, get_if_list, TCP, Raw
import sys, socket, random

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

def send_random_traffic(dst_ip, num_packets):

    dst_addr = socket.gethostbyname(dst_ip)
    total_pkts = 0
    random_port = random.randint(1024,65000)
    iface = get_if()
    #For this exercise the destination mac address is not important. Just ignore the value we use.
    p = Ether(dst="00:01:0a:02:02:00", src=get_if_hwaddr(iface)) / IP(dst=dst_addr)
    p = p / TCP(dport=random_port)
    for i in range(num_packets):
        sendp(p, iface = iface)
        total_pkts += 1
    print("Sent %s packets in total" % total_pkts)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python send.py <dst_ip> <num_packets>")
        sys.exit(1)
    else:
        dst_name = sys.argv[1]
        num_packets = int(sys.argv[2])
        send_random_traffic(dst_name, num_packets)