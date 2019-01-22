/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

#define MAX_HOPS 127

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_SOURCE_ROUTING = 0x1111;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;


header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header source_routing_t {
    bit<1> last_header;
    bit<7> switch_id;
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

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    source_routing_t[MAX_HOPS] source_routes;
    ipv4_t       ipv4;
}

