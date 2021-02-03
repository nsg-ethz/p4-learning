"""
Inspired in the mininet CLI.
"""
# pylint: disable=keyword-arg-before-vararg,invalid-name

import atexit
import os
import subprocess
import sys
from cmd import Cmd
from select import poll
from textwrap import dedent


class CLI(Cmd):
    "Simple command-line interface to talk to nodes."

    prompt = 'link-menu> '

    def __init__(self, controller, stdin=sys.stdin, *args, **kwargs):
        self.controller = controller
        # Local variable bindings for py command
        self.locals = {'controller': controller}
        # Attempt to handle input
        self.inPoller = poll()
        self.inPoller.register(stdin)
        Cmd.__init__(self, *args, stdin=stdin, **kwargs)

        print "Checking links and synchronizing with switches..."
        failed_links = self.check_all_links()
        if failed_links:
            formatted = ["%s-%s" % link for link in failed_links]
            print "Currently failed links:", ", ".join(formatted)
            # Notify the controller so the network will work after boot.
            self.do_notify()
        else:
            print "Currently failed links: None."
        self.do_synchronize()

        self.hello_msg()

        self.initReadline()
        self.run()

    readlineInited = False

    helpStr = dedent("""
    Mangage linkstate with the following commands:
        fail node1 node2    Fail link between node1 and node2.
        reset               Reset all link failures.

    The switch linkstate registers are automatically updated. The controller
    is only notified on demand. You can use the commands:
        synchronize         Manually synchronize linkstate registers.
        notify              Notify controller about failure.
    """).strip()

    header = dedent("""
    ===========================================================================
    Welcome to the Reroute CLI
    ===========================================================================
    """).strip()

    def hello_msg(self):
        """Greet user."""
        print
        print self.header
        print
        print self.helpStr
        print

    @classmethod
    def initReadline(cls):  # pylint: disable=invalid-name
        "Set up history if readline is available"
        # Only set up readline once to prevent multiplying the history file
        if cls.readlineInited:
            return
        cls.readlineInited = True
        try:
            from readline import (read_history_file, set_history_length,
                                  write_history_file)
        except ImportError:
            pass
        else:
            history_path = os.path.expanduser('~/.rsvp_controller_history')
            if os.path.isfile(history_path):
                read_history_file(history_path)
                set_history_length(1000)
            atexit.register(lambda: write_history_file(history_path))

    def run(self):
        "Run our cmdloop(), catching KeyboardInterrupt"
        while True:
            try:
                if self.isatty():
                    subprocess.call('stty echo sane intr ^C', shell=True)
                self.cmdloop()
                break
            except KeyboardInterrupt:
                # Output a message - unless it's also interrupted
                try:
                    print '\nInterrupt\n'
                except Exception:  # pylint: disable=broad-except
                    pass

    def emptyline(self):
        "Don't repeat last command when you hit return."
        pass

    def do_help(self, arg):
        "Describe available CLI commands."
        Cmd.do_help(self, arg)
        if arg == '':
            print self.helpStr

    def do_exit(self, _line):
        "Exit"
        assert self  # satisfy pylint and allow override
        return 'exited by user command'

    def do_quit(self, line):
        "Exit"
        return self.do_exit(line)

    def do_EOF(self, line):  # pylint: disable=invalid-name
        "Exit"
        print '\n'
        return self.do_exit(line)

    def isatty(self):
        "Is our standard input a tty?"
        return os.isatty(self.stdin.fileno())

    # Link management commands.
    # =========================

    def do_fail(self, line=""):
        """Fail a link between two nodes.

        Usage: fail_link node1 node2
        """
        try:
            node1, node2 = line.split()
            link = (node1, node2)
        except ValueError:
            print "Provide exactly two arguments: node1 node2"
            return

        for node in (node1, node2):
            if node not in self.controller.controllers:
                print "%s is not a valid node!" % node, \
                    "You can only fail links between switches"
                return

        if node2 not in self.controller.topo[node1]:
            print "The link %s-%s does not exist." % link
            return

        failed_links = self.check_all_links()
        for failed_link in failed_links:
            if failed_link in [(node1, node2), (node2, node1)]:
                print "The link %s-%s is already down!" % (node1, node2)
                return

        print "Failing link %s-%s." % link

        self.update_interfaces(link, "down")
        self.update_linkstate(link, "down")

    def do_reset(self, line=""):  # pylint: disable=unused-argument
        """Set all interfaces back up."""
        failed_links = self.check_all_links()
        for link in failed_links:
            print "Resetting failure for link %s-%s." % link
            self.update_interfaces(link, "up")
            self.update_linkstate(link, "up")

    def do_notify(self, line=""):  # pylint: disable=unused-argument
        """Notify controller of failures (or lack thereof)."""
        failed = self.check_all_links()
        self.controller.failure_notification(failed)

    def do_synchronize(self, line=""):  # pylint: disable=unused-argument
        """Ensure that all linkstate registers match the interface state."""
        print "Synchronizing link state registers with link state..."
        switchgraph = self.controller.topo.network_graph.subgraph(
            self.controller.controllers.keys()
        )
        for link in switchgraph.edges:
            ifs = self.get_interfaces(link)
            ports = self.get_ports(link)
            for node, intf, port in zip(link, ifs, ports):
                state = "0" if self.if_up(intf) else "1"
                print("%s: set port %s (%s) to %s." %
                      (node, port, intf, state))
                self.update_switch_linkstate(node, port, state)

    # Link management helpers.
    # ========================

    def check_all_links(self):
        """Check the state for all link interfaces."""
        failed_links = []
        switchgraph = self.controller.topo.network_graph.subgraph(
            self.controller.controllers.keys()
        )
        for link in switchgraph.edges:
            if1, if2 = self.get_interfaces(link)
            if not (self.if_up(if1) and self.if_up(if2)):
                failed_links.append(link)
        return failed_links

    @staticmethod
    def if_up(interface):
        """Return True if interface is up, else False."""
        cmd = ["ip", "link", "show", "dev", interface]
        return "state UP" in subprocess.check_output(cmd)

    def update_interfaces(self, link, state):
        """Set both interfaces on link to state (up or down)."""
        if1, if2 = self.get_interfaces(link)
        self.update_if(if1, state)
        self.update_if(if2, state)

    @staticmethod
    def update_if(interface, state):
        """Set interface to state (up or down)."""
        print "Set interface '%s' to '%s'." % (interface, state)
        cmd = ["sudo", "ip", "link", "set", "dev", interface, state]
        subprocess.check_call(cmd)

    def get_interfaces(self, link):
        """Return tuple of interfaces on both sides of the link."""
        node1, node2 = link
        if_12 = self.controller.topo[node1][node2]['intf']
        if_21 = self.controller.topo[node2][node1]['intf']
        return if_12, if_21

    def get_ports(self, link):
        """Return tuple of interfaces on both sides of the link."""
        node1, node2 = link
        if1, if2 = self.get_interfaces(link)
        port1 = self.controller.topo[node1]['interfaces_to_port'][if1]
        port2 = self.controller.topo[node2]['interfaces_to_port'][if2]
        return port1, port2

    def update_linkstate(self, link, state):
        """Update switch linkstate register for both link interfaces.

        The register array is indexed by the port number, e.g., the state for
        port 0 is stored at index 0.
        """
        node1, node2 = link
        port1, port2 = self.get_ports(link)
        _state = "1" if state == "down" else "0"
        print("Set linkstate for %s:%s and %s:%s to %s (%s)." %
              (node1, port1, node2, port2, _state, state))
        self.update_switch_linkstate(node1, port1, _state)
        self.update_switch_linkstate(node2, port2, _state)

    def update_switch_linkstate(self, switch, port, state):
        """Update the link state register on the device. """
        control = self.controller.controllers[switch]
        control.register_write('linkState', port, state)
