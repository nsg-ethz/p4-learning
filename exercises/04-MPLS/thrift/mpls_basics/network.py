from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')

# Network definition
net.addP4Switch('s1', cli_input='sx-commands/s1-commands.txt')
net.addP4Switch('s2', cli_input='sx-commands/s2-commands.txt')
net.addP4Switch('s3', cli_input='sx-commands/s3-commands.txt')
net.addP4Switch('s4', cli_input='sx-commands/s4-commands.txt')
net.addP4Switch('s5', cli_input='sx-commands/s5-commands.txt')
net.addP4Switch('s6', cli_input='sx-commands/s6-commands.txt')
net.addP4Switch('s7', cli_input='sx-commands/s7-commands.txt')
net.setP4SourceAll('basics.p4')

net.addHost('h1')
net.addHost('h2')
net.addHost('h3')

net.addLink("h1", "s1", port2=1)
net.addLink("s1", "s2", port1=2, port2=1)
net.addLink("s1", "s3", port1=3, port2=1)
net.addLink("s2", "s4", port1=2, port2=1)
net.addLink("s3", "s4", port1=2, port2=2)
net.addLink("s4", "s5", port1=3, port2=1)
net.addLink("s4", "s6", port1=4, port2=1)
net.addLink("s5", "s7", port1=2, port2=1)
net.addLink("s6", "s7", port1=2, port2=2)
net.addLink("s7", "h2", port1=3)
net.addLink("s7", "h3", port1=4)

# Assignment strategy
net.l3()

# Nodes general options
net.enablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()