/////////////////////////////////////////////////////////////////////////
// $Id: eth_vnet.cc,v 1.22 2008/01/26 22:24:01 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
// virtual Ethernet locator
//
// An implementation of ARP, ping(ICMP-echo), DHCP and read/write TFTP.
// Virtual host acts as a DHCP server for guest.
// There are no connections between the virtual host and real ethernets.
//
// Virtual host name: vnet
// Virtual host IP: 192.168.10.1
// Guest IP: 192.168.10.2
// Guest netmask: 255.255.255.0
// Guest broadcast: 192.168.10.255
// TFTP server uses ethdev value for the root directory and doesn't overwrite files

#define BX_PLUGGABLE

#define NO_DEVICE_INCLUDES
#include "iodev.h"

#if BX_NETWORKING

#include "eth.h"

#define LOG_THIS bx_devices.pluginNE2kDevice->

#define BX_ETH_VNET_LOGGING 1
#define BX_ETH_VNET_PCAP_LOGGING 0

#if BX_ETH_VNET_PCAP_LOGGING
#include <pcap.h>
#endif

/////////////////////////////////////////////////////////////////////////
// handler to send/receive packets
/////////////////////////////////////////////////////////////////////////

static const Bit8u default_host_ipv4addr[4] = {192,168,10,1};
static const Bit8u subnetmask_ipv4addr[4] = {0xff,0xff,0xff,0x00};
static const Bit8u default_guest_ipv4addr[4] = {192,168,10,2};
static const Bit8u broadcast_ipv4addr[3][4] =
{
  {  0,  0,  0,  0},
  {255,255,255,255},
  {192,168, 10,255},
};

#define ICMP_ECHO_PACKET_MAX  128
#define LAYER4_LISTEN_MAX  128
#define DEFAULT_LEASE_TIME 28800

static Bit8u    packet_buffer[BX_PACKET_BUFSIZE];
static unsigned packet_len;

typedef void (*layer4_handler_t)(
  void *this_ptr,
  const Bit8u *ipheader,
  unsigned ipheader_len,
  unsigned sourceport,
  unsigned targetport,
  const Bit8u *data,
  unsigned data_len
  );

#define INET_PORT_FTPDATA 20
#define INET_PORT_FTP 21
#define INET_PORT_TIME 37
#define INET_PORT_NAME 42
#define INET_PORT_DOMAIN 53
#define INET_PORT_BOOTP_SERVER 67
#define INET_PORT_BOOTP_CLIENT 68
#define INET_PORT_HTTP 80
#define INET_PORT_NTP 123

// TFTP server support by EaseWay <easeway@123.com>

#define INET_PORT_TFTP_SERVER 69

#define TFTP_RRQ    1
#define TFTP_WRQ    2
#define TFTP_DATA   3
#define TFTP_ACK    4
#define TFTP_ERROR  5
#define TFTP_OPTACK 6

#define TFTP_BUFFER_SIZE 512

#define BOOTREQUEST 1
#define BOOTREPLY 2

#define BOOTPOPT_PADDING 0
#define BOOTPOPT_END 255
#define BOOTPOPT_SUBNETMASK 1
#define BOOTPOPT_TIMEOFFSET 2
#define BOOTPOPT_ROUTER_OPTION 3
#define BOOTPOPT_DOMAIN_NAMESERVER 6
#define BOOTPOPT_HOST_NAME 12
#define BOOTPOPT_DOMAIN_NAME 15
#define BOOTPOPT_MAX_DATAGRAM_SIZE 22
#define BOOTPOPT_DEFAULT_IP_TTL 23
#define BOOTPOPT_BROADCAST_ADDRESS 28
#define BOOTPOPT_ARPCACHE_TIMEOUT 35
#define BOOTPOPT_DEFAULT_TCP_TTL 37
#define BOOTPOPT_NTP_SERVER 42
#define BOOTPOPT_NETBIOS_NAMESERVER 44
#define BOOTPOPT_X_FONTSERVER 48
#define BOOTPOPT_REQUESTED_IP_ADDRESS 50
#define BOOTPOPT_IP_ADDRESS_LEASE_TIME 51
#define BOOTPOPT_OPTION_OVRLOAD 52
#define BOOTPOPT_DHCP_MESSAGETYPE 53
#define BOOTPOPT_SERVER_IDENTIFIER 54
#define BOOTPOPT_PARAMETER_REQUEST_LIST 55
#define BOOTPOPT_MAX_DHCP_MESSAGE_SIZE 57
#define BOOTPOPT_RENEWAL_TIME 58
#define BOOTPOPT_REBINDING_TIME 59
#define BOOTPOPT_CLASS_IDENTIFIER 60
#define BOOTPOPT_CLIENT_IDENTIFIER 61

#define DHCPDISCOVER 1
#define DHCPOFFER    2
#define DHCPREQUEST  3
#define DHCPDECLINE  4
#define DHCPACK      5
#define DHCPNAK      6
#define DHCPRELEASE  7
#define DHCPINFORM   8

class bx_vnet_pktmover_c : public eth_pktmover_c {
public:
  bx_vnet_pktmover_c();
  void pktmover_init(
    const char *netif, const char *macaddr,
    eth_rx_handler_t rxh, void *rxarg, char *script);
  void sendpkt(void *buf, unsigned io_len);
private:
  void guest_to_host(const Bit8u *buf, unsigned io_len);
  void host_to_guest(Bit8u *buf, unsigned io_len);
  void process_arp(const Bit8u *buf, unsigned io_len);
  void host_to_guest_arp(Bit8u *buf, unsigned io_len);
  void process_ipv4(const Bit8u *buf, unsigned io_len);
  void host_to_guest_ipv4(Bit8u *buf, unsigned io_len);

  layer4_handler_t get_layer4_handler(
    unsigned ipprotocol, unsigned port);
  bx_bool register_layer4_handler(
    unsigned ipprotocol, unsigned port,layer4_handler_t func);
  bx_bool unregister_layer4_handler(
    unsigned ipprotocol, unsigned port);

  void process_icmpipv4(
    const Bit8u *ipheader, unsigned ipheader_len,
    const Bit8u *l4pkt, unsigned l4pkt_len);
  void process_tcpipv4(
    const Bit8u *ipheader, unsigned ipheader_len,
    const Bit8u *l4pkt, unsigned l4pkt_len);
  void process_udpipv4(
    const Bit8u *ipheader, unsigned ipheader_len,
    const Bit8u *l4pkt, unsigned l4pkt_len);
  void host_to_guest_udpipv4_packet(
    unsigned target_port, unsigned source_port,
    const Bit8u *udpdata, unsigned udpdata_len);

