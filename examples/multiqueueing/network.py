from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.enableCli()

# Network definition
net.addP4Switch('s1', cli_input='s1-commands.txt')
# can also bee added as a parametter in addP4Switch
net.setPriorityQueueNum('s1', 8)
net.setP4Source('s1','multi_queueing.p4')
net.addHost('h1')
net.addHost('h2')
net.addHost('h3')

net.addLink('s1', 'h1')
net.addLink('s1', 'h2')
net.addLink('s1', 'h3', bw=5)

# Assignment strategy
net.mixed()

# Nodes general options
net.enablePcapDumpAll()
net.enableLogAll()

# Start network
net.startNetwork()