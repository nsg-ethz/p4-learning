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

controller.table_add('FEC_tbl', 'mpls_ingress_4_hop', ['10.7.2.0/24'], ['2','3','2','2'])
controller.table_add('mpls_tbl', 'mpls_forward', ['2','0'], ['00:00:00:02:01:00','2'])
controller.table_add('FEC_tbl', 'mpls_ingress_4_hop', ['10.7.3.0/24'], ['2','3','2','2'])
controller.table_add('FEC_tbl', 'ipv4_forward', ['10.1.1.0/24'], ['00:00:0a:01:01:02','1'])

# Configure s2
controller = controllers['s2']

controller.table_add('mpls_tbl', 'mpls_forward', ['2','0'], ['00:00:00:04:01:00','2'])

# Configure s3
controller = controllers['s3']

controller.table_add('mpls_tbl', 'penultimate', ['1','1'], ['00:00:00:01:03:00','1'])

# Configure s4
controller = controllers['s4']

controller.table_add('mpls_tbl', 'mpls_forward', ['3','0'], ['00:00:00:05:01:00','3'])
controller.table_add('mpls_tbl', 'mpls_forward', ['2','0'], ['00:00:00:03:02:00','2'])

# Configure s5
controller = controllers['s5']

controller.table_add('mpls_tbl', 'penultimate', ['2','1'], ['00:00:00:07:01:00','2'])

# Configure s6
controller = controllers['s6']

controller.table_add('mpls_tbl', 'mpls_forward', ['1','0'], ['00:00:00:04:04:00','1'])

# Configure s7
controller = controllers['s7']

controller.table_add('FEC_tbl', 'ipv4_forward', ['10.7.2.0/24'], ['00:00:0a:07:02:02','3'])
controller.table_add('FEC_tbl', 'mpls_ingress_4_hop', ['10.1.1.0/24'], ['1','2','1','2'])
controller.table_add('FEC_tbl', 'ipv4_forward', ['10.7.3.0/24'], ['00:00:0a:07:03:02','4'])
controller.table_add('mpls_tbl', 'mpls_forward', ['2','0'], ['00:00:00:06:02:00','2'])