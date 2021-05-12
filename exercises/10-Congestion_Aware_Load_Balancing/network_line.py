from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.execScript('python routing-controller.py', reboot=True)

# Network definition
net.addP4Switch('s1')
net.addP4Switch('s2')
net.addP4Switch('s3')
net.setP4SourceAll('p4src/loadbalancer.p4')

net.addHost('h1')
net.addHost('h2')
net.addHost('h3')
net.addHost('h4')

net.addLink("h1", "s1")
net.addLink("h2", "s1")
net.addLink("h3", "s3")
net.addLink("h4", "s3")
net.addLink("s1", "s2")
net.addLink("s2", "s3")
net.setBwAll(10)

# Assignment strategy
net.l3()

# Nodes general options
net.enablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()