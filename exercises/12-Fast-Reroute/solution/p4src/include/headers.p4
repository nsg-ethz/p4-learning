/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>
#define N_PREFS 1024
#define PORT_WIDTH 32
#define N_PORTS 512
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<20> label_t;
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
struct metadata {
    bit<2> meter_color;
    bit<1> linkState;
    bit<32> nextHop;
    bit<32> index;
}
struct headers {
    ethernet_t                      ethernet;
    ipv4_t                          ipv4;
}
