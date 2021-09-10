import sys
import time
import ipaddress
import subprocess
from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_thrift_API import SimpleSwitchThriftAPI


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
    base = IterIPv4Network(str(prefix_base))
    for i in it.count():
        try:
            yield (base + (i+1)).compressed
        except ipaddress.AddressValueError:
            return


class RoutingController(object):

    def __init__(self, subnets=0):

        self.topo = load_topo('topology.json')
        self.controllers = {}

        print('Generating destination subnets...')
        destination_subnets = self.generate_ips('10.0.1.0/24', '10.250.250.0/24')
        h2 = destination_subnets[0]
        h3  = destination_subnets[-1]
        # Remove them
        destination_subnets = destination_subnets[1:-1]
        # Filter entries
        destination_subnets = destination_subnets[:subnets]
        # Put them back
        destination_subnets = [h2] + destination_subnets + [h3]
        self.destination_subnets = destination_subnets

    def init(self):
        print('Controller started.')
        self.connect_to_switches()
        self.reset_states()
        self.set_table_defaults()

    def reset_states(self):
        [controller.reset_state() for controller in list(self.controllers.values())]

    def connect_to_switches(self):
        for p4switch in self.topo.get_p4switches():
            thrift_port = self.topo.get_thrift_port(p4switch)
            self.controllers[p4switch] = SimpleSwitchThriftAPI(thrift_port)

    def set_table_defaults(self):
        for controller in list(self.controllers.values()):
            controller.table_set_default('ipv4_lpm', 'drop', [])

    def generate_ips(self, start, finish):

        dest_subets = []
        prefix_pool = generate_prefix_pool(start)

        ip = next(prefix_pool)
        dest_subets.append(ip)
        while ip != finish:
            ip = next(prefix_pool)
            dest_subets.append(ip)

        return dest_subets

    def initialize_tables(self):

        # Set static rules
        self.controllers['s1'].table_add('ipv4_lpm', 'ipv4_forward', ['10.0.1.2/32'], [self.topo.get_host_mac('h1'), '1'])

        self.controllers['s2'].table_add('ipv4_lpm', 'ipv4_forward', ['10.0.1.0/24'], ['00:00:0a:00:01:02', '1'])
        self.controllers['s2'].table_add('ipv4_lpm', 'ipv4_forward', ['10.0.0.0/8'], ['00:00:0a:00:01:02', '2'])

        self.controllers['s3'].table_add('ipv4_lpm', 'ipv4_forward', ['10.0.1.0/24'], ['00:00:0a:00:01:02', '1'])
        self.controllers['s3'].table_add('ipv4_lpm', 'ipv4_forward', ['10.0.0.0/8'], ['00:00:0a:00:01:02', '2'])

        self.controllers['s4'].table_add('ipv4_lpm', 'ipv4_forward', ['10.0.1.0/24'], ['00:00:0a:00:01:02', '2'])
        self.controllers['s4'].table_add('ipv4_lpm', 'ipv4_forward', ['10.0.2.2/32'], [self.topo.get_host_mac('h2'), '3'])
        self.controllers['s4'].table_add('ipv4_lpm', 'ipv4_forward', ['10.250.250.2/32'], [self.topo.get_host_mac('h3'), '4'])


        # Dynamic entries for s1
        for entry in self.destination_subnets:
            self.controllers['s1'].table_add('ipv4_lpm', 'ipv4_forward', [entry], ['00:00:00:02:01:00', '2'])

    def recover_from_failure(self, out):
        for entry in self.destination_subnets:
            self.controllers['s1'].table_modify_match('ipv4_lpm', 'ipv4_forward', [entry], ['00:00:00:03:01:00', str(out)])


if __name__ == '__main__':
    subnets = int(sys.argv[2])
    action = sys.argv[1]

    if action == 'populate':
        controller = RoutingController(subnets)
        controller.init()
        print('Populating tables with forwarding rules...')
        controller.initialize_tables()

    elif action == 'reroute':
        controller = RoutingController(subnets)
        controller.connect_to_switches()
        print('Updating the forwarding table...')
        startTime = time.time()
        # Reroute packets through port 3 of switch s1
        controller.recover_from_failure(3)
        endTime = time.time()
        print('The update took {} seconds to complete!'.format(endTime - startTime))
