from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_thrift_API import *
from crc import Crc
import socket, struct, pickle, os, time

from scapy.all import Ether, sniff, Packet, BitField, raw

class LossHeader(Packet):
    name = 'LossHeader'
    fields_desc = [BitField('batch_id',0,8), BitField('next_protocol', 0, 8)]

crc32_polinomials = [0x04C11DB7, 0xEDB88320, 0xDB710641, 0x82608EDB, 0x741B8CD7, 0xEB31D82E,
                     0xD663B05, 0xBA0DC66B, 0x32583499, 0x992C1A4C, 0x32583499, 0x992C1A4C]

NUM_PORTS = 2
NUM_BATCHES = 2

REGISTER_SIZE_TOTAL = 2048
REGISTER_BATCH_SIZE  = int(REGISTER_SIZE_TOTAL/NUM_BATCHES) # It must be an integer
REGISTER_PORT_SIZE = int(REGISTER_BATCH_SIZE/NUM_PORTS)     # It must be an integer

class PacketLossController(object):

    def __init__(self, num_hashes=3):

        self.topo = load_topo('topology.json')
        self.controllers = {}
        self.num_hashes = num_hashes

        # gets a controller API for each switch: {"s1": controller, "s2": controller...}
        self.connect_to_switches()
        # creates the 3 hashes that will use the p4 switch
        self.create_local_hashes()

        # initializes the switch
        # resets all registers, configures the 3 x 2 hash functions
        # reads the registers
        # populates the tables and mirroring id
        self.init()
        self.registers = {}

    def init(self):
        self.reset_all_registers()
        self.set_crc_custom_hashes_all()
        self.read_registers()
        self.configure_switches()

    def connect_to_switches(self):
        for p4switch in self.topo.get_p4switches():
            thrift_port = self.topo.get_thrift_port(p4switch)
            self.controllers[p4switch] = SimpleSwitchThriftAPI(thrift_port)

    def configure_switches(self):

        for sw, controller in self.controllers.items():
            # ads cpu port
            controller.mirroring_add(100, 3)

            # set the basic forwarding rules
            controller.table_add("forwarding", "set_egress_port", ["1"], ["2"])
            controller.table_add("forwarding", "set_egress_port", ["2"], ["1"])

            # set the remove header rules when there is a host in a port
            direct_hosts = self.topo.get_hosts_connected_to(sw)
            for host in direct_hosts:
                port = self.topo.node_to_node_port_num(sw,host)
                controller.table_add("remove_loss_header", "remove_header", [str(port)], [])

    def set_crc_custom_hashes_all(self):
        for sw_name in self.controllers:
            self.set_crc_custom_hashes(sw_name)

    def set_crc_custom_hashes(self, sw_name):
        custom_calcs = sorted(self.controllers[sw_name].get_custom_crc_calcs().items())
        i = 0
        # Set the first 3 hashes for the um
        for custom_crc32, width in custom_calcs[:self.num_hashes]:
            self.controllers[sw_name].set_crc32_parameters(custom_crc32, crc32_polinomials[i], 0xffffffff, 0xffffffff, True,
                                                           True)
            i += 1

        i = 0
        # Sets the 3 hashes for the dm, they have to be the same, thus we use the same index
        for custom_crc32, width in custom_calcs[self.num_hashes:]:
            self.controllers[sw_name].set_crc32_parameters(custom_crc32, crc32_polinomials[i], 0xffffffff, 0xffffffff,
                                                           True, True)
            i += 1

    def create_local_hashes(self):
        self.hashes = []
        for i in range(self.num_hashes):
            self.hashes.append(Crc(32, crc32_polinomials[i], True, 0xffffffff, True, 0xffffffff))

    def reset_all_registers(self):
        for sw, controller in self.controllers.items():
            for register in controller.get_register_arrays():
                controller.register_reset(register)

    def reset_registers(self, sw, stream, port, batch_id):
        start = (batch_id * REGISTER_BATCH_SIZE) + ((port-1) * REGISTER_PORT_SIZE)
        end = start + REGISTER_PORT_SIZE

        for register in self.controllers[sw].get_register_arrays():
            if stream in register:
                self.controllers[sw].register_write(register, [start, end], 0)

    def flow_to_bytestream(self, flow):
        # flow fields are: srcip , dstip, srcport, dstport, protocol, ip id
        return socket.inet_aton(flow[0]) + socket.inet_aton(flow[1]) + struct.pack(">HHBH",flow[2], flow[3], flow[4], flow[5])

    def read_registers(self):
        # reads all the registers
        self.registers = {sw: {} for sw in self.controllers.keys()}
        for sw, controller in self.controllers.items():
            for register in controller.get_register_arrays():
                self.registers[sw][register] = (controller.register_read(register))

    def extract_register_information(self, sw, stream, port, batch_id):
        # reads the region of a um or dm register: uses port, batch id.
        start = (batch_id * REGISTER_BATCH_SIZE) + ((port-1) * REGISTER_PORT_SIZE)
        end = start + REGISTER_PORT_SIZE
        res = {}
        for name, values in self.registers[sw].items():
            if stream in name:
                res[name] = values[start:end]

        return res

    def decode_meter_pair(self, um_registers, dm_registers):
        # TODO 3
        pass

    def verify_link(self, sw1, sw2, batch_id):
        # TODO 2
        pass

    def check_sw_links(self, sw, batch_id):
        # TODO 1
        pass

    # When a batch_id changes the controller gets triggered
    def recv_msg_cpu(self, pkt):
        interface = pkt.sniffed_on
        print(interface)
        switch_name = interface.split("-")[0]
        packet = Ether(raw(pkt))
        if packet.type == 0x1234:
            loss_header = LossHeader(packet.load)
            batch_id = loss_header.batch_id >> 7
            print(switch_name, batch_id)
            self.check_sw_links(switch_name, batch_id)

    def run_cpu_port_loop(self):
        cpu_interfaces = [str(self.topo.get_cpu_port_intf(sw_name).replace("eth0", "eth1")) for sw_name in self.controllers]
        sniff(iface=cpu_interfaces, prn=self.recv_msg_cpu)

if __name__ == "__main__":

    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--option', help="", type=str, required=False, default="run")
    args = parser.parse_args()

    controller = PacketLossController()
    if args.option == "run":
        controller.run_cpu_port_loop()