  void process_icmpipv4_echo(
    const Bit8u *ipheader, unsigned ipheader_len,
    const Bit8u *l4pkt, unsigned l4pkt_len);

  static void udpipv4_dhcp_handler(
    void *this_ptr,
    const Bit8u *ipheader, unsigned ipheader_len,
    unsigned sourceport, unsigned targetport,
    const Bit8u *data, unsigned data_len);
  void udpipv4_dhcp_handler_ns(
    const Bit8u *ipheader, unsigned ipheader_len,
    unsigned sourceport, unsigned targetport,
    const Bit8u *data, unsigned data_len);
  static void udpipv4_tftp_handler(
    void *this_ptr,
    const Bit8u *ipheader, unsigned ipheader_len,
    unsigned sourceport, unsigned targetport,
    const Bit8u *data, unsigned data_len);
  void udpipv4_tftp_handler_ns(
    const Bit8u *ipheader, unsigned ipheader_len,
    unsigned sourceport, unsigned targetport,
    const Bit8u *data, unsigned data_len);
  void tftp_send_error(
    Bit8u *buffer,
    unsigned sourceport, unsigned targetport,
    unsigned code, const char *msg);
  void tftp_send_data(
    Bit8u *buffer,
    unsigned sourceport, unsigned targetport,
    unsigned block_nr);
  void tftp_send_ack(
    Bit8u *buffer,
    unsigned sourceport, unsigned targetport,
    unsigned block_nr);
  void tftp_send_optack(
    Bit8u *buffer,
    unsigned sourceport, unsigned targetport,
    size_t tsize_option, unsigned blksize_option);

  char tftp_filename[BX_PATHNAME_LEN];
  char tftp_rootdir[BX_PATHNAME_LEN];
  bx_bool tftp_write;
  Bit16u tftp_tid;

  Bit8u host_macaddr[6];
  Bit8u guest_macaddr[6];
  Bit8u host_ipv4addr[4];
  Bit8u guest_ipv4addr[4];

  struct {
    unsigned ipprotocol;
    unsigned port;
    layer4_handler_t func;
  } l4data[LAYER4_LISTEN_MAX];
  unsigned l4data_used;

  static void rx_timer_handler(void *);
  void rx_timer(void);
  int rx_timer_index;
  unsigned tx_time;

#if BX_ETH_VNET_LOGGING
  FILE *pktlog_txt;
#endif // BX_ETH_VNET_LOGGING
#if BX_ETH_VNET_PCAP_LOGGING
  pcap_t *pcapp;
  pcap_dumper_t *pktlog_pcap;
  struct pcap_pkthdr pcaphdr;
#endif // BX_ETH_VNET_PCAP_LOGGING
};

class bx_vnet_locator_c : public eth_locator_c {
public:
  bx_vnet_locator_c(void) : eth_locator_c("vnet") {}
protected:
  eth_pktmover_c *allocate(
      const char *netif, const char *macaddr,
      eth_rx_handler_t rxh,
      void *rxarg, char *script) {
    bx_vnet_pktmover_c *pktmover;
    pktmover = new bx_vnet_pktmover_c();
    pktmover->pktmover_init(netif, macaddr, rxh, rxarg, script);
    return pktmover;
  }
} bx_vnet_match;

static void put_net2(Bit8u *buf,Bit16u data)
{
  *buf = (Bit8u)(data >> 8);
  *(buf+1) = (Bit8u)(data & 0xff);
}

static void put_net4(Bit8u *buf,Bit32u data)
{
  *buf = (Bit8u)((data >> 24) & 0xff);
  *(buf+1) = (Bit8u)((data >> 16) & 0xff);
  *(buf+2) = (Bit8u)((data >> 8) & 0xff);
  *(buf+3) = (Bit8u)(data & 0xff);
}

static Bit16u get_net2(const Bit8u *buf)
{
  return (((Bit16u)*buf) << 8) |
         ((Bit16u)*(buf+1));
}

static Bit32u get_net4(const Bit8u *buf)
{
  return (((Bit32u)*buf) << 24) |
         (((Bit32u)*(buf+1)) << 16) |
         (((Bit32u)*(buf+2)) << 8) |
         ((Bit32u)*(buf+3));
}

static Bit16u ip_checksum(const Bit8u *buf, unsigned buf_len)
{
  Bit32u sum = 0;
  unsigned n;

  for (n = 0; n < buf_len; n++) {
    if (n & 1) {
      sum += (Bit32u)(*buf++);
    } else {
      sum += (Bit32u)(*buf++) << 8;
    }
  }
  while (sum > 0xffff) {
    sum = (sum >> 16) + (sum & 0xffff);
  }

  return (Bit16u)sum;
}


// duplicate the part of tftp_send_data() that constructs the filename
// but ignore errors since tftp_send_data() will respond for us
static size_t get_file_size(const char *tpath, const char *tname)
{
  struct stat stbuf;
  char path[BX_PATHNAME_LEN];

  if (strlen(tname) == 0)
    return 0;

  if ((strlen(tpath) + strlen(tname)) > BX_PATHNAME_LEN)
    return 0;

  sprintf(path, "%s/%s", tpath, tname);
  if (stat(path, &stbuf) < 0)
    return 0;

  BX_INFO(("tftp filesize: %lu", (unsigned long)stbuf.st_size));
  return stbuf.st_size;
}


bx_vnet_pktmover_c::bx_vnet_pktmover_c()
{
}

void bx_vnet_pktmover_c::pktmover_init(
  const char *netif, const char *macaddr,
  eth_rx_handler_t rxh, void *rxarg, char *script)
{
  BX_INFO(("ne2k vnet driver"));
  this->rxh   = rxh;
  this->rxarg = rxarg;
  strcpy(this->tftp_rootdir, netif);
  this->tftp_tid = 0;
  this->tftp_write = 0;

  memcpy(&host_macaddr[0], macaddr, 6);
  memcpy(&guest_macaddr[0], macaddr, 6);
  host_macaddr[5] = (host_macaddr[5] & (~0x01)) ^ 0x02;

  memcpy(&host_ipv4addr[0], &default_host_ipv4addr[0], 4);
  memcpy(&guest_ipv4addr[0], &broadcast_ipv4addr[0][0], 4);

  l4data_used = 0;

  register_layer4_handler(0x11,INET_PORT_BOOTP_SERVER,udpipv4_dhcp_handler);
  register_layer4_handler(0x11,INET_PORT_TFTP_SERVER,udpipv4_tftp_handler);

  this->rx_timer_index =
    bx_pc_system.register_timer(this, this->rx_timer_handler, 1000,
                              	 0, 0, "eth_vnet");

#if BX_ETH_VNET_LOGGING
  pktlog_txt = fopen ("ne2k-pktlog.txt", "wb");
  if (!pktlog_txt) BX_PANIC (("ne2k-pktlog.txt failed"));
  fprintf (pktlog_txt, "vnet packetmover readable log file\n");
  fprintf (pktlog_txt, "TFTP root = %s\n", netif);
  fprintf (pktlog_txt, "host MAC address = ");
  int i;
  for (i=0; i<6; i++)
    fprintf (pktlog_txt, "%02x%s", 0xff & host_macaddr[i], i<5?":" : "\n");
  fprintf (pktlog_txt, "guest MAC address = ");
  for (i=0; i<6; i++)
    fprintf (pktlog_txt, "%02x%s", 0xff & guest_macaddr[i], i<5?":" : "\n");
  fprintf (pktlog_txt, "--\n");
  fflush (pktlog_txt);
#endif
#if BX_ETH_VNET_PCAP_LOGGING
  pcapp = pcap_open_dead (DLT_EN10MB, BX_PACKET_BUFSIZE);
  pktlog_pcap = pcap_dump_open (pcapp, "ne2k-pktlog.pcap");
  if (pktlog_pcap == NULL) BX_PANIC (("ne2k-pktlog.pcap failed"));
#endif
}

