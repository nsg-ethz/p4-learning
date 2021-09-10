from p4utils.utils.helper import load_topo

topo = load_topo('topology.json')

for host in sorted(topo.get_hosts().keys(), key = lambda x: int(x[1:])):

    host_intf = topo.get_host_first_interface(host)
    sw = topo.interface_to_node(host, host_intf)
    print(host, topo.get_intfs()[sw][host]['intfName'])