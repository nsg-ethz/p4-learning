from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI
from p4utils.utils.utils import ip_address_to_mac
import ipaddress
import subprocess
import time

class IterIPv4Network(ipaddress.IPv4Network):

    def __init__(self, addr,*args, **kwargs):
        super(IterIPv4Network, self).__init__(addr, *args, **kwargs)

    def __add__(self, offset):
        """Add numeric offset to the IP."""
        new_base_addr = int(self.network_address) + (offset * self.size())
        return self.__class__((new_base_addr, str(self.netmask)))

    def size(self):
        """Return network size."""
        start = int(self.network_address)
        return int(self.broadcast_address) + 1 - start

def generate_prefix_pool(prefix_base):
    import itertools as it
    base = IterIPv4Network(unicode(prefix_base))
    for i in it.count():
        try:
            yield (base + (i+1)).compressed
        except ipaddress.AddressValueError:
            return


class RoutingController(object):

    def __init__(self, subnets=0):

        self.topo = Topology(db="topology.db")
        self.controllers = {}

        destination_subnets = self.generate_ips("10.0.1.0/24", "10.250.250.0/24")
        h2 = destination_subnets[0]
        h3  = destination_subnets[-1]
        #remove them
        destination_subnets = destination_subnets[1:-1]
        #filter entries
        destination_subnets = destination_subnets[:subnets]
        # put them back
        destination_subnets = [h2] + destination_subnets + [h3]
        self.destination_subnets= destination_subnets

    def init(self):
        print "Start Controller"
        self.connect_to_switches()
        self.reset_states()
        self.set_table_defaults()

    def reset_states(self):
        [controller.reset_state() for controller in self.controllers.values()]

    def connect_to_switches(self):
        for p4switch in self.topo.get_p4switches():
            thrift_port = self.topo.get_thrift_port(p4switch)
            self.controllers[p4switch] = SimpleSwitchAPI(thrift_port)

    def set_table_defaults(self):
        for controller in self.controllers.values():
            controller.table_set_default("ipv4_lpm", "drop", [])

    def generate_ips(self, start, finish):

        dest_subets = []
        prefix_pool = generate_prefix_pool(start)

        ip = next(prefix_pool)
        dest_subets.append(ip)
        while ip != finish:
            ip = next(prefix_pool)
            dest_subets.append(ip)

        return dest_subets

    def initialize_tables(self, entries=0):

        #set static rules
        self.controllers["s1"].table_add("ipv4_lpm", "set_nhop_index", ["10.0.1.2/32"], ["1"])
        self.controllers["s1"].table_add("forward", "_forward", ["1"], ["00:00:0a:00:01:02", "1"])

        self.controllers["s2"].table_add("ipv4_lpm", "set_nhop_index", ["10.0.1.0/24"], ["1"])
        self.controllers["s2"].table_add("forward", "_forward", ["1"], ["00:00:0a:00:01:02", "1"])
        self.controllers["s2"].table_add("ipv4_lpm", "set_nhop_index", ["10.0.0.0/8"], ["2"])
        self.controllers["s2"].table_add("forward", "_forward", ["2"], ["00:00:0a:00:01:02", "2"])

        self.controllers["s3"].table_add("ipv4_lpm", "set_nhop_index", ["10.0.1.0/24"], ["1"])
        self.controllers["s3"].table_add("forward", "_forward", ["1"], ["00:00:0a:00:01:02", "1"])
        self.controllers["s3"].table_add("ipv4_lpm", "set_nhop_index", ["10.0.0.0/8"], ["2"])
        self.controllers["s3"].table_add("forward", "_forward", ["2"], ["00:00:0a:00:01:02", "2"])

        self.controllers["s4"].table_add("ipv4_lpm", "set_nhop_index", ["10.0.1.0/24"], ["2"])
        self.controllers["s4"].table_add("forward", "_forward", ["2"], ["00:00:0a:00:01:02", "2"])
        self.controllers["s4"].table_add("ipv4_lpm", "set_nhop_index", ["10.0.2.2/32"], ["3"])
        self.controllers["s4"].table_add("forward", "_forward", ["3"], ["00:00:0a:00:02:02", "3"])
        self.controllers["s4"].table_add("ipv4_lpm", "set_nhop_index", ["10.250.250.2/32"], ["4"])
        self.controllers["s4"].table_add("forward", "_forward", ["4"], ["00:00:0a:fa:fa:02", "4"])

        #dynamic entries for s1
        self.controllers["s1"].table_add("forward", "_forward", ["2"], ["00:00:00:02:01:00", "2"])

        for entry in self.destination_subnets:
            self.controllers["s1"].table_add("ipv4_lpm", "set_nhop_index", [entry], ["2"])

    def fail_link(self):
        subprocess.call("sudo ifconfig s1-eth2 down", shell=True)

    def recover_from_failure(self, out):
        self.controllers["s1"].table_modify_match("forward", "_forward", ["2"], ["00:00:00:03:01:00", str(out)])


    def fail_and_reroute(self):
        self.fail_link()
        time.sleep(2)
        self.recover_from_failure(3)

    def recover_link_reroute(self):
        subprocess.call("sudo ifconfig s1-eth2 up", shell=True)
        time.sleep(1)
        self.recover_from_failure(2)

    def main(self):
        pass


if __name__ == "__main__":
    import sys

    subnets = int(sys.argv[2])
    action = sys.argv[1]

    if action == "populate":
        controller = RoutingController(subnets)
        controller.init()
        controller.initialize_tables()

    elif action == "reroute":
        controller = RoutingController(subnets)
        controller.connect_to_switches()
        controller.recover_from_failure(3)

