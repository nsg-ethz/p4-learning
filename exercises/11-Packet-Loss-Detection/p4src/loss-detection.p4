/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#include "include/headers.p4"
#include "include/parsers.p4"

/* CONSTANTS */
#define NUM_PORTS 2
#define NUM_BATCHES 2

#define REGISTER_SIZE_TOTAL 2048 //256
#define REGISTER_BATCH_SIZE REGISTER_SIZE_TOTAL/NUM_BATCHES
#define REGISTER_PORT_SIZE REGISTER_BATCH_SIZE/NUM_PORTS

#define REGISTER_CELL_WIDTH 64

#define LOSS_CHANGE_OF_BATCH 0x1234

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

    register<bit<16>>(1) last_batch_id;

    # TODO 5 define the 8 registers. 4 for the um and 4 for the dm

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action compute_hash_indexes(){

       // TODO 6 define the 6 custom32 hash functions
    }

    action apply_um_meter(){

        // TODO 7 implement the insertion of a packet into the um meter
    }

    action apply_dm_meter(){

        // TODO 8 impelement the insertion of a packet into the dm meter

    }

    action set_egress_port(bit<9> egress_port){
        standard_metadata.egress_spec = egress_port;
    }

    table forwarding {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            set_egress_port;
            drop;
            NoAction;
        }
        size = 64;
        default_action = drop;
    }

    // TODO 4 implement the remove_header action

    // TODO 3 Define the remove_loss_header table

    apply {

        // TODO 9: Understand the ingres pipeline

        if (hdr.ipv4.isValid())
        {
            // Set the tcp/udp ports to a metadata field so we can hash them without
            // having to duplicate the hash functions
            if (hdr.tcp.isValid())
            {
                meta.tmp_src_port = hdr.tcp.srcPort;
                meta.tmp_dst_port = hdr.tcp.dstPort;
            }
            else if (hdr.udp.isValid())
            {
                meta.tmp_src_port = hdr.udp.srcPort;
                meta.tmp_dst_port = hdr.udp.dstPort;
            }

            // Sets egress port 1->2 2->1
            forwarding.apply();

            // Assumes that the comunication is not host -- switch -- host, otherwise we
            // would have to check that too
            if (!hdr.loss.isValid())
            {
               hdr.loss.setValid();
               hdr.loss.nextProtocol = hdr.ipv4.protocol;
               hdr.ipv4.totalLen = hdr.ipv4.totalLen + 2;
               hdr.ipv4.protocol = TYPE_LOSS;

               meta.dont_execute_dm = 1;
            }
            else{
               meta.previous_batch_id = (bit<16>)hdr.loss.batch_id;
            }

            // Compute local batch
            meta.batch_id = (bit<16>)((standard_metadata.ingress_global_timestamp >> 21) % 2);

            last_batch_id.read(meta.last_local_batch_id, (bit<32>)0);
            last_batch_id.write((bit<32>)0, meta.batch_id);
            // Only works if there is enough traffic. For example
            // if there is 1 packet every 1 second it can happen
            // that the batch id never changes
            if (meta.batch_id != meta.last_local_batch_id)
            {
                clone3(CloneType.I2E, 100, meta);
            }

            // Update the header batch id with the current one
            hdr.loss.batch_id = (bit<1>)meta.batch_id;

            // Compute the hash indexes before we apply the meters
            compute_hash_indexes();
            remove_loss_header.apply();

            if (meta.dont_execute_um == 0)
            {
               apply_um_meter();
            }

            if (meta.dont_execute_dm == 0)
            {
               apply_dm_meter();
            }

            // Drop the packet if ttl=1
            if (hdr.ipv4.ttl == 1)
            {
                drop();
            }
            else
            {
                hdr.ipv4.ttl = hdr.ipv4.ttl -1;
            }
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
        // If ingress clone
        // TODO 10
        if (standard_metadata.instance_type == 1){
            hdr.loss.setValid();
            hdr.ipv4.setInvalid();
            hdr.loss.batch_id = (bit<1>)meta.last_local_batch_id;
            hdr.loss.padding = (bit<7>)0;
            hdr.loss.nextProtocol = (bit<8>)0;
            hdr.ethernet.etherType = LOSS_CHANGE_OF_BATCH;
            truncate((bit<32>)16); //ether+loss header
        }
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