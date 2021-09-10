from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')

# Network definition
net.addP4Switch('s1')
net.addP4Switch('s2')
net.addP4Switch('s3')
net.setP4SourceAll('p4src/loss-detection.p4')

net.addHost('h1')
net.addHost('h2')

net.addLink("h1", "s1")
net.addLink("s1", "s2")
net.addLink("s2", "s3")
net.addLink("s3", "h2")

# Assignment strategy
net.l2()

# Nodes general options
net.enableCpuPortAll()
net.disablePcapDumpAll()
net.disableLogAll()
net.enableCli()
net.startNetwork()