void bx_vnet_pktmover_c::sendpkt(void *buf, unsigned io_len)
{
  guest_to_host((const Bit8u *)buf,io_len);
}

void bx_vnet_pktmover_c::guest_to_host(const Bit8u *buf, unsigned io_len)
{
#if BX_ETH_VNET_LOGGING
  fprintf (pktlog_txt, "a packet from guest to host, length %u\n", io_len);
  Bit8u *charbuf = (Bit8u *)buf;
  unsigned n;
  for (n=0; n<io_len; n++) {
    if (((n % 16) == 0) && n>0)
      fprintf (pktlog_txt, "\n");
    fprintf (pktlog_txt, "%02x ", (unsigned)charbuf[n]);
  }
  fprintf (pktlog_txt, "\n--\n");
  fflush (pktlog_txt);
#endif
#if BX_ETH_VNET_PCAP_LOGGING
  if (pktlog_pcap && !ferror((FILE *)pktlog_pcap)) {
    Bit64u time = bx_pc_system.time_usec();
    pcaphdr.ts.tv_usec = time % 1000000;
    pcaphdr.ts.tv_sec = time / 1000000;
    pcaphdr.caplen = io_len;
    pcaphdr.len = io_len;
    pcap_dump((u_char *)pktlog_pcap, &pcaphdr, buf);
    fflush((FILE *)pktlog_pcap);
  }
#endif

  this->tx_time = (64 + 96 + 4 * 8 + io_len * 8) / 10;
  if ((io_len >= 14) &&
      (!memcmp(&buf[6],&this->guest_macaddr[0],6)) &&
      (!memcmp(&buf[0],&this->host_macaddr[0],6) ||
       !memcmp(&buf[0],&broadcast_macaddr[0],6))) {
    switch (get_net2(&buf[12])) {
    case 0x0800: // IPv4.
      process_ipv4(buf, io_len);
      break;
    case 0x0806: // ARP.
      process_arp(buf, io_len);
      break;
    default: // unknown packet type.
      break;
    }
  }
}

// The receive poll process
void bx_vnet_pktmover_c::rx_timer_handler(void *this_ptr)
{
  bx_vnet_pktmover_c *class_ptr = (bx_vnet_pktmover_c *) this_ptr;

  class_ptr->rx_timer();
}

void bx_vnet_pktmover_c::rx_timer(void)
{
  this->rxh(this->rxarg, (void *)packet_buffer, packet_len);
#if BX_ETH_VNET_LOGGING
  fprintf (pktlog_txt, "a packet from host to guest, length %u\n", packet_len);
  Bit8u *charbuf = (Bit8u *)packet_buffer;
  unsigned n;
  for (n=0; n<packet_len; n++) {
    if (((n % 16) == 0) && n>0)
      fprintf (pktlog_txt, "\n");
    fprintf (pktlog_txt, "%02x ", (unsigned)charbuf[n]);
  }
  fprintf (pktlog_txt, "\n--\n");
  fflush (pktlog_txt);
#endif
#if BX_ETH_VNET_PCAP_LOGGING
  if (pktlog_pcap && !ferror((FILE *)pktlog_pcap)) {
    Bit64u time = bx_pc_system.time_usec();
    pcaphdr.ts.tv_usec = time % 1000000;
    pcaphdr.ts.tv_sec = time / 1000000;
    pcaphdr.caplen = packet_len;
    pcaphdr.len = packet_len;
    pcap_dump((u_char *)pktlog_pcap, &pcaphdr, packet_buffer);
    fflush((FILE *)pktlog_pcap);
  }
#endif
}

void bx_vnet_pktmover_c::host_to_guest(Bit8u *buf, unsigned io_len)
{
  Bit8u localbuf[60];

  if (io_len < 14) {
    BX_PANIC(("host_to_guest: io_len < 14!"));
    return;
  }

  if (io_len < 60) {
    memcpy(&localbuf[0],&buf[0],io_len);
    memset(&localbuf[io_len],0,60-io_len);
    buf=localbuf;
    io_len=60;
  }

  packet_len = io_len;
  memcpy(&packet_buffer, &buf[0], io_len);
  unsigned rx_time = (64 + 96 + 4 * 8 + io_len * 8) / 10;
  bx_pc_system.activate_timer(this->rx_timer_index, this->tx_time + rx_time + 100, 0);
}

/////////////////////////////////////////////////////////////////////////
// ARP
/////////////////////////////////////////////////////////////////////////

void bx_vnet_pktmover_c::process_arp(const Bit8u *buf, unsigned io_len)
{
  unsigned opcode;
  unsigned protocol;
  Bit8u replybuf[60];

  if (io_len < 22) return;
  if (io_len < (unsigned)(22+buf[18]*2+buf[19]*2)) return;
  // hardware:Ethernet
  if (buf[14] != 0x00 || buf[15] != 0x01 || buf[18] != 0x06) return;
  opcode = get_net2(&buf[20]);
  protocol = get_net2(&buf[16]);
  memset(&replybuf[0],0,60);

  // protocol
  switch (protocol) {
  case 0x0800: // IPv4
    if (buf[19] == 0x04) {
      switch (opcode) {
      case 0x0001: // ARP REQUEST
        if (!memcmp(&buf[22],&this->guest_macaddr[0],6)) {
          memcpy(&this->guest_ipv4addr[0],&buf[28],4);
          if (!memcmp(&buf[38],&this->host_ipv4addr[0],4)) {
            memcpy(&replybuf[14],&buf[14],6);
            replybuf[20]=0x00;
            replybuf[21]=0x02;
            memcpy(&replybuf[22],&this->host_macaddr[0],6);
            memcpy(&replybuf[28],&this->host_ipv4addr[0],4);
            memcpy(&replybuf[32],&this->guest_macaddr[0],6);
            memcpy(&replybuf[38],&this->guest_ipv4addr[0],4);

            host_to_guest_arp(replybuf,60);
          }
        }
        break;
      case 0x0002: // ARP REPLY
        BX_INFO(("unexpected ARP REPLY"));
        break;
      case 0x0003: // RARP REQUEST
        BX_ERROR(("RARP is not implemented"));
        break;
      case 0x0004: // RARP REPLY
        BX_INFO(("unexpected RARP REPLY"));
        break;
      default:
        BX_INFO(("arp: unknown ARP opcode %04x",opcode));
        break;
      }
    }
    else
    {
      BX_INFO(("arp: unknown address length %u",(unsigned)buf[19]));
    }
    break;
  default:
    BX_INFO(("arp: unknown protocol 0x%04x",protocol));
    break;
  }
}

