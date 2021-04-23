from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_p4runtime_API import SimpleSwitchP4RuntimeAPI


topo = load_topo('topology.json')
controllers = {}

for switch, data in topo.get_p4rtswitches().items():
    controllers[switch] = SimpleSwitchP4RuntimeAPI(data['device_id'], data['grpc_port'],
                                                   p4rt_path=data['p4rt_path'],
                                                   json_path=data['json_path'])

controller = controllers['s1']                        

controller.table_add('dmac', 'forward', ['00:00:0a:00:00:01'], ['1'])
controller.table_add('dmac', 'forward', ['00:00:0a:00:00:02'], ['2'])
controller.table_add('dmac', 'forward', ['00:00:0a:00:00:03'], ['3'])
controller.table_add('dmac', 'forward', ['00:00:0a:00:00:04'], ['4'])