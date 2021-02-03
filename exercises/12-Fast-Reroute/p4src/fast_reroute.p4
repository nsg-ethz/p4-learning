/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

//My includes
#include "include/headers.p4"
#include "include/parsers.p4"

#define N_PREFS 1024
#define PORT_WIDTH 32
#define N_PORTS 512



/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    // Register to look up the port of the default next hop.
    register<bit<PORT_WIDTH>>(N_PREFS) primaryNH; 

    // Register containing link states. 0: No Problems. 1: Link failure.
    // This register is updated by CLI.py, you only need to read from it.
    register<bit<1>>(N_PORTS) linkState;

    action rewriteMac(macAddr_t dstAddr){
	    hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
	}

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action read_port(bit<32>  index){
        meta.index = index;
        // Read primary next hop and write result into meta.nextHop.
        primaryNH.read(meta.nextHop,  meta.index);
    }


    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            read_port;
            drop;
        }
        size = 512;
        default_action = drop;
    }

    table rewrite_mac {
        key = {
             meta.nextHop: exact;
        }
        actions = {
            rewriteMac;
            drop;
        }
        size = 512;
        default_action = drop;
    }
    
    apply {
        if (hdr.ipv4.isValid()){
            ipv4_lpm.apply();

            // TODO: Read the link state for the selected next hop.
            // TODO: Switch the the backup next hop if the link state is 1.

            // Do not change the following lines: They set the egress port
            // and update the MAC address.
            standard_metadata.egress_spec = (bit<9>) meta.nextHop;
		    rewrite_mac.apply();    
        }
    }
}
/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    apply {

    }

}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
  update_checksum(
      hdr.ipv4.isValid(),
            { hdr.ipv4.version,
        hdr.ipv4.ihl,
              hdr.ipv4.dscp,
              hdr.ipv4.ecn,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}




/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
