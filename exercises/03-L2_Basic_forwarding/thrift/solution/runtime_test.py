#!/usr/bint/env python3
import p4runtime_cli.shell as sh
import tempfile

# you can omit the config argument if the switch is already configured with the
# correct P4 dataplane.

temp = tempfile.NamedTemporaryFile(suffix='.bin')
sh.setup(
    device_id=1,
    grpc_addr='0.0.0.0:9559',
    election_id=(0, 1), # (high, low)
    config=sh.FwdPipeConfig('p4src/l2_basic_forwarding_p4rt.txt', 'p4src/l2_basic_forwarding.json')
)
temp.close()

te = sh.TableEntry('dmac')(action='forward')
te.match['hdr.ethernet.dstAddr'] = '00:00:0a:00:00:01'
te.action['egress_port'] = '1'
te.insert()

te = sh.TableEntry('dmac')(action='forward')
te.match['hdr.ethernet.dstAddr'] = '00:00:0a:00:00:02'
te.action['egress_port'] = '2'
te.insert()

te = sh.TableEntry('dmac')(action='forward')
te.match['hdr.ethernet.dstAddr'] = '00:00:0a:00:00:03'
te.action['egress_port'] = '3'
te.insert()

te = sh.TableEntry('dmac')(action='forward')
te.match['hdr.ethernet.dstAddr'] = '00:00:0a:00:00:04'
te.action['egress_port'] = '4'
te.insert()

print(list(sh.TableEntry('dmac').read()))

sh.teardown()
