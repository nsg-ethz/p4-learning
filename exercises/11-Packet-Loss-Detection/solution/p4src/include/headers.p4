/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

const bit<16> TYPE_IPV4 = 0x800;
const bit<8>  TYPE_TCP  = 6;
const bit<8>  TYPE_UDP  = 17;
const bit<8>  TYPE_LOSS = 0xFC;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;


header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header loss_t {

    bit<1> batch_id;
    bit<7> padding; // to be able to add 2 bytes to the IP header length
    bit<8> nextProtocol;
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

header tcp_t{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<1>  cwr;
    bit<1>  ece;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
}

struct metadata {

    bit<16> tmp_src_port;
    bit<16> tmp_dst_port;

    bit<16> um_h1;
    bit<16> um_h2;
    bit<16> um_h3;

    bit<16> dm_h1;
    bit<16> dm_h2;
    bit<16> dm_h3;

    bit<64> tmp_ip_src;
    bit<64> tmp_ip_dst;
    bit<64> tmp_ports_proto_id;
    bit<64> tmp_counter;

    bit<16> previous_batch_id;
    bit<16> batch_id;
    bit<16> last_local_batch_id;

    bit<1> dont_execute_um;
    bit<1> dont_execute_dm;

}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    loss_t       loss;
    tcp_t        tcp;
    udp_t        udp;
}

