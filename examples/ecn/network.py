from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.enableCli()

# Network definition
net.addP4Switch('s1', cli_input='s1-commands.txt')
net.setP4SourceAll('ecn.p4')

net.addHost('h1')
net.addHost('h2')
net.addHost('h3')

net.addLink('h1','s1')
net.addLink('h2','s1')
net.addLink('h3','s1', bw=0.5)

# Assignment strategy
net.l3()

# Nodes general options
net.enablePcapDumpAll()
net.enableLogAll()

# Start the network
net.startNetwork()