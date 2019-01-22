/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

/* TCP/IP Headers */

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    tos;
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

/* DV ROUTING HEADERS */

header recirculate_header_t {
    bit<8> length;
}

header recirculate_data_t {
    bit<8> value;
}

/* Metadata */
struct recirculate_meta_t {
   bit<8> stack_length;
   bit<8> stack_length_tmp;
}

struct metadata {
    recirculate_meta_t recirculate_meta;
}

/* Headers Definition */

struct headers {
    ethernet_t   ethernet;
    recirculate_header_t recirculate_header;
    recirculate_data_t[STACK_LENGTH] recirculate_stack;
    recirculate_data_t recirculate_last;
    ipv4_t       ipv4;
}