from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')

# Network definition
net.addP4Switch('s1')
net.addP4Switch('s2')
net.addP4Switch('s3')
net.addP4Switch('s4')
net.setP4SourceAll('p4src/fast_reroute.p4')

net.addHost('h1')
net.addHost('h2')
net.addHost('h3')
net.addHost('h4')

net.addLink("h1", "s1")
net.addLink("h2", "s2")
net.addLink("h3", "s3")
net.addLink("h4", "s4")
net.addLink("s1", "s2", weight=1)
net.addLink("s2", "s3", weight=1)
net.addLink("s3", "s4", weight=5)
net.addLink("s4", "s1", weight=1)
net.addLink("s1", "s3", weight=10)
net.addLink("s2", "s4", weight=10)

# Assignment strategy
net.l3()

# Nodes general options
net.disablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()