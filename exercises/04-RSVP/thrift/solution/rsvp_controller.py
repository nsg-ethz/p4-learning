import os
import threading
import time
from p4utils.utils.helper import load_topo
from p4utils.utils.sswitch_thrift_API import SimpleSwitchThriftAPI
from cli import RSVPCLI


class RSVPController(object):

    def __init__(self):
        """Initializes the topology and data structures
        """

        if not os.path.exists('topology.json'):
            print('Could not find topology object!!!\n')
            raise Exception

        self.topo = load_topo('topology.json')
        self.controllers = {}
        self.init()

        # sorted by timeouts
        self.current_reservations = {}
        # initial link capacity
        self.links_capacity = self.build_links_capacity()

        self.update_lock = threading.Lock()
        self.timeout_thread = threading.Thread(target=self.reservations_timeout_thread, args=(1, ))
        self.timeout_thread.daemon = True
        self.timeout_thread.start()

    def init(self):
        """Connects to switches and resets.
        """
        self.connect_to_switches()
        self.reset_states()

    def reset_states(self):
        """Resets registers, tables, etc.
        """
        [controller.reset_state() for controller in self.controllers.values()]

    def connect_to_switches(self):
        """Connects to all the switches in the topology and saves them
         in self.controllers.
        """
        for p4switch in self.topo.get_p4switches():
            thrift_port = self.topo.get_thrift_port(p4switch)
            self.controllers[p4switch] = SimpleSwitchThriftAPI(thrift_port)        

    def build_links_capacity(self):
        """Builds link capacities dictionary

        Returns:
            dict: {edge: bw}
        """

        links_capacity = {}
        # Iterates all the edges in the topology formed by switches
        for src, dst in self.topo.keep_only_p4switches().edges:
            bw = self.topo.edges[(src, dst)]['bw']
            # add both directions
            links_capacity[(src, dst)] = bw
            links_capacity[(dst, src)] = bw

        return links_capacity
    
    def reservations_timeout_thread(self, refresh_rate = 1):
        """Every refresh_rate checks all the reservations. If any times out
        tries to delete it.

        Args:
            refresh_rate (int, optional): Refresh rate. Defaults to 1.
        """

        while True:
            # sleeps
            time.sleep(refresh_rate)

            # locks the self.current_reservations data structure. This is done
            # because the CLI can also access the reservations.
            with self.update_lock:
                to_remove = []
                
                # iterates all the reservations and updates its timeouts
                # if timeout is reached we delete it
                for reservation, data in self.current_reservations.items():
                    data['timeout'] -= refresh_rate
                    # has expired?
                    if data['timeout'] <= 0:
                        to_remove.append(reservation)

                # removes all the reservations that expired
                for reservation in to_remove:
                    self.del_reservation(*reservation)


    def set_mpls_tbl_labels(self):
        """We set all the table defaults to reach all the hosts/networks in the network
        """

        # for all switches
        for sw_name, controller in self.controllers.items():

            # get all direct hosts and add direct entry
            for host in self.topo.get_hosts_connected_to(sw_name):
                sw_port = self.topo.node_to_node_port_num(sw_name, host)
                host_ip = self.topo.get_host_ip(host)
                host_mac = self.topo.get_host_mac(host)

                # adds direct forwarding rule
                controller.table_add('FEC_tbl', 'ipv4_forward', ['0.0.0.0/0', str(host_ip)], [str(host_mac), str(sw_port)])
                
            for switch in self.topo.get_switches_connected_to(sw_name):
                sw_port = self.topo.node_to_node_port_num(sw_name, switch)
                # reverse port mac
                other_switch_mac = self.topo.node_to_node_mac(switch, sw_name)

                # we add a normal rule and a penultimate one 
                controller.table_add('mpls_tbl', 'mpls_forward', [str(sw_port), '0'], [str(other_switch_mac), str(sw_port)])
                controller.table_add('mpls_tbl', 'penultimate', [str(sw_port), '1'], [str(other_switch_mac), str(sw_port)])


    def build_mpls_path(self, switches_path):
        """Using a path of switches builds the mpls path. In our simplification
        labels are port indexes. 

        Args:
            switches_path (list): path of switches to allocate

        Returns:
            list: label path
        """

        # label path
        label_path = []
        # iterate over all pair of switches in the path
        for current_node, next_node in zip(switches_path, switches_path[1:]):
            # we get sw1->sw2 port number from topo object
            label = self.topo.node_to_node_port_num(current_node, next_node)
            label_path.append(label)
        return label_path
    
    def get_sorted_paths(self, src, dst):
        """Gets all paths between src, dst 
        sorted by length. This function uses the internal networkx API.

        Args:
            src (str): src name
            dst (str): dst name

        Returns:
            list: paths between src and dst
        """

        paths = self.topo.get_all_paths_between_nodes(src, dst)
        # trim src and dst
        paths = [x[1:-1] for x in paths]
        return paths

    def get_shortest_path(self, src, dst):
        """Computes shortest path. Simple function used to test the system 
        by always allocating the shortest path. 

        Args:
            src (str): src name
            dst (str): dst name

        Returns:
            list: shortest path between src,dst
        """
        
        return self.get_sorted_paths(src, dst)[0]

    def check_if_reservation_fits(self, path, bw):
        """Checks if a the candidate reservation fits in the current
        state of the network. Using the path of switches, checks if all
        the edges (links) have enough space. Otherwise, returns False.

        Args:
            path (list): list of switches
            bw (float): requested bandwidth in mbps

        Returns:
            bool: true if allocation can be performed on path
        """

        # iterates over all pairs of switches (edges)
        for link in zip(path, path[1:]):
            # checks if there is enough capacity 
            if (self.links_capacity[link] - bw) < 0:
                return False
        return True        
    
    def add_link_capacity(self, path, bw):
        """Adds bw capacity to a all the edges along path. This 
        function is used when an allocation is removed.

        Args:
            path (list): list of switches
            bw (float): requested bandwidth in mbps
        """

        # iterates over all pairs of switches (edges)
        for link in zip(path, path[1:]):   
            # adds capacity   
            self.links_capacity[link] += bw

    def sub_link_capacity(self, path, bw):
        """subtracts bw capacity to a all the edges along path. This 
        function is used when an allocation is added.

        Args:
            path (list): list of switches
            bw (float): requested bandwidth in mbps
        """
        
        # iterates over all pairs of switches (edges)
        for link in zip(path, path[1:]):
            # subtracts capacity
            self.links_capacity[link] -= bw
    
    def get_available_path(self, src, dst, bw):
        """Checks all paths from src to dst and picks the 
        shortest path that can allocate bw.

        Args:
            src (str): src name
            dst (str): dst name
            bw (float): requested bandwidth in mbps

        Returns:
            list/bool: best path/ False if none
        """
             
        # get all paths sorted from shorter to longer
        paths = self.get_sorted_paths(src, dst)

        for path in paths:
            # checks if the path has capacity
            if self.check_if_reservation_fits(path, bw):
                return path
        return False

    def get_meter_rates_from_bw(self, bw, burst_size=700000):
        """Returns the CIR and PIR rates and bursts to configure 
          meters at bw.

        Args:
            bw (float): desired bandwdith in mbps
            burst_size (int, optional): Max capacity of the meter buckets. Defaults to 50000.

        Returns:
            list: [(rate1, burst1), (rate2, burst2)]
        """

        rates = []
        rates.append( (0.125 * bw, burst_size) )
        rates.append( (0.125 * bw, burst_size) )
        return rates
        

    def set_direct_meter_bandwidth(self, sw_name, meter_name, handle, bw):
        """Sets a meter entry (using a table handle) to color packets using
           bw mbps

        Args:
            sw_name (str): switch name
            meter_name (str): meter name
            handle (int): entry handle
            bw (float): desired bandwidth to rate limit
        """

        rates = self.get_meter_rates_from_bw(bw)
        self.controllers[sw_name].meter_set_rates(meter_name, handle, rates)

    def _add_reservation(self, src, dst, duration, bandwidth, priority, path, update):
        """Adds or updates a single reservation

        Args:
            src (str): src name
            dst (str): dst name
            duration (float): reservation timeout
            bandwidth (float): requested bandwidth in mbps
            priority (int): reservation priority
            path (list): switch path were to allocate the reservation
            update (bool): update flag
        """

        # We build the label path. For that we use self.build_mpls_path and 
        # reverse the returned labels, since our rsvp.p4 will push them in 
        # reverse order.
        label_path = [str(x) for x in self.build_mpls_path(path)[::-1]]

        # Get required info to add a table rule

        # get ingress switch as the first node in the path
        src_gw = path[0]
        # compute the action name using the length of the labels path
        action = 'mpls_ingress_{}_hop'.format(len(label_path))
        # src lpm address
        src_ip = str(self.topo.get_host_ip(src) + '/32')
        # dst exact address
        dst_ip = str(self.topo.get_host_ip(dst))
        # match list
        match = [src_ip, dst_ip]

        # if we have a label path
        if len(label_path) != 0:

            # If the entry is new we simply add it
            if not update:
                entry_handle = self.controllers[src_gw].table_add('FEC_tbl', action, match, label_path)
                self.set_direct_meter_bandwidth(src_gw, 'rsvp_meter', entry_handle, bandwidth)
            # if the entry is being updated we modify if using its handle  
            else:
                entry = self.current_reservations.get((src, dst), None)
                entry_handle = self.controllers[src_gw].table_modify('FEC_tbl', action, entry['handle'], label_path)
                self.set_direct_meter_bandwidth(src_gw, 'rsvp_meter', entry_handle, bandwidth)
            
            # udpates controllers link and reservation structures if rules were added succesfully
            if entry_handle:
                self.sub_link_capacity(path, bandwidth)
                self.current_reservations[(src, dst)] = {'timeout': (duration), 'bw': (bandwidth), 'priority': (priority), 'handle': entry_handle, 'path': path}
                print('Successful reservation({}->{}): path: {}'.format(src, dst, '->'.join(path)))
            else:
                print('\033[91mFailed reservation({}->{}): path: {}\033[0m'.format(src, dst, '->'.join(path)))

        else:
            print('Warning: Hosts are connected to the same switch!')


    def add_reservation(self, src, dst, duration, bandwidth, priority):
        """Adds a new reservation taking into account the priority. This
        addition can potentially move or delete other allocations.

        Args:
            src (str): src name
            dst (str): dst name
            duration (float): reservation timeout
            bandwidth (float): requested bandwidth in mbps
            priority (int): reservation priority
        """
        
        # locks the self.current_reservations data structure. This is done
        # because there is a thread that could access it concurrently.
        with self.update_lock:

            # if reservation exists, we allocate it again, by just updating the entry
            # for that we set the FLAG UPDATE_ENTRY and restore its link capacity 
            # such the new re-allocation with a possible new bw/prioirty can be done
            # taking new capacities into account.
            UPDATE_ENTRY = False
            if self.current_reservations.get((src, dst), None):
                data = self.current_reservations[(src, dst)]
                path = data['path']
                bw = data['bw']
                # updates link capacities
                self.add_link_capacity(path, bw)
                UPDATE_ENTRY = True

            # finds the best (if exists) path to allocate the requestes reservation
            path = self.get_available_path(src, dst, bandwidth)

            if path:   
                # add or update the reservation 
                self._add_reservation(src, dst, duration, bandwidth, priority, path, UPDATE_ENTRY)

            # Cant be allocated! However, it might be possible to re-allocate things 
            else:
                # check if the flow could be placed removing lower priorities
                previous_links_capacities =  self.links_capacity.copy()
                for reservation, data in self.current_reservations.items():
                    # make sure we do not remove ourselves 
                    # again in case this is a modification
                    if reservation == (src, dst):
                        continue
                    if data['priority'] < priority:
                        self.add_link_capacity(data['path'], data['bw'])

                # check if it fits in a newtwork without lower priority flows
                path = self.get_available_path(src, dst, bandwidth)

                # we rebalance lower priority reservations if possible
                if path:                   
                    # adds main new allocation
                    self._add_reservation(src, dst, duration, bandwidth, priority, path, UPDATE_ENTRY)

                    # re-allocate everything if possible 
                    for reservation, data in sorted(self.current_reservations.items(), key=lambda x: x[1]['priority'], reverse=True):
                        if data['priority'] < priority:
                            src, dst = reservation[0], reservation[1]
                            path = self.get_available_path(src, dst, data['bw'])
                            if path:   
                                # add or update the reservation 
                                self._add_reservation(src, dst, data['timeout'], data['bw'], data['priority'], path, True)
                            else:
                                # delete it
                                data = self.current_reservations[(src, dst)]
                                path = data['path']
                                bw = data['bw']
                                self.sub_link_capacity(path, bw)
                                print('\033[91mDeleting allocation {}->{} due to a higher priority allocation!\033[0m'.format(src, dst))
                                self.del_reservation(src, dst)

                else:
                    # restore capacities
                    self.links_capacity = previous_links_capacities
                    # if we failed and it was an entry to be updated we remove it
                    if UPDATE_ENTRY:
                        data = self.current_reservations[(src, dst)]
                        path = data['path']
                        bw = data['bw']
                        self.sub_link_capacity(path, bw)
                        print('Deleting new allocation. Does not fit anymore!')
                        self.del_reservation(src, dst)
                    print('\033[91mRESERVATION FAILURE: no bandwidth available!\033[0m')

    def del_reservation(self, src, dst):
        """Deletes a reservation between src and dst, if exists. To 
        delete the reservation the self.current_reservations data structure 
        is used to retrieve all the needed information. After deleting the reservation
        from the ingress switch, path capacities are updated.

        Args:
            src (str): src name
            dst (str): dst name
        """

        # checks if there is an allocation between src->dst
        entry = self.current_reservations.get((src, dst), None)
        if entry:
            # gets handle to delete entry
            entry_handle = entry['handle']
            # gets src ingress switch
            sw_gw = self.topo.get_host_gateway_name(src)
            # removes table entry using the handle
            self.controllers[sw_gw].table_delete('FEC_tbl', entry_handle, True)
            # updates links capacity
            self.add_link_capacity(entry['path'], entry['bw'])
            # removes the reservation from the controllers memory
            del(self.current_reservations[(src, dst)])
            print('\nRSVP Deleted/Expired Reservation({}->{}): path: {}'.format(src, dst, '->'.join(entry['path'])))
        else:
            print('No entry for {} -> {}'.format(src, dst))

    def del_all_reservations(self):
        """Deletes all the current reservations
        """

        # locks the self.current_reservations data structure. This is done
        # because there is a thread that could access it concurrently.
        with self.update_lock:
            
            # makes a copy of all the reservation pairs
            reservation_keys = list(self.current_reservations.keys())
            for src, dst in reservation_keys:
                self.del_reservation(src, dst)
    

if __name__ == '__main__':
    controller = RSVPController()
    controller.set_mpls_tbl_labels()
    cli = RSVPCLI(controller)