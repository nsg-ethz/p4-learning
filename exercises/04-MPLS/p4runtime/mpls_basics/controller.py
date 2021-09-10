from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_p4runtime_API import SimpleSwitchP4RuntimeAPI
from p4utils.utils.sswitch_thrift_API import SimpleSwitchThriftAPI


topo = load_topo('topology.json')
controllers = {}

for switch, data in topo.get_p4rtswitches().items():
    controllers[switch] = SimpleSwitchP4RuntimeAPI(data['device_id'], data['grpc_port'],
                                                   p4rt_path=data['p4rt_path'],
                                                   json_path=data['json_path'])

# Configure s1
controller = controllers['s1']

controller.table_add('check_is_ingress_border', 'set_is_ingress_border', ['1'])

# TODO 2.6: Add the forwarding entries for fec_to_label table


controller.table_add('mpls_tbl', 'mpls_forward', ['2'], ['00:00:00:02:01:00','2'])
controller.table_add('mpls_tbl', 'mpls_forward', ['3'], ['00:00:00:03:01:00','3'])

# TODO 5.1: Add the forwarding entries for check_is_egress_border table, for port 1
#           Add the forwarding entries for mpls_tbl table


# Configure s2
controller = controllers['s2']

# TODO 3.3: Add the forwarding entries for mpls_tbl table


# TODO 5.1: Add the forwarding entries for mpls_tbl table


# Configure s3
controller = controllers['s3']

# TODO 3.3: Add the forwarding entries for mpls_tbl table


# Configure s4
controller = controllers['s4']

# TODO 3.3: Add the forwarding entries for mpls_tbl table


# TODO 5.1: Add the forwarding entries for mpls_tbl table


# Configure s5
controller = controllers['s5']

# TODO 3.3: Add the forwarding entries for mpls_tbl table


# Configure s6
controller = controllers['s6']

# TODO 3.3: Add the forwarding entries for mpls_tbl table


# TODO 5.1: Add the forwarding entries for mpls_tbl table


# Configure s7
controller = controllers['s7']

# TODO 3.3: Add the forwarding entries for mpls_tbl table


# TODO 4.3: Add the forwarding entries for check_is_egress_border table, for ports 3 and 4


# TODO 5.1: Add the forwarding entries for check_is_ingress_border table, for ports 3 and 4
#           Add the forwarding entries for fec_to_label table
#           Add the forwarding entries for mpls_tbl

