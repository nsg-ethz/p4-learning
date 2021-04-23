from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_p4runtime_API import SimpleSwitchP4RuntimeAPI


topo = load_topo('topology.json')
controllers = {}
sw_name = 's1'

for switch, data in topo.get_p4rtswitches().items():
    controllers[switch] = SimpleSwitchP4RuntimeAPI(data['device_id'], data['grpc_port'],
                                                   p4rt_path=data['p4rt_path'],
                                                   json_path=data['json_path'])

controller = controllers[sw_name]

# TODO: populate table dmac


# Get port list
interfaces_to_port = topo.get_node_intfs(fields=['port'])[sw_name].copy()
# Filter lo and cpu port
interfaces_to_port.pop('lo', None)
interfaces_to_port.pop(topo.get_cpu_port_intf(sw_name), None)
port_list = list(interfaces_to_port.values())

# Iterate over switch ports
mc_grp_id = 1
for ingress_port in interfaces_to_port.values():
    # TODO: add broadcast groups with custom ports
    # TODO: populate select_mcast_grp table


    mc_grp_id +=1

