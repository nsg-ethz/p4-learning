/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

//My includes
#include "include/headers.p4"
#include "include/parsers.p4"

#define REGISTER_SIZE 1024
#define REGISTER_WIDTH 32

#define PKT_INSTANCE_TYPE_NORMAL 0
#define PKT_INSTANCE_TYPE_INGRESS_CLONE 1
#define PKT_INSTANCE_TYPE_EGRESS_CLONE 2
#define PKT_INSTANCE_TYPE_COALESCED 3
#define PKT_INSTANCE_TYPE_INGRESS_RECIRC 4
#define PKT_INSTANCE_TYPE_REPLICATION 5
#define PKT_INSTANCE_TYPE_RESUBMIT 6


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

    register <bit<REGISTER_WIDTH>>(REGISTER_SIZE) loadbalance_seed;

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action set_egress_type (bit<4> egress_type){
        meta.egress_type = egress_type;
    }

    table egress_type {
        key = {
            standard_metadata.egress_spec: exact;
        }

        actions = {
            set_egress_type;
            NoAction;
        }
        size=64;
        default_action = NoAction;
    }

    action update_flow_seed(){
        bit<12> register_index;
        bit<32> seed;
        random(seed, (bit<32>)0, (bit<32>)1234567);

        hash(register_index,
	    HashAlgorithm.crc16,
	    (bit<1>)0,
	    { hdr.ipv4.dstAddr,
	      hdr.ipv4.srcAddr,
              hdr.tcp.srcPort,
              hdr.tcp.dstPort,
              hdr.ipv4.protocol},
	      (bit<12>)REGISTER_SIZE);

	loadbalance_seed.write((bit<32>)register_index, seed);
    }

    action ecmp_group(bit<14> ecmp_group_id, bit<16> num_nhops){

        bit<12> register_index;
        bit<32> seed;

        hash(register_index,
	    HashAlgorithm.crc16,
	    (bit<1>)0,
	    { hdr.ipv4.srcAddr,
	      hdr.ipv4.dstAddr,
              hdr.tcp.srcPort,
              hdr.tcp.dstPort,
              hdr.ipv4.protocol},
	      (bit<12>)REGISTER_SIZE);

	loadbalance_seed.read(seed, (bit<32>)register_index);

        hash(meta.ecmp_hash,
	    HashAlgorithm.crc16,
	    (bit<1>)0,
	    { hdr.ipv4.srcAddr,
	      hdr.ipv4.dstAddr,
              hdr.tcp.srcPort,
              hdr.tcp.dstPort,
              hdr.ipv4.protocol,
              seed},
	      num_nhops);
	    meta.ecmp_group_id = ecmp_group_id;
    }

    action set_nhop(macAddr_t dstAddr, egressSpec_t port) {

        //set the src mac address as the previous dst, this is not correct right?
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;

       //set the destination mac address that we got from the match in the table
        hdr.ethernet.dstAddr = dstAddr;

        //set the output port that we also get from the table
        standard_metadata.egress_spec = port;

        //decrease ttl by 1
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ecmp_group_to_nhop {
        key = {
            meta.ecmp_group_id: exact;
            meta.ecmp_hash: exact;
        }
        actions = {
            drop;
            set_nhop;
        }
        size = 1024;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_nhop;
            ecmp_group;
            drop;
        }
        size = 1024;
        default_action = drop;
    }

    apply {

        if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_INGRESS_RECIRC){
            bit<32> src_ip = hdr.ipv4.srcAddr;
            hdr.ipv4.srcAddr = hdr.ipv4.dstAddr;
            hdr.ipv4.dstAddr = src_ip;
            hdr.ethernet.etherType = TYPE_FEEDBACK;
        }

        //Only forward packets if they are IP and TTL > 1
        if (hdr.ipv4.isValid() && hdr.ipv4.ttl > 1){
            switch (ipv4_lpm.apply().action_run){
                ecmp_group: {
                    ecmp_group_to_nhop.apply();
                }
            }
        }

        egress_type.apply();

        if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_NORMAL && hdr.ethernet.etherType == TYPE_FEEDBACK && meta.egress_type == TYPE_EGRESS_HOST){
            update_flow_seed();
            drop();
        }

    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    register <bit<48>>(REGISTER_SIZE) feedback_ts;

    action read_feedback_ts(){

        hash(meta.feedback_register_index,
	    HashAlgorithm.crc16,
	    (bit<1>)0,
	    { hdr.ipv4.srcAddr,
	      hdr.ipv4.dstAddr,
              hdr.tcp.srcPort,
              hdr.tcp.dstPort,
              hdr.ipv4.protocol},
	      (bit<12>)REGISTER_SIZE);

	feedback_ts.read(meta.feedback_ts, (bit<32>)meta.feedback_register_index);

    }

    apply {
        //Cloned packet, used to generate probe
        if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_EGRESS_CLONE){
            recirculate_preserving_field_list(0);
        }

        else if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_NORMAL && hdr.ethernet.etherType != TYPE_FEEDBACK) {

            if (hdr.tcp.isValid()){
                if (hdr.telemetry.isValid()){
                    if (hdr.telemetry.enq_qdepth < (bit<16>)standard_metadata.enq_qdepth && meta.egress_type == TYPE_EGRESS_SWITCH){
                        hdr.telemetry.enq_qdepth = (bit<16>)standard_metadata.enq_qdepth;
                    }
                    //If egresss. We do not update the queue of the last hop because this can not be changed anyways.
                    else if (meta.egress_type == TYPE_EGRESS_HOST){
                        hdr.ethernet.etherType = TYPE_IPV4;
                        hdr.telemetry.setInvalid();

                        //clone packet if above threshold
                        if (hdr.telemetry.enq_qdepth > 50){
                            read_feedback_ts();
                            bit<48> backoff;
                            random(backoff, 48w500000, 48w1000000);
                            if ((standard_metadata.ingress_global_timestamp - meta.feedback_ts) > backoff){
	                        feedback_ts.write((bit<32>)meta.feedback_register_index, standard_metadata.ingress_global_timestamp);
	                        bit<8> probability;
	                        random(probability, 8w0, 8w3);
	                        if (probability == 0) {
                                    clone(CloneType.E2E, 100);
                                }
                             }
                        }
                    }
                }
                else {
                    //If ingress and next hop is a switch
                    if (meta.egress_type == TYPE_EGRESS_SWITCH){
                        hdr.telemetry.setValid();
                        hdr.telemetry.enq_qdepth = (bit<16>)standard_metadata.enq_qdepth;
                        hdr.ethernet.etherType = TYPE_TELEMETRY;
                        hdr.telemetry.nextHeaderType = TYPE_IPV4;
                    }
                }
            }
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
              hdr.ipv4.tos,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr},
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