from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.execScript('python controller-all-ports.py', reboot=True)
net.disableArpTables()

# Network definition
net.addP4Switch('s1')
net.setP4Source('s1','./p4src/l2_flooding_all_ports.p4')
net.setP4CliInput('s1', './s1-commands-all-ports.txt')
net.addHost('h1')
net.addHost('h2')
net.addHost('h3')
net.addHost('h4')
net.addLink('s1', 'h1')
net.addLink('s1', 'h2')
net.addLink('s1', 'h3')
net.addLink('s1', 'h4')

# Assignment strategy
net.l2()

# Nodes general options
net.enablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()