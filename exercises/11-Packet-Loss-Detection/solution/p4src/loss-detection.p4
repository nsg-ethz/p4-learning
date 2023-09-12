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

    register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) um_ip_src;
    register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) um_ip_dst;
    register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) um_ports_proto_id;
    register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) um_counter;

    register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) dm_ip_src;
    register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) dm_ip_dst;
    register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) dm_ports_proto_id;
    register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) dm_counter;

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action compute_hash_indexes(){

         // Compute hash indexes for upstream meter
        hash(meta.um_h1, HashAlgorithm.crc32_custom, ((meta.batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.egress_spec-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,  hdr.ipv4.dstAddr,
         meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
        hash(meta.um_h2, HashAlgorithm.crc32_custom, ((meta.batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.egress_spec-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,  hdr.ipv4.dstAddr,
         meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
        hash(meta.um_h3, HashAlgorithm.crc32_custom, ((meta.batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.egress_spec-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,  hdr.ipv4.dstAddr,
         meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);

        // Compute hash indexes for downstream meter
        hash(meta.dm_h1, HashAlgorithm.crc32_custom, ((meta.previous_batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.ingress_port-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,  hdr.ipv4.dstAddr,
         meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
        hash(meta.dm_h2, HashAlgorithm.crc32_custom, ((meta.previous_batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.ingress_port-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,  hdr.ipv4.dstAddr,
         meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
        hash(meta.dm_h3, HashAlgorithm.crc32_custom, ((meta.previous_batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.ingress_port-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,  hdr.ipv4.dstAddr,
         meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
    }

    action apply_um_meter(){

        // ip src
        //hash1
        bit<64> tmp = (bit<64>)hdr.ipv4.srcAddr;
        um_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.um_h1);
        meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
        um_ip_src.write((bit<32>)meta.um_h1, meta.tmp_ip_src);

        //hash2
        um_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.um_h2);
        meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
        um_ip_src.write((bit<32>)meta.um_h2, meta.tmp_ip_src);

        //hash3
        um_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.um_h3);
        meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
        um_ip_src.write((bit<32>)meta.um_h3, meta.tmp_ip_src);

        // ip dst
        tmp = (bit<64>)hdr.ipv4.dstAddr;
        um_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.um_h1);
        meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
        um_ip_dst.write((bit<32>)meta.um_h1, meta.tmp_ip_dst);

        //hash2
        um_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.um_h2);
        meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
        um_ip_dst.write((bit<32>)meta.um_h2, meta.tmp_ip_dst);

        //hash3
        um_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.um_h3);
        meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
        um_ip_dst.write((bit<32>)meta.um_h3, meta.tmp_ip_dst);

        // misc fields
        //hash1
        tmp = (bit<8>)0 ++ meta.tmp_src_port ++ meta.tmp_dst_port ++ hdr.loss.nextProtocol ++ hdr.ipv4.identification;
        um_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.um_h1);
        meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
        um_ports_proto_id.write((bit<32>)meta.um_h1, meta.tmp_ports_proto_id);

        //hash2
        um_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.um_h2);
        meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
        um_ports_proto_id.write((bit<32>)meta.um_h2, meta.tmp_ports_proto_id);

        //hash3
        um_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.um_h3);
        meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
        um_ports_proto_id.write((bit<32>)meta.um_h3, meta.tmp_ports_proto_id);

        // counter
        //hash1
        um_counter.read(meta.tmp_counter, (bit<32>)meta.um_h1);
        meta.tmp_counter = meta.tmp_counter + 1;
        um_counter.write((bit<32>)meta.um_h1, meta.tmp_counter);

        //hash2
        um_counter.read(meta.tmp_counter, (bit<32>)meta.um_h2);
        meta.tmp_counter = meta.tmp_counter + 1;
        um_counter.write((bit<32>)meta.um_h2, meta.tmp_counter);

        //hash3
        um_counter.read(meta.tmp_counter, (bit<32>)meta.um_h3);
        meta.tmp_counter = meta.tmp_counter + 1;
        um_counter.write((bit<32>)meta.um_h3, meta.tmp_counter);
    }

    action apply_dm_meter(){

        // ip src
        //hash1
        bit<64> tmp = (bit<64>)hdr.ipv4.srcAddr;
        dm_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.dm_h1);
        meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
        dm_ip_src.write((bit<32>)meta.dm_h1, meta.tmp_ip_src);

        //hash2
        dm_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.dm_h2);
        meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
        dm_ip_src.write((bit<32>)meta.dm_h2, meta.tmp_ip_src);

        //hash3
        dm_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.dm_h3);
        meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
        dm_ip_src.write((bit<32>)meta.dm_h3, meta.tmp_ip_src);

        // ip dst
        tmp = (bit<64>)hdr.ipv4.dstAddr;
        dm_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.dm_h1);
        meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
        dm_ip_dst.write((bit<32>)meta.dm_h1, meta.tmp_ip_dst);

        //hash2
        dm_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.dm_h2);
        meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
        dm_ip_dst.write((bit<32>)meta.dm_h2, meta.tmp_ip_dst);

        //hash3
        dm_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.dm_h3);
        meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
        dm_ip_dst.write((bit<32>)meta.dm_h3, meta.tmp_ip_dst);

        // misc fields
        //hash1
        tmp = (bit<8>)0 ++ meta.tmp_src_port ++ meta.tmp_dst_port ++ hdr.loss.nextProtocol ++ hdr.ipv4.identification;
        dm_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.dm_h1);
        meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
        dm_ports_proto_id.write((bit<32>)meta.dm_h1, meta.tmp_ports_proto_id);

        //hash2
        dm_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.dm_h2);
        meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
        dm_ports_proto_id.write((bit<32>)meta.dm_h2, meta.tmp_ports_proto_id);

        //hash3
        dm_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.dm_h3);
        meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
        dm_ports_proto_id.write((bit<32>)meta.dm_h3, meta.tmp_ports_proto_id);

        // counter
        //hash1
        dm_counter.read(meta.tmp_counter, (bit<32>)meta.dm_h1);
        meta.tmp_counter = meta.tmp_counter + 1;
        dm_counter.write((bit<32>)meta.dm_h1, meta.tmp_counter);

        //hash2
        dm_counter.read(meta.tmp_counter, (bit<32>)meta.dm_h2);
        meta.tmp_counter = meta.tmp_counter + 1;
        dm_counter.write((bit<32>)meta.dm_h2, meta.tmp_counter);

        //hash3
        dm_counter.read(meta.tmp_counter, (bit<32>)meta.dm_h3);
        meta.tmp_counter = meta.tmp_counter + 1;
        dm_counter.write((bit<32>)meta.dm_h3, meta.tmp_counter);

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

    action remove_header (){

        bit<8> protocol = hdr.loss.nextProtocol;
        hdr.loss.setInvalid();
        hdr.ipv4.protocol = protocol;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen - 2;

        meta.dont_execute_um = 1;
    }

    table remove_loss_header {
        key = {
            standard_metadata.egress_spec: exact;
        }

        actions = {
            remove_header;
            NoAction;
        }
        size=64;
        default_action = NoAction;
    }

    apply {

        if (hdr.ipv4.isValid())
        {
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
                clone_preserving_field_list(CloneType.I2E, 100, 0);
            }

            // Update the header batch id with the current one
            hdr.loss.batch_id = (bit<1>)meta.batch_id;

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