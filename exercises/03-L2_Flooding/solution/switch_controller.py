from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_thrift_API import SimpleSwitchThriftAPI

class FloodingController(object):

    def __init__(self, sw_name):
        self.topo = load_topo('topology.json')
        self.sw_name = sw_name
        self.thrift_port = self.topo.get_thrift_port(sw_name)
        self.cpu_port =  self.topo.get_cpu_port_index(self.sw_name)
        self.controller = SimpleSwitchThriftAPI(self.thrift_port)
        self.init()

    def init(self):
        self.controller.reset_state()
        self.fill_dmac_table()
        self.add_boadcast_groups()

    def fill_dmac_table(self):
        self.controller.table_add("dmac", "forward", ['00:00:0a:00:00:01'], ['1'])
        self.controller.table_add("dmac", "forward", ['00:00:0a:00:00:02'], ['2'])
        self.controller.table_add("dmac", "forward", ['00:00:0a:00:00:03'], ['3'])
        self.controller.table_add("dmac", "forward", ['00:00:0a:00:00:04'], ['4'])
        self.controller.table_set_default("dmac", "broadcast", [])

    def add_boadcast_groups(self):
        interfaces_to_port = self.topo.get_node_intfs[self.sw_name]["interfaces_to_port"].copy()
        #filter lo and cpu port
        interfaces_to_port.pop('lo', None)
        interfaces_to_port.pop(self.topo.get_cpu_port_intf(self.sw_name), None)

        mc_grp_id = 1
        rid = 0
        for ingress_port in interfaces_to_port.values():

            port_list = list(interfaces_to_port.values())
            del(port_list[port_list.index(ingress_port)])

            #add multicast group
            self.controller.mc_mgrp_create(mc_grp_id)

            #add multicast node group
            handle = self.controller.mc_node_create(rid, port_list)

            #associate with mc grp
            self.controller.mc_node_associate(mc_grp_id, handle)

            #fill broadcast table
            self.controller.table_add("select_mcast_grp", "set_mcast_grp", [str(ingress_port)], [str(mc_grp_id)])

            mc_grp_id +=1
            rid +=1

if __name__ == "__main__":
    import sys
    sw_name = sys.argv[1]
    controller = FloodingController(sw_name)