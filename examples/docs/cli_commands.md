
# CLI commands
`~/p4/bmv2/targets/simple_switch/sswitch_CLI`

Through this CLI, methods provided by the `SimpleSwitchAPI` and the `RuntimeAPI` can be accessed.

## SimpleSwitchAPI
`~/p4/bmv2/targets/simple_switch/sswitch_CLI.py`
- Set depth of one / all egress queue(s): `set_queue_depth <nb_pkts> [<egress_port>]`
- Set rate of one / all egress queue(s): `set_queue_rate <rate_pps> [<egress_port>]`
- Add mirroring mapping: `mirroring_add <mirror_id> <egress_port>`
- Delete mirroring mapping: `mirroring_delete <mirror_id>`
- Get time elapsed (in microseconds) since the switch started: `get_time_elapsed`
- Get time elapsed (in microseconds) since the switch clock's epoch: `get_time_since_epoch`


## RuntimeAPI
`~/p4/bmv2/tools/runtime_CLI.py`

- Run a shell command: `shell`
- List tables defined in the P4 program: `show_tables`
- List actions defined in the P4 program: `show_actions`
- List one table's actions as per the P4 program: `table_show_actions <table_name>`
- Show info about a table: `table_info <table_name>`
- Set default action for a match table: `table_set_default <table name> <action name> <action parameters>`
- Return the number of entries in a match table (direct or indirect): `table_num_entries <table name>`
- Add entry to a match table: `table_add <table name> <action name> <match fields> => <action parameters> [priority]`
- Set a timeout in ms for a given entry; the table has to support timeouts: `table_set_timeout <table_name> <entry handle> <timeout (ms)>`
- Add entry to a match table: `table_modify <table name> <action name> <entry handle> [action parameters]`
- Delete entry from a match table: `table_delete <table name> <entry handle>`
- Add a member to an action profile: `act_prof_create_member <action profile name> <action_name> [action parameters]`
- Add a member to an indirect match table: `table_indirect_create_member <table name> <action_name> [action parameters]`
- Delete a member in an action profile: `act_prof_delete_member <action profile name> <member handle>`
- Delete a member in an indirect match table: `table_indirect_delete_member <table name> <member handle>`
- Modify member in an action profile: `act_prof_modify_member <action profile name> <action_name> <member_handle> [action parameters]`
- Modify member in an indirect match table: `table_indirect_modify_member <table name> <action_name> <member_handle> [action parameters]`
- Add entry to an indirect match table: `table_indirect_add <table name> <match fields> => <member handle> [priority]`
- Add entry to an indirect match table: `table_indirect_add <table name> <match fields> => <group handle> [priority]`
- Delete entry from an indirect match table: `table_indirect_delete <table name> <entry handle>`
- Set default member for indirect match table: `table_indirect_set_default <table name> <member handle>`
- Set default group for indirect match table: `table_indirect_set_default <table name> <group handle>`
- Add a group to an action pofile: `act_prof_create_group <action profile name>`
- Add a group to an indirect match table: `table_indirect_create_group <table name>`
- Delete a group from an action profile: `act_prof_delete_group <action profile name> <group handle>`
- Delete a group: `table_indirect_delete_group <table name> <group handle>`
- Add member to group in an action profile: `act_prof_add_member_to_group <action profile name> <member handle> <group handle>`
- Add member to group: `table_indirect_add_member_to_group <table name> <member handle> <group handle>`
- Remove member from group in action profile: `act_prof_remove_member_from_group <action profile name> <member handle> <group handle>`
- Remove member from group: `table_indirect_remove_member_from_group <table name> <member handle> <group handle>`
- Create multicast group: `mc_mgrp_create <group id>`
- Destroy multicast group: `mc_mgrp_destroy <group id>`
- Create multicast node: `mc_node_create <rid> <space-separated port list> [ | <space-separated lag list> ]`
- Update multicast node: `mc_node_update <node handle> <space-separated port list> [ | <space-separated lag list> ]`
- Associate node to multicast group: `mc_node_associate <group handle> <node handle>`
- Dissociate node from multicast group: `mc_node_associate <group handle> <node handle>`
- Destroy multicast node: `mc_node_destroy <node handle>`
- Set lag membership of port list: `mc_set_lag_membership <lag index> <space-separated port list>`
- Dump entries in multicast engine: `mc_dump`
- Load new json config: `load_new_config_file <path to .json file>`
- Swap the 2 existing configs, need to have called load_new_config_file before: `swap_configs`
- Configure rates for an entire meter array: `meter_array_set_rates <name> <rate_1>:<burst_1> <rate_2>:<burst_2> ...`
- Configure rates for a meter: `meter_set_rates <name> <index> <rate_1>:<burst_1> <rate_2>:<burst_2> ...`
- Retrieve rates for a meter: `meter_get_rates <name> <index>`
- Read counter value: `counter_read <name> <index>`
- Reset counter: `counter_reset <name>`
- Read register value: `register_read <name> <index>`
- Write register value: `register_write <name> <index> <value>`
- Reset all the cells in the register array to 0: `register_reset <name>`
- Display some information about a table entry: `table_dump_entry <table name> <entry handle>`
- Display some information about a member: `act_prof_dump_member <action profile name> <member handle>`
- Display some information about a member: `table_dump_member <table name> <member handle>`
- Display some information about a group: `table_dump_group <action profile name> <group handle>`
- Display some information about a group: `table_dump_group <table name> <group handle>`
- Display entries in an action profile: `act_prof_dump <action profile name>`
- Display entries in a match-table: `table_dump <table name>`
- Display some information about a table entry: `table_dump_entry_from_key <table name> <match fields> [priority]`
- Add a port to the switch (behavior depends on device manager used): `port_add <iface_name> <port_num> [pcap_path]`
- Removes a port from the switch (behavior depends on device manager used): `port_remove <port_num>`
- Shows the ports connected to the switch: `show_ports`
- Show some basic info about the switch: `switch_info`
- Reset all state in the switch (table entries, registers, ...), but P4 config is preserved: `reset_state`
- Retrieves the JSON config currently used by the switch and dumps it to user-specified file: `write_config_to_file <filename>`
- Serialize the switch state and dumps it to user-specified file: `serialize_state <filename>`
- Change the parameters for a custom crc16 hash: `set_crc16_parameters <name> <polynomial> <initial remainder> <final xor value> <reflect data?> <reflect remainder?>`
- Change the parameters for a custom crc32 hash: `set_crc32_parameters <name> <polynomial> <initial remainder> <final xor value> <reflect data?> <reflect remainder?>`