from p4utils.utils.topology import Topology

topo = Topology(db="topology.db")

for host in sorted(topo.get_hosts().keys(), key = lambda x: int(x[1:])):

    host_intf = topo.get_host_first_interface(host)
    sw = topo.interface_to_node(host, host_intf)
    print host, topo[sw][host]['intf']