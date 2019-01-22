import random
import time
from p4utils.utils.topology import Topology
from subprocess import Popen

topo = Topology(db="topology.db")

iperf_send = "mx {0} iperf3 -c {1} -M 9000 -t {2} --bind {3} --cport {4} -p {5} 2>&1 >/dev/null"
iperf_recv = "mx {0} iperf3 -s -p {1} --one-off 2>&1 >/dev/null"

Popen("sudo killall iperf iperf3", shell=True)

dst_port1 = random.randint(1024, 65000)
dst_port2 = random.randint(1024, 65000)

Popen(iperf_recv.format("h3", dst_port1), shell=True)
Popen(iperf_recv.format("h4", dst_port2), shell=True)

time.sleep(1)

import sys
duration = int(sys.argv[1])

Popen(iperf_send.format("h1", topo.get_host_ip("h3"), duration, topo.get_host_ip("h1"), dst_port1, dst_port1), shell=True)
Popen(iperf_send.format("h2", topo.get_host_ip("h4"), duration, topo.get_host_ip("h2"), dst_port2, dst_port2), shell=True)

