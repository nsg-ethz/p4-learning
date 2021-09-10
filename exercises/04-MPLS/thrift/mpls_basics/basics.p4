/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

/* TODO 1.1: Create a new etherType for MPLS protocol, which will be used to identify it from the ethernet header. */

#define CONST_MAX_PORTS 	32
#define CONST_MAX_LABELS 	10

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

/* TODO 1.2: Create a header for MPLS protocol, called "mpls_t". The header should have 4 fields like we described in the README. */

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

/* TODO 2.1: Note that we have created this metadata struct, which will help us identify packets read from ingress and egress routers. */

struct metadata {
    bit<1> is_ingress_border;
    bit<1> is_egress_border;
}

/* TODO 1.3: Add the newly-defined "mpls_t" header to the struct "headers". The "mpls_t" header should go in between of "ethernet_t" and "ipv4_t". */

struct headers {
    ethernet_t              ethernet;
    ipv4_t                  ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {

            /* TODO 1.5: Call the MPLS parser in case an MPLS packet is detected. */
            
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    /* TODO 1.4: Create a parser that extracts the MPLS header that you have created. */

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

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
        
    action drop() {
        mark_to_drop(standard_metadata);
    }
            
    /* TODO 2.3: Create the action set_is_ingress_border. */

    /* TODO 2.2: Create the table check_is_ingress_border. */

    action add_mpls_header(bit<20> tag) {

        // We add the mpls header
        hdr.mpls.setValid();
        hdr.mpls.label = tag;
        hdr.ethernet.etherType = TYPE_MPLS;
    }

    /* TODO 2.5: Create the table fec_to_label. */

    action mpls_forward(macAddr_t dstAddr, egressSpec_t port) {
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;

        standard_metadata.egress_spec = port;
        hdr.mpls.ttl = hdr.mpls.ttl - 1;
    }

    /* TODO 3.2: Create the table mpls_tbl. */

    /* TODO 3.5: Create the action ipv4_forward. */

    /* TODO 3.4: Create the table ipv4_lpm. */

    apply {

            // We check if it is an ingress border port
            check_is_ingress_border.apply();

            if(meta.is_ingress_border == 1){

                // We need to check if the header is valid since mpls label is based on dst ip
                if(hdr.ipv4.isValid()){
                    
                    // We add the label based on the destination
                    fec_to_label.apply();
                }
            }
            
            /* TODO 3.1: Uncomment the following lines. */

            // We select the egress port based on the mpls label
            //if(hdr.mpls.isValid()){
            //    mpls_tbl.apply();
            //}

            /* TODO 3.4 Uncomment the following lines. */

            // Normal forwarding
            //else if (hdr.ipv4.isValid())
            //{
            //   ipv4_lpm.apply();
            //}

    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    
    action is_egress_border(){
        
        // We remove the mpls header
        hdr.mpls.setInvalid();
        hdr.ethernet.etherType = TYPE_IPV4;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    /* TODO 4.1: Create the table check_is_egress_border.  */

    apply { 
        // We check if it is an egress border port
        if (hdr.mpls.isValid()){
            check_is_egress_border.apply();
        }     
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {

    /* TODO 3.6 Uncomment to update the checksum field once the ttl changes.  */

    //apply {
    //    update_checksum(
	//        hdr.ipv4.isValid(),
    //        { hdr.ipv4.version,
	//          hdr.ipv4.ihl,
    //          hdr.ipv4.diffserv,
    //          hdr.ipv4.totalLen,
    //          hdr.ipv4.identification,
    //          hdr.ipv4.flags,
    //          hdr.ipv4.fragOffset,
    //          hdr.ipv4.ttl,
    //          hdr.ipv4.protocol,
    //          hdr.ipv4.srcAddr,
    //          hdr.ipv4.dstAddr },
    //          hdr.ipv4.hdrChecksum,
    //          HashAlgorithm.csum16);
    //}
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.mpls);
        packet.emit(hdr.ipv4);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;