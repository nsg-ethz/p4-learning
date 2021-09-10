import sys
from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_thrift_API import SimpleSwitchThriftAPI


class ReadCounters(object):

    def __init__(self, sw_name):
        self.topo = load_topo('topology.json')
        self.sw_name = sw_name
        self.thrift_port = self.topo.get_thrift_port(sw_name)
        self.controller = SimpleSwitchThriftAPI(self.thrift_port)

    def direct(self):
        entries = self.controller.table_num_entries('count_table')
        for i in range(0,4):
            self.controller.counter_read('direct_port_counter', i)

    def indirect(self):
        for i in range(1,5):
            self.controller.counter_read('port_counter', i)


if __name__ == '__main__':
    if sys.argv[1] == 'direct':
        ReadCounters('s1').direct()

    elif sys.argv[1] == 'indirect':
        ReadCounters('s1').indirect()