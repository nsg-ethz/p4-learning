/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>


#include "include/constants.p4"
#include "include/headers.p4"
#include "include/parsers.p4"


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

    apply {
        standard_metadata.egress_spec = 2;
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

   register<bit<8>>(128) recirculate_register;

   apply {

       if (hdr.recirculate_header.isValid()) {
            if (meta.recirculate_meta.stack_length < hdr.recirculate_header.length) {

            hdr.recirculate_last.setValid();
            recirculate_register.read(hdr.recirculate_last.value, (bit<32>)meta.recirculate_meta.stack_length);

            meta.recirculate_meta.stack_length = meta.recirculate_meta.stack_length +1;
            meta.recirculate_meta.stack_length_tmp = meta.recirculate_meta.stack_length;
            if (meta.recirculate_meta.stack_length < hdr.recirculate_header.length) {
                recirculate_preserving_field_list(0);
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