void bx_vnet_pktmover_c::host_to_guest_arp(Bit8u *buf, unsigned io_len)
{
  memcpy(&buf[0],&this->guest_macaddr[0],6);
  memcpy(&buf[6],&this->host_macaddr[0],6);
  buf[12]=0x08;
  buf[13]=0x06;
  host_to_guest(buf,io_len);
}

/////////////////////////////////////////////////////////////////////////
// IPv4
/////////////////////////////////////////////////////////////////////////

void bx_vnet_pktmover_c::process_ipv4(const Bit8u *buf, unsigned io_len)
{
  unsigned total_len;
  unsigned packet_id;
  unsigned fragment_flags;
  unsigned fragment_offset;
  unsigned ipproto;
  unsigned l3header_len;
  const Bit8u *l4pkt;
  unsigned l4pkt_len;

  if (io_len < (14U+20U)) {
    BX_INFO(("ip packet - too small packet"));
    return;
  }
  if ((buf[14+0] & 0xf0) != 0x40) {
    BX_INFO(("ipv%u packet - not implemented",((unsigned)buf[14+0] >> 4)));
    return;
  }
  l3header_len = ((unsigned)(buf[14+0] & 0x0f) << 2);
  if (l3header_len != 20) {
    BX_ERROR(("ip: option header is not implemented"));
    return;
  }
  if (io_len < (14U+l3header_len)) return;
  if (ip_checksum(&buf[14],l3header_len) != (Bit16u)0xffff) {
    BX_INFO(("ip: invalid checksum"));
    return;
  }

  total_len = get_net2(&buf[14+2]);
  // FIXED By EaseWay
  // Ignore this check to tolerant some cases
  //if (io_len > (14U+total_len)) return;

  if (memcmp(&buf[14+16],host_ipv4addr,4) &&
      memcmp(&buf[14+16],broadcast_ipv4addr[0],4) &&
      memcmp(&buf[14+16],broadcast_ipv4addr[1],4) &&
      memcmp(&buf[14+16],broadcast_ipv4addr[2],4))
  {
    BX_INFO(("target IP address %u.%u.%u.%u is unknown",
      (unsigned)buf[14+16],(unsigned)buf[14+17],
      (unsigned)buf[14+18],(unsigned)buf[14+19]));
    return;
  }

  packet_id = get_net2(&buf[14+4]);
  fragment_flags = (unsigned)buf[14+6] >> 5;
  fragment_offset = ((unsigned)get_net2(&buf[14+6]) & 0x1fff) << 3;
  ipproto = buf[14+9];

  if ((fragment_flags & 0x1) || (fragment_offset != 0)) {
    BX_INFO(("ignore fragmented packet!"));
    return;
  } else {
    l4pkt = &buf[14 + l3header_len];
    l4pkt_len = total_len - l3header_len;
  }

  switch (ipproto) {
  case 0x01: // ICMP
    process_icmpipv4(&buf[14],l3header_len,l4pkt,l4pkt_len);
    break;
  case 0x06: // TCP
    process_tcpipv4(&buf[14],l3header_len,l4pkt,l4pkt_len);
    break;
  case 0x11: // UDP
    process_udpipv4(&buf[14],l3header_len,l4pkt,l4pkt_len);
    break;
  default:
    BX_INFO(("unknown IP protocol %02x",ipproto));
    break;
  }
}

void bx_vnet_pktmover_c::host_to_guest_ipv4(Bit8u *buf, unsigned io_len)
{
  unsigned l3header_len;

  memcpy(&buf[0],&this->guest_macaddr[0],6);
  memcpy(&buf[6],&this->host_macaddr[0],6);
  buf[12]=0x08;
  buf[13]=0x00;
  buf[14+0] = (buf[14+0] & 0x0f) | 0x40;
  l3header_len = ((unsigned)(buf[14+0] & 0x0f) << 2);
  memcpy(&buf[14+12],&this->host_ipv4addr[0],4);
  memcpy(&buf[14+16],&this->guest_ipv4addr[0],4);
  put_net2(&buf[14+10], 0);
  put_net2(&buf[14+10], ip_checksum(&buf[14],l3header_len) ^ (Bit16u)0xffff);

  host_to_guest(buf,io_len);
}

layer4_handler_t bx_vnet_pktmover_c::get_layer4_handler(
  unsigned ipprotocol, unsigned port)
{
  unsigned n;

  for (n = 0; n < l4data_used; n++) {
    if (l4data[n].ipprotocol == ipprotocol && l4data[n].port == port)
      return l4data[n].func;
  }

  return (layer4_handler_t)NULL;
}

bx_bool bx_vnet_pktmover_c::register_layer4_handler(
  unsigned ipprotocol, unsigned port,layer4_handler_t func)
{
  if (get_layer4_handler(ipprotocol,port) != (layer4_handler_t)NULL) {
    BX_INFO(("IP protocol 0x%02x port %u is already in use",
      ipprotocol,port));
    return false;
  }

  unsigned n;

  for (n = 0; n < l4data_used; n++) {
    if (l4data[n].func == (layer4_handler_t)NULL) {
      break;
    }
  }

  if (n == l4data_used) {
    if (n >= LAYER4_LISTEN_MAX) {
      BX_ERROR(("vnet: LAYER4_LISTEN_MAX is too small"));
      return false;
    }
    l4data_used++;
  }

  l4data[n].ipprotocol = ipprotocol;
  l4data[n].port = port;
  l4data[n].func = func;

  return true;
}

