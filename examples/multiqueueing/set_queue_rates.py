import nnpy
import struct
from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_thrift_API import SimpleSwitchThriftAPI



class Controller(object):

    def __init__(self, sw_name):
        self.topo = load_topo('topology.json')
        self.sw_name = sw_name
        self.thrift_port = self.topo.get_thrift_port(sw_name)
        self.controller = SimpleSwitchThriftAPI(self.thrift_port)

    #self.fill_table_test()
    def _set_queue_rate(self, rate, port, priority):
        self.controller.set_queue_rate(rate, port, priority)

if __name__ == "__main__":
    import sys
    switch_name = sys.argv[1]
    port = int(sys.argv[2])
    priority = int(sys.argv[3])
    rate = int(sys.argv[4])
    controller = Controller(switch_name)
    controller._set_queue_rate(rate, port, priority)