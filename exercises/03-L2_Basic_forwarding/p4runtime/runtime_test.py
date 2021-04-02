#!/usr/bint/env python3
import p4runtime_cli.api as api
from p4utils.utils.sswitch_p4runtime_API import SimpleSwitchP4RuntimeAPI
import tempfile

import time

controller = SimpleSwitchP4RuntimeAPI(1, 9559,
                                      p4rt_path='p4src/l2_basic_forwarding_p4rt.txt',
                                      json_path='p4src/l2_basic_forwarding.json')

controller.table_add('dmac','forward',['00:00:0a:00:00:01'],[1])
controller.table_add('dmac','forward',['00:00:0a:00:00:02'],[2])
controller.table_add('dmac','forward',['00:00:0a:00:00:03'],[3])
controller.table_add('dmac','forward',['00:00:0a:00:00:04'],[4])

# you can omit the config argument if the switch is already configured with the
# correct P4 dataplane.

# cli, cont = api.setup(
#                         device_id=1,
#                         grpc_addr='0.0.0.0:9559',
#                         #config=api.FwdPipeConfig('p4src/l2_basic_forwarding_p4rt.txt', 'c')
#                         config = api.FwdPipeConfig('p4src/l2_basic_forwarding_p4rt.txt', 'p4src/l2_basic_forwarding.json')
#                      )

# te = api.TableEntry(cli, cont, 'dmac')(action='forward')
# te.match['hdr.ethernet.dstAddr'] = '00:00:0a:00:00:01'
# te.action['egress_port'] = '1'
# te.insert()

# te = api.TableEntry(cli, cont, 'dmac')(action='forward')
# te.match['hdr.ethernet.dstAddr'] = '00:00:0a:00:00:02'
# te.action['egress_port'] = '2'
# te.insert()

# te = api.TableEntry(cli, cont, 'dmac')(action='forward')
# te.match['hdr.ethernet.dstAddr'] = '00:00:0a:00:00:03'
# te.action['egress_port'] = '3'
# te.insert()

# te = api.TableEntry(cli, cont, 'dmac')(action='forward')
# te.match['hdr.ethernet.dstAddr'] = '00:00:0a:00:00:04'
# te.action['egress_port'] = '4'
# te.insert()

# api.TableEntry(cli, cont, 'dmac').read(lambda te: print(te))

#api.teardown(cli)
