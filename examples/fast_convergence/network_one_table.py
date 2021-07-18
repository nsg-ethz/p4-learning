from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.enableCli()

# Network definition
net.addP4Switch('s1')
net.addP4Switch('s2')
net.addP4Switch('s3')
net.addP4Switch('s4')
net.setP4SourceAll('forwarding_one_table.p4')

net.addHost('h1')
net.addHost('h2')
net.addHost('h3')

net.addLink('h1','s1')
net.addLink('s1','s2')
net.addLink('s1','s3')
net.addLink('s2','s4')
net.addLink('s3','s4')
net.addLink('s4','h2')
net.addLink('s4','h3')

# Nodes general options
net.enablePcapDumpAll()
net.disableLogAll()

# Start network
net.startNetwork()