from p4utils.utils.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')

# Network definition
net.addP4Switch('s1')
net.setP4Source('s1','repeater_with_table.p4')
net.setP4CliInput('s1', 's1-commands.txt')
net.addHost('h1')
net.addHost('h2')
net.addLink('s1', 'h1')
net.addLink('s1', 'h2')

# Assignment strategy
net.l2()

# Nodes general options
net.enablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()