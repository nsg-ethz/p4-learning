"""
Inspired in the mininet CLI.
"""

import subprocess
from cmd import Cmd
from os import isatty
from select import poll, POLLIN
import select
import sys
import os
import atexit

class RSVPCLI( Cmd ):
    "Simple command-line interface to talk to nodes."

    prompt = 'rsvp-menu> '

    def __init__( self, controller, stdin=sys.stdin, script=None,
                  *args, **kwargs ):

        self.controller = controller
        # Local variable bindings for py command
        self.locals = { 'controller': controller }
        # Attempt to handle input
        self.inPoller = poll()
        self.inPoller.register( stdin )
        self.inputFile = script
        Cmd.__init__( self, *args, stdin=stdin, **kwargs )

        self.hello_msg()
        if self.inputFile:
            self.do_source( self.inputFile )
            return

        self.initReadline()
        self.run()

    readlineInited = False

    def hello_msg(self):
        """
        """
        print('======================================================================')
        print('Welcome to the RSVP CLI')
        print('======================================================================')
        print('You can now make reservations for your hosts in the network.')
        print('To add a reservation run:')
        print('add_reservation <src> <dst> <duration> <bw> <priority>')
        print('')
        print('To delete a reservation run: ')
        print('del_reservation <src> <dst>')
        print('')


    @classmethod
    def initReadline( cls ):
        "Set up history if readline is available"
        # Only set up readline once to prevent multiplying the history file
        if cls.readlineInited:
            return
        cls.readlineInited = True
        try:
            from readline import ( read_history_file, write_history_file,
                                   set_history_length )
        except ImportError:
            pass
        else:
            history_path = os.path.expanduser( '~/.rsvp_controller_history' )
            if os.path.isfile( history_path ):
                read_history_file( history_path )
                set_history_length( 1000 )
            atexit.register( lambda: write_history_file( history_path ) )

    def run( self ):
        "Run our cmdloop(), catching KeyboardInterrupt"
        while True:
            try:
                if self.isatty():
                    subprocess.call( 'stty echo sane intr ^C',shell=True)
                self.cmdloop()
                break
            except KeyboardInterrupt:
                # Output a message - unless it's also interrupted
                # pylint: disable=broad-except
                try:
                    print( '\nInterrupt\n' )
                except Exception:
                    pass
                # pylint: enable=broad-except

    def emptyline( self ):
        "Don't repeat last command when you hit return."
        pass

    def getLocals( self ):
        "Local variable bindings for py command"
        self.locals.update( self.mn )
        return self.locals

    helpStr = (
        'To add a reservation run:\n'
        'add_reservation <src> <dst> <duration> <bw> <priority>\n'
        '\n'
        'To delete a reservation run: \n'
        'del_reservation <src> <dst>\n'
        ''
    )

    def do_help( self, line ):
        "Describe available CLI commands."
        Cmd.do_help( self, line )
        if line == '':
            print( self.helpStr )
  
    def do_exit( self, _line ):
        "Exit"
        assert self  # satisfy pylint and allow override
        return 'exited by user command'

    def do_quit( self, line ):
        "Exit"
        return self.do_exit( line )

    def do_EOF( self, line ):
        "Exit"
        print( '\n' )
        return self.do_exit( line )

    def isatty( self ):
        "Is our standard input a tty?"
        return isatty( self.stdin.fileno() )

    """
    RSVP COMMANDS
    """

    def do_add_reservation(self, line=""):
        """Adds a reservation using mpls.
        add_reservation <src> <dst> <duration> <bw> <priority>
        """

        # geta rguments
        args = line.split()
        # defaults
        duration = 9999
        bw = 1
        priority = 1

        if len(args) < 2:
            print("Not enough args!")
            return
        
        elif len(args) == 2:
            src, dst =  args
        
        elif len(args) == 3:
            src, dst, duration =  args
        
        elif len(args) == 4:
            src, dst, duration, bw =  args
        
        elif len(args) == 5:
            src, dst, duration, bw,  priority =  args
        
        else:
            print("Too many args!")
            return

        # casts
        duration = float(duration)
        bw = float(bw)
        priority = int(priority)
        
        # add entry
        res = self.controller.add_reservation(src, dst, duration, bw,  priority)


    def do_del_reservation(self, line=""):
        """Deletes a reservation"""

        # gets arguments
        args = line.split()

        if len(args) < 2:
            print("Not enough args!")
            return
        
        elif len(args) == 2:
            src, dst =  args[:2]
        
        else:
            print("Too many args!")
            return

        # add entry
        res = self.controller.del_reservation(src, dst)

    def do_del_all_reservations(self, line =""):
        """Deletes all the reservations"""

        res = self.controller.del_all_reservations()

    def do_print_reservations(self, line = ""):
        """Prints current reservations"""

        print("Current Reservations:")
        print("---------------------")
        for i, ((src, dst), data) in enumerate(self.controller.current_reservations.items()):
            print("{:>3} {}->{} : {}, bw:{}, priority:{}, timeout:{}".format(i, src, dst, 
                "->".join(data['path']), data['bw'], data['priority'], data["timeout"] ))
    
    def do_print_link_capacity(self, line=""):
        """Prints current link capacities"""

        print("Current Link Capacities:")
        print("---------------------")
        for edge, bw in self.controller.links_capacity.items():
            print("{} -> {}".format(edge, bw))
        