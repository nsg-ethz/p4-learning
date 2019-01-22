import nnpy
import struct
import ipaddress
from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI

class DigestController():

    def __init__(self, sw_name):

        self.sw_name = sw_name
        self.topo = Topology(db="topology.db")
        self.sw_name = sw_name
        self.thrift_port = self.topo.get_thrift_port(sw_name)
        self.controller = SimpleSwitchAPI(self.thrift_port)

    def recv_msg_digest(self, msg):

        topic, device_id, ctx_id, list_id, buffer_id, num = struct.unpack("<iQiiQi",
                                                                     msg[:32])
        #print num, len(msg)
        offset = 9
        msg = msg[32:]
        for sub_message in range(num):
            random_num, src, dst = struct.unpack("!BII", msg[0:offset])
            print "random number:", random_num, "src ip:", str(ipaddress.IPv4Address(src)), "dst ip:", str(ipaddress.IPv4Address(dst))
            msg = msg[offset:]

        self.controller.client.bm_learning_ack_buffer(ctx_id, list_id, buffer_id)

    def run_digest_loop(self):

        sub = nnpy.Socket(nnpy.AF_SP, nnpy.SUB)
        notifications_socket = self.controller.client.bm_mgmt_get_info().notifications_socket
        print "connecting to notification sub %s" % notifications_socket
        sub.connect(notifications_socket)
        sub.setsockopt(nnpy.SUB, nnpy.SUB_SUBSCRIBE, '')

        while True:
            msg = sub.recv()
            self.recv_msg_digest(msg)


def main():
    DigestController("s1").run_digest_loop()

if __name__ == "__main__":
    main()