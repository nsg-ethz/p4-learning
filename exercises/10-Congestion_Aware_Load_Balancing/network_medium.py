from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.execScript('python routing-controller.py', reboot=True)

# Network definition
net.addP4Switch('s1')
net.addP4Switch('s2')
net.addP4Switch('s3')
net.addP4Switch('s4')
net.addP4Switch('s5')
net.addP4Switch('s6')
net.setP4SourceAll('p4src/loadbalancer.p4')

net.addHost('h1')
net.addHost('h2')
net.addHost('h3')
net.addHost('h4')
net.addHost('h5')
net.addHost('h6')
net.addHost('h7')
net.addHost('h8')

net.addLink("h1", "s1")
net.addLink("h2", "s1")
net.addLink("h3", "s1")
net.addLink("h4", "s1")
net.addLink("h5", "s6")
net.addLink("h6", "s6")
net.addLink("h7", "s6")
net.addLink("h8", "s6")
net.addLink("s1", "s2")
net.addLink("s1", "s3")
net.addLink("s1", "s4")
net.addLink("s1", "s5")
net.addLink("s2", "s6")
net.addLink("s3", "s6")
net.addLink("s4", "s6")
net.addLink("s5", "s6")
net.setBwAll(10)

# Assignment strategy
net.l3()

# Nodes general options
net.enablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()