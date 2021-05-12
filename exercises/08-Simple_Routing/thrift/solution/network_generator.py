import argparse
import networkx

def init_python(f):
    
    f.write('from p4utils.mininetlib.network_API import NetworkAPI\n')
    f.write('\n')
    f.write('# Network general options\n')
    f.write('net = NetworkAPI()\n')
    f.write('net.setLogLevel("info")\n')

def end_python(f):

    f.write('\n')
    f.write('# Assignment strategy\n')
    f.write('net.l3()\n')
    f.write('\n')
    f.write('# Nodes general options\n')
    f.write('net.enablePcapDumpAll()\n')
    f.write('net.enableLogAll()\n')
    f.write('net.enableCli()\n')
    f.write('net.startNetwork()\n')

def create_linear_topo(f, num_switches):
    
    f.write('\n')
    f.write('# Network definition\n')

    # Add switches
    for i in range(1, num_switches+1):
        f.write('net.addP4Switch("s{}")\n'.format(i))
    
    f.write('net.setP4SourceAll("p4src/ecmp.p4")\n')
    f.write('\n')

    # Add hosts
    for i in range(1, num_switches+1):
        f.write('net.addHost("h{}")\n'.format(i))

    f.write('\n')

    # Connect hosts with switches
    for i in range(1, num_switches+1):
        f.write('net.addLink("h{}", "s{}")\n'.format(i, i))

    # Connect switches
    for i in range(1, num_switches):
        f.write('net.addLink("s{}", "s{}")\n'.format(i, i+1))

def create_circular_topo(f, num_switches):

    create_linear_topo(num_switches)
    # Add link between s1 and sN
    f.write('net.addLink("s{}", "s{}")\n'.format(1, num_switches))

def create_random_topo(f, degree=4, num_switches=10):

    f.write('\n')
    f.write('# Network definition\n')

    g = networkx.random_regular_graph(degree, num_switches)
    trials = 0
    while not networkx.is_connected(g):
        g = networkx.random_regular_graph(degree, num_switches)
        trials +=1
        if trials >= 10:
            print("Could not Create a connected graph")
            return

    # Add switches
    for i in range(1, num_switches+1):
        f.write('net.addP4Switch("s{}")\n'.format(i))
    
    f.write('net.setP4SourceAll("p4src/ecmp.p4")\n')
    f.write('\n')

    # Add hosts
    for i in range(1, num_switches+1):
        f.write('net.addHost("h{}")\n'.format(i))

    f.write('\n')

    # Connect hosts with switches
    for i in range(1, num_switches + 1):
        f.write('net.addLink("h{}","s{}")\n'.format(i, i))

    # Connect switches
    for edge in g.edges:
        f.write('net.addLink("s{}","s{}")\n'.format(edge[0]+1, edge[1]+1))


def main():
    pass

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output_name', type=str, required=False, default="network_test.py")
    parser.add_argument("--topo", type=str, default="linear")
    parser.add_argument('-n', type=str, required=False, default=2)
    parser.add_argument('-d', type=str, required=False, default=4)
    args = parser.parse_args()

    with open(args.output_name, 'w') as f:
        init_python(f)
        if args.topo == "linear":
            create_linear_topo(f, int(args.n))
        elif args.topo == "circular":
            create_circular_topo(f, int(args.n))
        elif args.topo == "random":
            create_random_topo(f, int(args.d), int(args.n))
        end_python(f)
