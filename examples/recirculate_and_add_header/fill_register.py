#!/usr/bin/env python

from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI


class FillRegisters(object):

    def __init__(self, sw_name):

        self.topo = Topology(db="topology.db")
        self.sw_name = sw_name
        self.thrift_port = self.topo.get_thrift_port(sw_name)
        self.controller = SimpleSwitchAPI(self.thrift_port)


    def fill_registers(self):

        for i in range(128):
            self.controller.register_write("recirculate_register", i, i)

if __name__ == "__main__":
    FillRegisters("s1").fill_registers()

