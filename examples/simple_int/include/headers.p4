/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

#define MAX_INT_HEADERS 9

const bit<16> TYPE_IPV4 = 0x800;
const bit<5>  IPV4_OPTION_INT = 31;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

typedef bit<13> switch_id_t;
typedef bit<13> queue_depth_t;
typedef bit<6>  output_port_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    dscp;
    bit<2>    ecn;
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

header ipv4_option_t {
    bit<1> copyFlag;
    bit<2> optClass;
    bit<5> option;
    bit<8> optionLength;
}

header int_count_t {
    bit<16>   num_switches;
}

header int_header_t {
    switch_id_t switch_id;
    queue_depth_t queue_depth;
    output_port_t output_port;
}


struct parser_metadata_t {
    bit<16> num_headers_remaining;
}

struct metadata {
    parser_metadata_t  parser_metadata;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    ipv4_option_t ipv4_option;
    int_count_t   int_count;
    int_header_t[MAX_INT_HEADERS] int_headers;
}

error { IPHeaderWithoutOptions }