bx_bool bx_vnet_pktmover_c::unregister_layer4_handler(
  unsigned ipprotocol, unsigned port)
{
  unsigned n;

  for (n = 0; n < l4data_used; n++) {
    if (l4data[n].ipprotocol == ipprotocol && l4data[n].port == port) {
      l4data[n].func = (layer4_handler_t)NULL;
      return true;
    }
  }

  BX_ERROR(("IP protocol 0x%02x port %u is not registered",
    ipprotocol,port));
  return false;
}

void bx_vnet_pktmover_c::process_icmpipv4(
  const Bit8u *ipheader, unsigned ipheader_len,
  const Bit8u *l4pkt, unsigned l4pkt_len)
{
  unsigned icmptype;
  unsigned icmpcode;

  if (l4pkt_len < 8) return;
  icmptype = l4pkt[0];
  icmpcode = l4pkt[1];
  if (ip_checksum(l4pkt,l4pkt_len) != (Bit16u)0xffff) {
    BX_INFO(("icmp: invalid checksum"));
    return;
  }

  switch (icmptype) {
  case 0x08: // ECHO
    if (icmpcode == 0) {
      process_icmpipv4_echo(ipheader,ipheader_len,l4pkt,l4pkt_len);
    }
    break;
  default:
    BX_INFO(("unhandled icmp packet: type=%u code=%u",
      icmptype, icmpcode));
    break;
  }
}

void bx_vnet_pktmover_c::process_tcpipv4(
  const Bit8u *ipheader, unsigned ipheader_len,
  const Bit8u *l4pkt, unsigned l4pkt_len)
{
  if (l4pkt_len < 20) return;

  BX_INFO(("tcp packet - not implemented"));
}

void bx_vnet_pktmover_c::process_udpipv4(
  const Bit8u *ipheader, unsigned ipheader_len,
  const Bit8u *l4pkt, unsigned l4pkt_len)
{
  unsigned udp_targetport;
  unsigned udp_sourceport;
  unsigned udp_len;
  layer4_handler_t func;

  if (l4pkt_len < 8) return;
  udp_sourceport = get_net2(&l4pkt[0]);
  udp_targetport = get_net2(&l4pkt[2]);
  udp_len = get_net2(&l4pkt[4]);

  func = get_layer4_handler(0x11,udp_targetport);
  if (func != (layer4_handler_t)NULL) {
    (*func)((void *)this,ipheader,ipheader_len,
      udp_sourceport,udp_targetport,&l4pkt[8],l4pkt_len-8);
  } else {
    BX_INFO(("udp - unhandled port %u",udp_targetport));
  }
}

void bx_vnet_pktmover_c::host_to_guest_udpipv4_packet(
  unsigned target_port, unsigned source_port,
  const Bit8u *udpdata, unsigned udpdata_len)
{
  Bit8u ipbuf[BX_PACKET_BUFSIZE];

  if ((udpdata_len + 42U) > BX_PACKET_BUFSIZE) {
    BX_PANIC(("generated udp data is too long"));
    return;
  }

  // udp pseudo-header
  ipbuf[34U-12U]=0;
  ipbuf[34U-11U]=0x11; // UDP
  put_net2(&ipbuf[34U-10U],8U+udpdata_len);
  memcpy(&ipbuf[34U-8U],host_ipv4addr,4);
  memcpy(&ipbuf[34U-4U],guest_ipv4addr,4);
  // udp header
  put_net2(&ipbuf[34U+0],source_port);
  put_net2(&ipbuf[34U+2],target_port);
  put_net2(&ipbuf[34U+4],8U+udpdata_len);
  put_net2(&ipbuf[34U+6],0);
  memcpy(&ipbuf[42U],udpdata,udpdata_len);
  put_net2(&ipbuf[34U+6], ip_checksum(&ipbuf[34U-12U],12U+8U+udpdata_len) ^ (Bit16u)0xffff);
  // ip header
  memset(&ipbuf[14U],0,20U);
  ipbuf[14U+0] = 0x45;
  ipbuf[14U+1] = 0x00;
  put_net2(&ipbuf[14U+2],20U+8U+udpdata_len);
  put_net2(&ipbuf[14U+4],1);
  ipbuf[14U+6] = 0x00;
  ipbuf[14U+7] = 0x00;
  ipbuf[14U+8] = 0x07; // TTL
  ipbuf[14U+9] = 0x11; // UDP

  host_to_guest_ipv4(ipbuf,udpdata_len + 42U);
}

/////////////////////////////////////////////////////////////////////////
// ICMP/IPv4
/////////////////////////////////////////////////////////////////////////

void bx_vnet_pktmover_c::process_icmpipv4_echo(
  const Bit8u *ipheader, unsigned ipheader_len,
  const Bit8u *l4pkt, unsigned l4pkt_len)
{
  Bit8u replybuf[ICMP_ECHO_PACKET_MAX];

  if ((14U+ipheader_len+l4pkt_len) > ICMP_ECHO_PACKET_MAX) {
    BX_ERROR(("icmp echo: size of an echo packet is too long"));
    return;
  }

  memcpy(&replybuf[14],ipheader,ipheader_len);
  memcpy(&replybuf[14+ipheader_len],l4pkt,l4pkt_len);

  replybuf[14+ipheader_len+0] = 0x00; // echo reply
  put_net2(&replybuf[14+ipheader_len+2],0);
  put_net2(&replybuf[14+ipheader_len+2],
    ip_checksum(&replybuf[14+ipheader_len],l4pkt_len) ^ (Bit16u)0xffff);

  host_to_guest_ipv4(replybuf,14U+ipheader_len+l4pkt_len);
}

/////////////////////////////////////////////////////////////////////////
// DHCP/UDP/IPv4
/////////////////////////////////////////////////////////////////////////

void bx_vnet_pktmover_c::udpipv4_dhcp_handler(
  void *this_ptr,
  const Bit8u *ipheader, unsigned ipheader_len,
  unsigned sourceport, unsigned targetport,
  const Bit8u *data, unsigned data_len)
{
  ((bx_vnet_pktmover_c *)this_ptr)->udpipv4_dhcp_handler_ns(
    ipheader,ipheader_len,sourceport,targetport,data,data_len);
}

