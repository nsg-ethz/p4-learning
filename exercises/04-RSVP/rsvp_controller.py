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
                pass
                # PART 1, TASK 5.1 Iterate self.current_reservations, update timeout, and if any 
                # entry expired, delete it.
  

    def set_mpls_tbl_labels(self):
        """We set all the table defaults to reach all the hosts/networks in the network
        """

        # for all switches
        for sw_name, controller in self.controllers.items():
            pass
            # TODO PART 1 TASK 2
            # 1) for all the hosts connected to this switch add the FEC_tbl entry
            # 2) for all switches connected to this switch add the 2 mplt_tbl entries


    def build_mpls_path(self, switches_path):
        """Using a path of switches builds the mpls path. In our simplification
        labels are port indexes. 

        Args:
            switches_path (list): path of switches to allocate

        Returns:
            list: label path
        """

        label_path = []

        # PART 1, TASK 3.2 Get mpls stack of labels

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

        # PART 1, TASK 3.1 Implement this function and its helper check_if_reservation_fits
  
    
    def add_link_capacity(self, path, bw):
        """Adds bw capacity to a all the edges along path. This 
        function is used when an allocation is removed.

        Args:
            path (list): list of switches
            bw (float): requested bandwidth in mbps
        """

         # PART 1, TASK 3.4 add bw to edges

    def sub_link_capacity(self, path, bw):
        """subtracts bw capacity to a all the edges along path. This 
        function is used when an allocation is added.

        Args:
            path (list): list of switches
            bw (float): requested bandwidth in mbps
        """
        
        # PART 1, TASK 3.4 sub bw to edges

    
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

        # PART 1, TASK 3.1 Implement this function and its helper check_if_reservation_fits


    def get_meter_rates_from_bw(self, bw, burst_size=700000):
        """Returns the CIR and PIR rates and bursts to configure 
          meters at bw.

        Args:
            bw (float): desired bandwdith in mbps
            burst_size (int, optional): Max capacity of the meter buckets. Defaults to 50000.

        Returns:
            list: [(rate1, burst1), (rate2, burst2)]
        """

        # PART 2 TASK 1.2 get the CIR and PIR from bw

    def set_direct_meter_bandwidth(self, sw_name, meter_name, handle, bw):
        """Sets a meter entry (using a table handle) to color packets using
           bw mbps

        Args:
            sw_name (str): switch name
            meter_name (str): meter name
            handle (int): entry handle
            bw (float): desired bandwidth to rate limit
        """

        # PART 2 TASK 1.3 use the controller to configure the meter


    def add_reservation(self, src, dst,duration, bandwidth, priority):
        """[summary]

        Args:
            src (str): src name
            dst (str): dst name
            duration (float): reservation timeout
            bw (float): requested bandwidth in mbps
            priority (int): reservation priority
        """
       
        # locks the self.current_reservations data structure. This is done
        # because there is a thread that could access it concurrently.
        with self.update_lock:

            # PART 1, TASK 3.4 check if there is an existing reservation for (src,dst). 
            # you can use the self.current_reservations dictionary to check it.
            # If the reservation exists get the path and bw and update the links capacity 
            # data structure using `self.add_link_capacity(path, bw)`
            
            # PART 1, TASK 3.1. Once get_available_path is implemented call it to get a path.
            path = self.get_available_path(src, dst, bandwidth)

            # PART 1, TASK 3.2 If there is an available path 
            if path:    
                pass
                # PART 1, TASK 3.2 Get mpls stack of labels

                # PART 1, TASK 3.3 get:
                # 1) ingress switch name
                # 2) action name using `mpls_ingress_x_hop` set x as number of labels
                # 3) src and dst ips (your match)
                # 4) make sure all your labels are strings and use them as action parameters

                # PART 1, TASK 3.4

                # check if its a new or an existing reservation (to update)

                # add entry or modify
                # PART 2  TASK 1.4 Configure the associated meter properly.

                # update controllers data structures: self.current_reservation & self.links_capacity
               

            # PART 1, TASK 3.2 otherwise we print no path available
            else:
                # PART 1, task 4.3 if we dont find a path but the reservation existed
                # you have to erase it while making sure you update links_capacity accordingly 
                print("\033[91mRESERVATION FAILURE: no bandwidth available!\033[0m")


    def del_reservation(self, src, dst):
        """Deletes a reservation between src and dst, if exists. To 
        delete the reservation the self.current_reservations data structure 
        is used to retrieve all the needed information. After deleting the reservation
        from the ingress switch, path capacities are updated.

        Args:
            src (str): src name
            dst (str): dst name
        """

        # PART 1, TASK 4.1 remove the reservation from the switch, controller and update links capacities.

    def del_all_reservations(self):
        """Deletes all the current reservations
        """

        # locks the self.current_reservations data structure. This is done
        # because there is a thread that could access it concurrently.
        with self.update_lock:
            pass
            # PART 1, TASK 4.2 remove all the reservations            
    

if __name__ == '__main__':
    controller = RSVPController()
    controller.set_mpls_tbl_labels()
    cli = RSVPCLI(controller)