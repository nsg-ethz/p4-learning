from p4utils.utils.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')

# Network definition
net.addP4Switch('s1', conf_path='s1-commands.txt')
net.addP4Switch('s2', conf_path='s2-commands.txt')
net.setP4SourceAll('heavy_hitter.p4')

net.addHost('h1')
net.addHost('h2')

net.addLink("h1", "s1", port2=1)
net.addLink("s1", "s2", port1=2, port2=2)
net.addLink("s2", "h2", port1=1)

# Assignment strategy
net.mixed()

# Nodes general options
net.disablePcapDumpAll()
net.disableLogAll()
net.enableCli()
net.startNetwork()