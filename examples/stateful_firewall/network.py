from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.enableCli()

# Network definition
net.addP4Switch('s1', cli_input='s1-commands.txt')
net.setP4Source('s1', 'stateful_firewall.p4')
net.addP4Switch('s2', cli_input='s2-commands.txt')
net.setP4Source('s2', 'ip_forwarding.p4')
net.addHost('h1')
net.addHost('h2')

net.addLink('h1', 's1')
net.addLink('h2', 's2')
net.addLink('s1', 's2')

# Assignment strategy
net.mixed()

# Nodes general options
net.enablePcapDumpAll()
net.enableLogAll()

# Start network
net.startNetwork()