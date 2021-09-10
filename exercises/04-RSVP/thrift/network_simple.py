from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')

# Network definition
net.addP4Switch('s1')
net.addP4Switch('s2')
net.addP4Switch('s3')
net.setP4SourceAll('rsvp.p4')

net.addHost('h1')
net.addHost('h2')
net.addHost('h3')
net.addHost('h4')
net.addHost('h5')
net.addHost('h6')

net.addLink("h1", "s1")
net.addLink("h2", "s1")
net.addLink("s1", "s2")
net.addLink("s1", "s3")
net.addLink("s2", "s3")
net.addLink("h3", "s2")
net.addLink("h4", "s2")
net.addLink("h5", "s3")
net.addLink("h6", "s3")
net.setBwAll(10)

# Assignment strategy
net.l3()

# Nodes general options
net.disablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()