void bx_vnet_pktmover_c::udpipv4_dhcp_handler_ns(
    const Bit8u *ipheader, unsigned ipheader_len,
    unsigned sourceport, unsigned targetport,
    const Bit8u *data, unsigned data_len)
{
  const Bit8u *opts;
  unsigned opts_len;
  unsigned extcode;
  unsigned extlen;
  const Bit8u *extdata;
  unsigned dhcpmsgtype = 0;
  bx_bool found_serverid = false;
  bx_bool found_leasetime = false;
  bx_bool found_guest_ipaddr = false;
  Bit32u leasetime = BX_MAX_BIT32U;
  const Bit8u *dhcpreqparams = NULL;
  unsigned dhcpreqparams_len = 0;
  Bit8u dhcpreqparam_default[8];
  bx_bool dhcpreqparam_default_validflag = false;
  unsigned dhcpreqparams_default_len = 0;
  Bit8u *replyopts;
  Bit8u replybuf[576];

  if (data_len < (236U+64U)) return;
  if (data[0] != BOOTREQUEST) return;
  if (data[1] != 1 || data[2] != 6) return;
  if (memcmp(&data[28U],guest_macaddr,6)) return;
  if (data[236] != 0x63 || data[237] != 0x82 ||
      data[238] != 0x53 || data[239] != 0x63) return;

  opts = &data[240];
  opts_len = data_len - 240U;

  while (1) {
    if (opts_len < 1) {
      BX_ERROR(("dhcp: invalid request"));
      return;
    }
    extcode = *opts++;
    opts_len--;

    if (extcode == BOOTPOPT_PADDING) continue;
    if (extcode == BOOTPOPT_END) break;
    if (opts_len < 1) {
      BX_ERROR(("dhcp: invalid request"));
      return;
    }
    extlen = *opts++;
    opts_len--;
    if (opts_len < extlen) {
      BX_ERROR(("dhcp: invalid request"));
      return;
    }
    extdata = opts;
    opts += extlen;
    opts_len -= extlen;

    switch (extcode)
    {
    case BOOTPOPT_DHCP_MESSAGETYPE:
      if (extlen != 1)
        break;
      dhcpmsgtype = *extdata;
      break;
    case BOOTPOPT_PARAMETER_REQUEST_LIST:
      if (extlen < 1)
        break;
      dhcpreqparams = extdata;
      dhcpreqparams_len = extlen;
      break;
    case BOOTPOPT_SERVER_IDENTIFIER:
      if (extlen != 4)
        break;
      if (memcmp(extdata,host_ipv4addr,4)) {
        BX_INFO(("dhcp: request to another server"));
        return;
      }
      found_serverid = true;
      break;
    case BOOTPOPT_IP_ADDRESS_LEASE_TIME:
      if (extlen != 4)
        break;
      leasetime = get_net4(&extdata[0]);
      found_leasetime = true;
      break;
    case BOOTPOPT_REQUESTED_IP_ADDRESS:
      if (extlen != 4)
        break;
      if (!memcmp(extdata,default_guest_ipv4addr,4)) {
        found_guest_ipaddr = true;
        memcpy(guest_ipv4addr,default_guest_ipv4addr,4);
      }
      break;
    default:
      BX_ERROR(("extcode %d not supported yet", extcode));
      break;
    }
  }

  memset(&dhcpreqparam_default,0,sizeof(dhcpreqparam_default));
  memset(&replybuf[0],0,sizeof(replybuf));
  replybuf[0] = BOOTREPLY;
  replybuf[1] = 1;
  replybuf[2] = 6;
  memcpy(&replybuf[4],&data[4],4);
  memcpy(&replybuf[16],default_guest_ipv4addr,4);
  memcpy(&replybuf[20],host_ipv4addr,4);
  memcpy(&replybuf[28],&data[28],6);
  memcpy(&replybuf[44],"vnet",4);
  memcpy(&replybuf[108],"pxelinux.0",10);
  replybuf[236] = 0x63;
  replybuf[237] = 0x82;
  replybuf[238] = 0x53;
  replybuf[239] = 0x63;
  replyopts = &replybuf[240];
  opts_len = sizeof(replybuf)/sizeof(replybuf[0])-240;
  switch (dhcpmsgtype) {
  case DHCPDISCOVER:
    BX_INFO(("dhcp server: DHCPDISCOVER"));
    *replyopts ++ = BOOTPOPT_DHCP_MESSAGETYPE;
    *replyopts ++ = 1;
    *replyopts ++ = DHCPOFFER;
    opts_len -= 3;
    dhcpreqparam_default[0] = BOOTPOPT_IP_ADDRESS_LEASE_TIME;
    dhcpreqparam_default[1] = BOOTPOPT_SERVER_IDENTIFIER;
    dhcpreqparam_default_validflag = true;
    break;
  case DHCPREQUEST:
    BX_INFO(("dhcp server: DHCPREQUEST"));
    // check ciaddr.
    if (found_serverid || found_guest_ipaddr || (!memcmp(&data[12],default_guest_ipv4addr,4))) {
      *replyopts ++ = BOOTPOPT_DHCP_MESSAGETYPE;
      *replyopts ++ = 1;
      *replyopts ++ = DHCPACK;
      opts_len -= 3;
      dhcpreqparam_default[0] = BOOTPOPT_IP_ADDRESS_LEASE_TIME;
      if (!found_serverid) {
        dhcpreqparam_default[1] = BOOTPOPT_SERVER_IDENTIFIER;
      }
      dhcpreqparam_default_validflag = true;
    } else {
      *replyopts ++ = BOOTPOPT_DHCP_MESSAGETYPE;
      *replyopts ++ = 1;
      *replyopts ++ = DHCPNAK;
      opts_len -= 3;
      if (found_leasetime) {
        dhcpreqparam_default[dhcpreqparams_default_len++] = BOOTPOPT_IP_ADDRESS_LEASE_TIME;
        dhcpreqparam_default_validflag = true;
      }
      if (!found_serverid) {
        dhcpreqparam_default[dhcpreqparams_default_len++] = BOOTPOPT_SERVER_IDENTIFIER;
        dhcpreqparam_default_validflag = true;
      }
    }
    break;
  default:
    BX_ERROR(("dhcp server: unsupported message type %u",dhcpmsgtype));
    return;
  }

  while (1) {
    while (dhcpreqparams_len-- > 0) {
      switch (*dhcpreqparams++) {
      case BOOTPOPT_SUBNETMASK:
        BX_INFO(("provide BOOTPOPT_SUBNETMASK"));
        if (opts_len < 6) {
          BX_ERROR(("option buffer is insufficient"));
          return;
        }
        opts_len -= 6;
        *replyopts ++ = BOOTPOPT_SUBNETMASK;
        *replyopts ++ = 4;
        memcpy(replyopts,subnetmask_ipv4addr,4);
        replyopts += 4;
        break;
      case BOOTPOPT_ROUTER_OPTION:
        BX_INFO(("provide BOOTPOPT_ROUTER_OPTION"));
        if (opts_len < 6) {
          BX_ERROR(("option buffer is insufficient"));
          return;
        }
        opts_len -= 6;
        *replyopts ++ = BOOTPOPT_ROUTER_OPTION;
        *replyopts ++ = 4;
        memcpy(replyopts,host_ipv4addr,4);
        replyopts += 4;
        break;
#if 0 // DNS is not implemented.
      case BOOTPOPT_DOMAIN_NAMESERVER:
        BX_INFO(("provide BOOTPOPT_DOMAIN_NAMESERVER"));
        if (opts_len < 6) {
          BX_ERROR(("option buffer is insufficient"));
          return;
        }
        opts_len -= 6;
        *replyopts ++ = BOOTPOPT_DOMAIN_NAMESERVER;
        *replyopts ++ = 4;
        memcpy(replyopts,host_ipv4addr,4);
        replyopts += 4;
        break;
#endif
      case BOOTPOPT_BROADCAST_ADDRESS:
        BX_INFO(("provide BOOTPOPT_BROADCAST_ADDRESS"));
        if (opts_len < 6) {
          BX_ERROR(("option buffer is insufficient"));
          return;
        }
        opts_len -= 6;
        *replyopts ++ = BOOTPOPT_BROADCAST_ADDRESS;
        *replyopts ++ = 4;
        memcpy(replyopts,broadcast_ipv4addr[2],4);
        replyopts += 4;
        break;
      case BOOTPOPT_IP_ADDRESS_LEASE_TIME:
        BX_INFO(("provide BOOTPOPT_IP_ADDRESS_LEASE_TIME"));
        if (opts_len < 6) {
          BX_ERROR(("option buffer is insufficient"));
          return;
        }
        opts_len -= 6;
        *replyopts ++ = BOOTPOPT_IP_ADDRESS_LEASE_TIME;
        *replyopts ++ = 4;
        if (leasetime < DEFAULT_LEASE_TIME) {
          put_net4(replyopts, leasetime);
        } else {
          put_net4(replyopts, DEFAULT_LEASE_TIME);
        }
        replyopts += 4;
        break;
      case BOOTPOPT_SERVER_IDENTIFIER:
        BX_INFO(("provide BOOTPOPT_SERVER_IDENTIFIER"));
        if (opts_len < 6) {
          BX_ERROR(("option buffer is insufficient"));
          return;
        }
        opts_len -= 6;
        *replyopts ++ = BOOTPOPT_SERVER_IDENTIFIER;
        *replyopts ++ = 4;
        memcpy(replyopts,host_ipv4addr,4);
        replyopts += 4;
        break;
      case BOOTPOPT_RENEWAL_TIME:
        BX_INFO(("provide BOOTPOPT_RENEWAL_TIME"));
        if (opts_len < 6) {
          BX_ERROR(("option buffer is insufficient"));
          return;
        }
        opts_len -= 6;
        *replyopts ++ = BOOTPOPT_RENEWAL_TIME;
        *replyopts ++ = 4;
        put_net4(replyopts, 600);
        replyopts += 4;
        break;
      case BOOTPOPT_REBINDING_TIME:
        BX_INFO(("provide BOOTPOPT_REBINDING_TIME"));
        if (opts_len < 6) {
          BX_ERROR(("option buffer is insufficient"));
          return;
        }
        opts_len -= 6;
        *replyopts ++ = BOOTPOPT_REBINDING_TIME;
        *replyopts ++ = 4;
        put_net4(replyopts, 1800);
        replyopts += 4;
        break;
      default:
        if (*(dhcpreqparams-1) != 0) {
          BX_ERROR(("dhcp server: requested parameter %u not supported yet",*(dhcpreqparams-1)));
        }
        break;
      }
    }

    if (!dhcpreqparam_default_validflag) break;
    dhcpreqparams = &dhcpreqparam_default[0];
    dhcpreqparams_len = sizeof(dhcpreqparam_default);
    dhcpreqparam_default_validflag = false;
  }

  if (opts_len < 1) {
    BX_ERROR(("option buffer is insufficient"));
    return;
  }
  opts_len -= 2;
  *replyopts ++ = BOOTPOPT_END;

  opts_len = replyopts - &replybuf[0];
  if (opts_len < (236U+64U)) {
    opts_len = (236U+64U); // BOOTP
  }
  if (opts_len < (548U)) {
    opts_len = 548U; // DHCP
  }
  host_to_guest_udpipv4_packet(
    sourceport, targetport,
    replybuf, opts_len);
}

