from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.enableCli()
net.execScript('sudo python controller_one_table.py populate 50000')

# Network definition
net.addP4Switch('s1')
net.addP4Switch('s2')
net.addP4Switch('s3')
net.addP4Switch('s4')
net.setP4SourceAll('forwarding_one_table.p4')

net.addHost('h1')
net.setDefaultRoute('h1', '10.0.1.1')
net.addHost('h2')
net.setDefaultRoute('h2', '10.0.2.1')
net.addHost('h3')
net.setDefaultRoute('h3', '10.250.250.1')

net.addLink('h1', 's1')
net.setIntfIp('h1', 's1', '10.0.1.2/24')
net.setIntfIp('s1', 'h1', '10.0.1.1/24')
net.addLink('s1', 's2')
net.addLink('s1', 's3')
net.addLink('s2', 's4')
net.addLink('s3', 's4')
net.addLink('s4', 'h2')
net.setIntfIp('s4', 'h2', '10.0.2.1/24')
net.setIntfIp('h2', 's4', '10.0.2.2/24')
net.addLink('s4', 'h3')
net.setIntfIp('s4', 'h3', '10.250.250.1/24')
net.setIntfIp('h3', 's4', '10.250.250.2/24')

# Nodes general options
net.enablePcapDumpAll()
net.disableLogAll()

# Start network
net.startNetwork()