import random
import time
from p4utils.utils.topology import Topology
from subprocess import Popen
import sys

topo = Topology(db="topology.db")

iperf_send = "mx {0} iperf3 -M 9000 -c {1} -t {2} --bind {3} --cport {4} -p {5} 2>&1 >/dev/null"
iperf_recv = "mx {0} iperf3 -s -p {1} --one-off 2>&1 >/dev/null"
duration = int(sys.argv[1])

send_cmds = []
recv_cmds = []

Popen("sudo killall iperf iperf3", shell=True)

num_hosts = 8
num_senders= 4

for src_host in sorted(topo.get_hosts().keys(), key = lambda x: int(x[1:]))[:num_senders]:
    dst_host = 'h' + str((int(src_host[1:]) + 3) % num_hosts + 1)

    src_port = random.randint(1025, 65000)
    dst_port = random.randint(1025, 65000)
    src_ip = topo.get_host_ip(src_host)
    dst_ip = topo.get_host_ip(dst_host)

    send_cmds.append(iperf_send.format(src_host, dst_ip, duration, src_ip, src_port, dst_port))
    recv_cmds.append(iperf_recv.format(dst_host, dst_port))

#start receivers first
for recv_cmd in recv_cmds:
    Popen(recv_cmd, shell=True)

time.sleep(1)

for send_cmd in send_cmds:
    Popen(send_cmd, shell=True)