# Control Plane

## Simple Switch CLI

We can use the Simple Switch CLI to configure the switch and populate match-action tables.

#### Running the CLI

To get the switch CLI simply run:

```bash
simple_switch_CLI --thrift-port <port>
```

The CLI connect to the Thrift RPC server running in each switch process.
9090 is the default value but of course if you are running several devices
on your machine, you will need to provide a different port for each.
One CLI instance can only connect to one switch device.

#### Filling tables

The most used commands to modify table contents are:

  * table_set_default <table_name> <action_name> <action_parameters>
  * table_add <table_name> <action_name> <match_fields> => <action_parameters>

For example if we have the following table:

```
action drop(){
     // drops packet
     mark_to_drop(standard_metadata);
}

table table_name {

   action action_name(bit<8> action_parameter){
       ...
   }

   key = {
       standard_metadata.ingress_port: exact;
   }

   actions = {
       drop;
       action_name;
   }
```


```bash
table_set_default table_name drop
table_add table_name action_name 1 => 5
```

The first command would set the default action, and action parameters (none in this case) for table `table_name`. Thus, when
using the `table_name` table if there is no match, the drop action will be called.

In the second example command adds an entry that matches if the `standard_metadata.ingress_port` is equal to 1 and executes the
action `action_name` with `action_parameter` set to 5.

#### Writing the CLI input in a file

You can also populate the table writing the commands directly in a text file and then feeding the CLI:

```bash
simple_switch_CLI --thrift-port <port> < command_file.txt
```

#### Using P4 utils configuration file

Alternatively, you can use the p4-utils configuration file (i.e `p4app.json`) to set a `cli` configuration
file for each switch. When creating the topology, or rebooting switches, p4-utils will automatically use
the file to populate and configure switches.

To set default `cli` configuration files you need to define your switches like:

```javascript
    "switches": {
      "s1": {
        "cli_input": "<path_to_cli_commands_file>"
      }
    }
```

You can find all the documentation about `p4app.json` in the `p4-utils` [documentation](https://github.com/nsg-ethz/p4-utils#topology-description).


### P4 Utils Control Plane API

You can find a wrapper of the Control Plane CLI as one of the features of p4-utils. It basically allows you to do the same but instead of using text sent to
the CLI you can use the power of a scripting language such as python. You can read more about this API [here](https://github.com/nsg-ethz/p4-utils#control-plane-api).