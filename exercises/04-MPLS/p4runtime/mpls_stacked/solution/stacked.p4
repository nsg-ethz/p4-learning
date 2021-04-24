/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x0800;
const bit<16> TYPE_MPLS = 0x8847;

#define CONST_MAX_LABELS 	128
#define CONST_MAX_MPLS_HOPS 8

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<20> label_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header mpls_t {
    bit<20>   label;
    bit<3>    exp;
    bit<1>    s;
    bit<8>    ttl;
}

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

struct metadata {

}

struct headers {
    ethernet_t                      ethernet;
    mpls_t[CONST_MAX_MPLS_HOPS]     mpls;
    ipv4_t                          ipv4;
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
            TYPE_MPLS: parse_mpls;
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_mpls {
        packet.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.s) {
            1: parse_ipv4;
            default: parse_mpls;
        }
    }

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

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {

        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;

        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action mpls_ingress_1_hop(label_t label_1) {

        hdr.ethernet.etherType = TYPE_MPLS;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_1;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 1;
    }

    action mpls_ingress_2_hop(label_t label_1, label_t label_2) {

        hdr.ethernet.etherType = TYPE_MPLS;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_1;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 1;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_2;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;
    }

    action mpls_ingress_3_hop(label_t label_1, label_t label_2, label_t label_3) {

        hdr.ethernet.etherType = TYPE_MPLS;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_1;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 1;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_2;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_3;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;
    }

    action mpls_ingress_4_hop(label_t label_1, label_t label_2, label_t label_3, label_t label_4) {

        hdr.ethernet.etherType = TYPE_MPLS;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_1;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 1;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_2;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_3;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_4;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;
    }

    action mpls_ingress_5_hop(label_t label_1, label_t label_2, label_t label_3, label_t label_4, label_t label_5) {

        hdr.ethernet.etherType = TYPE_MPLS;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_1;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 1;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_2;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_3;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_4;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;

        hdr.mpls.push_front(1);
        hdr.mpls[0].setValid();
        hdr.mpls[0].label = label_5;
        hdr.mpls[0].ttl = hdr.ipv4.ttl - 1;
        hdr.mpls[0].s = 0;
    }

    table FEC_tbl {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            mpls_ingress_1_hop;
            mpls_ingress_2_hop;
            mpls_ingress_3_hop;
            mpls_ingress_4_hop;
            mpls_ingress_5_hop;
            NoAction;
        }
        default_action = NoAction();
        size = 256;
    }

    action mpls_forward(macAddr_t dstAddr, egressSpec_t port) {

        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;

        standard_metadata.egress_spec = port;

        hdr.mpls[1].ttl = hdr.mpls[0].ttl - 1;

        hdr.mpls.pop_front(1);
    }

    action penultimate(macAddr_t dstAddr, egressSpec_t port) {

        hdr.ethernet.etherType = TYPE_IPV4;

        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;

        hdr.ipv4.ttl = hdr.mpls[0].ttl - 1;

        standard_metadata.egress_spec = port;
        hdr.mpls.pop_front(1);
    }

    table mpls_tbl {
        key = {
            hdr.mpls[0].label: exact;
            hdr.mpls[0].s: exact;
        }
        actions = {
            mpls_forward;
            penultimate;
            NoAction;
        }
        default_action = NoAction();
        size = CONST_MAX_LABELS;
    }

    apply {
        /* Ingress Pipeline Control Logic */
        if(hdr.ipv4.isValid()){
            FEC_tbl.apply();
        }
        if(hdr.mpls[0].isValid()){
            mpls_tbl.apply();
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

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
    apply {

        // We have modified the ip ttl, so we have to compute the new checksum
        update_checksum(
                hdr.ipv4.isValid(),
                { hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
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