void bx_vnet_pktmover_c::udpipv4_tftp_handler(
  void *this_ptr,
  const Bit8u *ipheader, unsigned ipheader_len,
  unsigned sourceport, unsigned targetport,
  const Bit8u *data, unsigned data_len)
{
  ((bx_vnet_pktmover_c *)this_ptr)->udpipv4_tftp_handler_ns(
    ipheader,ipheader_len,sourceport,targetport,data,data_len);
}

void bx_vnet_pktmover_c::udpipv4_tftp_handler_ns(
  const Bit8u *ipheader, unsigned ipheader_len,
  unsigned sourceport, unsigned targetport,
  const Bit8u *data, unsigned data_len)
{
  Bit8u buffer[TFTP_BUFFER_SIZE + 4];
  char path[BX_PATHNAME_LEN];
  FILE *fp;
  unsigned block_nr;
  unsigned tftp_len;

  switch (get_net2(data)) {
    case TFTP_RRQ:
      if (tftp_tid == 0) {
        strncpy((char*)buffer, (const char*)data + 2, data_len - 2);
        buffer[data_len - 4] = 0;

        // options
        size_t tsize_option = 0;
        int blksize_option = 0;
        if (strlen((char*)buffer) < data_len - 2) {
          const char *mode = (const char*)data + 2 + strlen((char*)buffer) + 1;
          int octet_option = 0;
          while (mode < (const char*)data + data_len) {
            if (memcmp(mode, "octet\0", 6) == 0) {
              mode += 6;
              octet_option = 1;
            } else if (memcmp(mode, "tsize\0", 6) == 0) {
              mode += 6;
              tsize_option = 1;             // size needed
              mode += strlen(mode)+1;
            } else if (memcmp(mode, "blksize\0", 8) == 0) {
              mode += 8;
              blksize_option = atoi(mode);
              mode += strlen(mode)+1;
            } else {
              BX_INFO(("tftp req: unknown option %s", mode));
              break;
            }
          }
          if (!octet_option) {
            tftp_send_error(buffer, sourceport, targetport, 4, "Unsupported transfer mode");
            return;
          }
        }

        strcpy(tftp_filename, (char*)buffer);
        BX_INFO(("tftp req: %s", tftp_filename));
        if (tsize_option) {
          tsize_option = get_file_size(tftp_rootdir, tftp_filename);
          if (tsize_option > 0) {
            // if tsize requested and file exists, send optack and return
            // optack ack will pick up where we leave off here.
            // if blksize_option is less than TFTP_BUFFER_SIZE should
            // probably use blksize_option...
            tftp_send_optack(buffer, sourceport, targetport, tsize_option, TFTP_BUFFER_SIZE);
            return;
          }
        }
        tftp_tid = sourceport;
        tftp_write = 0;
        tftp_send_data(buffer, sourceport, targetport, 1);
      } else {
        tftp_send_error(buffer, sourceport, targetport, 4, "Illegal request");
      }
      break;
    case TFTP_WRQ:
      if (tftp_tid == 0) {
        strncpy((char*)buffer, (const char*)data + 2, data_len - 2);
        buffer[data_len - 4] = 0;

        // transfer mode
        if (strlen((char*)buffer) < data_len - 2) {
          const char *mode = (const char*)data + 2 + strlen((char*)buffer) + 1;
          if (memcmp(mode, "octet\0", 6) != 0) {
            tftp_send_error(buffer, sourceport, targetport, 4, "Unsupported transfer mode");
            return;
          }
        }

        strcpy(tftp_filename, (char*)buffer);
        sprintf(path, "%s/%s", tftp_rootdir, tftp_filename);
        fp = fopen(path, "rb");
        if (fp) {
          tftp_send_error(buffer, sourceport, targetport, 6, "File exists");
          fclose(fp);
          return;
        }
        fp = fopen(path, "wb");
        if (!fp) {
          tftp_send_error(buffer, sourceport, targetport, 2, "Access violation");
          return;
        }
        fclose(fp);
        tftp_tid = sourceport;
        tftp_write = 1;

        tftp_send_ack(buffer, sourceport, targetport, 0);
      } else {
        tftp_send_error(buffer, sourceport, targetport, 4, "Illegal request");
      }
      break;
    case TFTP_DATA:
      if ((tftp_tid == sourceport) && (tftp_write == 1)) {
        block_nr = get_net2(data + 2);
        strncpy((char*)buffer, (const char*)data + 4, data_len - 4);
        tftp_len = data_len - 4;
        buffer[tftp_len] = 0;
        if (tftp_len <= 512) {
          sprintf(path, "%s/%s", tftp_rootdir, tftp_filename);
          fp = fopen(path, "ab");
          if (!fp) {
            tftp_send_error(buffer, sourceport, targetport, 2, "Access violation");
            return;
          }
          if (fseek(fp, (block_nr - 1) * TFTP_BUFFER_SIZE, SEEK_SET) < 0) {
            tftp_send_error(buffer, sourceport, targetport, 3, "Block not seekable");
            return;
          }
          fwrite(buffer, 1, tftp_len, fp);
          fclose(fp);
          tftp_send_ack(buffer, sourceport, targetport, block_nr);
          if (tftp_len < 512) {
            tftp_tid = 0;
          }
        } else {
          tftp_send_error(buffer, sourceport, targetport, 4, "Illegal request");
        }
      } else {
        tftp_send_error(buffer, sourceport, targetport, 4, "Illegal request");
      }
      break;
    case TFTP_ACK:
      tftp_send_data(buffer, sourceport, targetport, get_net2(data + 2) + 1);
      break;
    case TFTP_ERROR:
      // silently ignore error packets
      break;
    default:
      BX_ERROR(("TFTP unknown opt %d", get_net2(data)));
  }
}

