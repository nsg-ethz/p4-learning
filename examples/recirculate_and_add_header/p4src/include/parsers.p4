
/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {

        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: ipv4;
            TYPE_RECIRCULATE_PKT: recirculate_start;
            default: accept;
        }

    }

    state recirculate_start {
        packet.extract(hdr.recirculate_header);
        transition select(meta.recirculate_meta.stack_length) {
            0: accept;
            default: stack_parse;
        }
    }

    state stack_parse {
        packet.extract(hdr.recirculate_stack.next);
        meta.recirculate_meta.stack_length_tmp = meta.recirculate_meta.stack_length_tmp - 1;
        transition select(meta.recirculate_meta.stack_length_tmp) {
            0: accept;
            default: stack_parse;
        }
    }

    state ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {

        packet.emit(hdr.ethernet);
        packet.emit(hdr.recirculate_header);
        packet.emit(hdr.recirculate_stack);
        packet.emit(hdr.recirculate_last);
        packet.emit(hdr.ipv4);

    }
}