void bx_vnet_pktmover_c::tftp_send_error(
  Bit8u *buffer,
  unsigned sourceport, unsigned targetport,
  unsigned code, const char *msg)
{
  put_net2(buffer, TFTP_ERROR);
  put_net2(buffer + 2, code);
  strcpy((char*)buffer + 4, msg);
  host_to_guest_udpipv4_packet(sourceport, targetport, buffer, strlen(msg) + 5);
  tftp_tid = 0;
}

void bx_vnet_pktmover_c::tftp_send_data(
  Bit8u *buffer,
  unsigned sourceport, unsigned targetport,
  unsigned block_nr)
{
  char path[BX_PATHNAME_LEN];
  char msg[BX_PATHNAME_LEN];
  int rd;

  if (strlen(tftp_filename) == 0) {
    tftp_send_error(buffer, sourceport, targetport, 1, "File not found");
    return;
  }

  if ((strlen(tftp_rootdir) + strlen(tftp_filename)) > BX_PATHNAME_LEN) {
    tftp_send_error(buffer, sourceport, targetport, 1, "Path name too long");
    return;
  }

  sprintf(path, "%s/%s", tftp_rootdir, tftp_filename);
  FILE *fp = fopen(path, "rb");
  if (!fp) {
    sprintf(msg, "File not found: %s", tftp_filename);
    tftp_send_error(buffer, sourceport, targetport, 1, msg);
    return;
  }

  if (fseek(fp, (block_nr - 1) * TFTP_BUFFER_SIZE, SEEK_SET) < 0) {
    tftp_send_error(buffer, sourceport, targetport, 3, "Block not seekable");
    return;
  }

  rd = fread(buffer + 4, 1, TFTP_BUFFER_SIZE, fp);
  fclose(fp);

  if (rd < 0) {
    tftp_send_error(buffer, sourceport, targetport, 3, "Block not readable");
    return;
  }

  put_net2(buffer, TFTP_DATA);
  put_net2(buffer + 2, block_nr);
  host_to_guest_udpipv4_packet(sourceport, targetport, buffer, rd + 4);
  if (rd < TFTP_BUFFER_SIZE) {
    tftp_tid = 0;
  }
}

void bx_vnet_pktmover_c::tftp_send_ack(
  Bit8u *buffer,
  unsigned sourceport, unsigned targetport,
  unsigned block_nr)
{
  put_net2(buffer, TFTP_ACK);
  put_net2(buffer + 2, block_nr);
  host_to_guest_udpipv4_packet(sourceport, targetport, buffer, 4);
}

void bx_vnet_pktmover_c::tftp_send_optack(
  Bit8u *buffer,
  unsigned sourceport, unsigned targetport,
  size_t tsize_option, unsigned blksize_option)
{
  Bit8u *p = buffer;
  put_net2(p, TFTP_OPTACK);
  p += 2;
  if (tsize_option > 0) {
    *p++='t'; *p++='s'; *p++='i'; *p++='z'; *p++='e'; *p++='\0';
    sprintf((char *)p, "%lu", (unsigned long)tsize_option);
    p += strlen((const char *)p) + 1;
  }
  if (blksize_option > 0) {
    *p++='b'; *p++='l'; *p++='k'; *p++='s'; *p++='i'; *p++='z'; *p++='e'; *p++='\0';
    sprintf((char *)p, "%d", blksize_option); p += strlen((const char *)p) + 1;
  }
  host_to_guest_udpipv4_packet(sourceport, targetport, buffer, p - buffer);
}

#endif /* if BX_NETWORKING */
