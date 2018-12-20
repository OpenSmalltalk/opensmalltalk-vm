/////////////////////////////////////////////////////////////////////////
// $Id: eth_tap.cc,v 1.30 2008/02/15 22:05:42 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2001  MandrakeSoft S.A.
//
//    MandrakeSoft S.A.
//    43, rue d'Aboukir
//    75002 Paris - France
//    http://www.linux-mandrake.com/
//    http://www.mandrakesoft.com/
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

// eth_tap.cc  - TAP interface by Bryce Denney
//
// Here's how to get this working.  On the host machine:
//    $ su root
//    # /sbin/insmod ethertap
//    Using /lib/modules/2.2.14-5.0/net/ethertap.o
//    # mknod /dev/tap0 c 36 16          # if not already there
//    # /sbin/ifconfig tap0 10.0.0.1
//    # /sbin/route add -host 10.0.0.2 gw 10.0.0.1
//
// Now you have a tap0 device which you can on the ifconfig output.  The
// tap0 interface has the IP address of 10.0.0.1.  The bochs machine will have
// the IP address 10.0.0.2.
//
// Compile a bochs version from March 8, 2002 or later with --enable-ne2000.
// Add this ne2k line to your .bochsrc to activate the tap device.
//   ne2k: ioaddr=0x280, irq=9, mac=fe:fd:00:00:00:01, ethmod=tap, ethdev=tap0
// Don't change the mac or ethmod!
//
// Boot up DLX Linux in Bochs.  Log in as root and then type the following
// commands to set up networking:
//   # ifconfig eth0 10.0.0.2
//   # route add -net 10.0.0.0
//   # route add default gw 10.0.0.1
// Now you should be able to ping from guest OS to your host machine, if
// you give its IP number.  I'm still having trouble with pings from the
// host machine to the guest, so something is still not right.  Symptoms: I
// ping from the host to the guest's IP address 10.0.0.2.  With tcpdump I can
// see the ping going to Bochs, and then the ping reply coming from Bochs.
// But the ping program itself does not see the responses....well every
// once in a while it does, like 1 in 60 pings.
//
// host$ ping 10.0.0.2
// PING 10.0.0.2 (10.0.0.2) from 10.0.0.1 : 56(84) bytes of data.
//
// Netstat output:
// 20:29:59.018776 fe:fd:0:0:0:0 fe:fd:0:0:0:1 0800 98: 10.0.0.1 > 10.0.0.2: icmp: echo request
//      4500 0054 2800 0000 4001 3ea7 0a00 0001
//      0a00 0002 0800 09d3 a53e 0400 9765 893c
//      3949 0000 0809 0a0b 0c0d 0e0f 1011 1213
//      1415 1617 1819
// 20:29:59.023017 fe:fd:0:0:0:1 fe:fd:0:0:0:0 0800 98: 10.0.0.2 > 10.0.0.1: icmp: echo reply
//      4500 0054 004a 0000 4001 665d 0a00 0002
//      0a00 0001 0000 11d3 a53e 0400 9765 893c
//      3949 0000 0809 0a0b 0c0d 0e0f 1011 1213
//      1415 1617 1819
//
// I suspect it may be related to the fact that ping 10.0.0.1 from the
// host also doesn't work.  Why wouldn't the host respond to its own IP
// address on the tap0 device?
//
// Theoretically, if you set up packet forwarding (with masquerading) on the
// host, you should be able to get Bochs talking to anyone on the internet.
//

// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE
// is used to know when we are exporting symbols and when we are importing.
#define BX_PLUGGABLE

#define NO_DEVICE_INCLUDES
#include "iodev.h"

#if BX_NETWORKING && defined(HAVE_ETHERTAP)

#include "eth.h"

#define LOG_THIS bx_devices.pluginNE2kDevice->

#include <signal.h>
#include <sys/param.h>
#include <sys/ioctl.h>
#ifndef __APPLE__
#include <sys/poll.h>
#endif
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <sys/wait.h>
#if defined(__linux__)
#include <asm/types.h>
#include <linux/netlink.h>
#include <linux/if.h>
#elif BX_HAVE_NET_IF_H
#include <net/if.h>
#endif
#include <assert.h>
#include <fcntl.h>
#include <errno.h>

#define BX_ETH_TAP_LOGGING 0

//
//  Define the class. This is private to this module
//
class bx_tap_pktmover_c : public eth_pktmover_c {
public:
  bx_tap_pktmover_c(const char *netif, const char *macaddr,
		     eth_rx_handler_t rxh,
		     void *rxarg, char *script);
  void sendpkt(void *buf, unsigned io_len);
private:
  int fd;
  int rx_timer_index;
  static void rx_timer_handler(void *);
  void rx_timer ();
  Bit8u guest_macaddr[6];
#if BX_ETH_TAP_LOGGING
  FILE *txlog, *txlog_txt, *rxlog, *rxlog_txt;
#endif
};


//
//  Define the static class that registers the derived pktmover class,
// and allocates one on request.
//
class bx_tap_locator_c : public eth_locator_c {
public:
  bx_tap_locator_c(void) : eth_locator_c("tap") {}
protected:
  eth_pktmover_c *allocate(const char *netif, const char *macaddr,
			   eth_rx_handler_t rxh,
			   void *rxarg, char *script) {
    return (new bx_tap_pktmover_c(netif, macaddr, rxh, rxarg, script));
  }
} bx_tap_match;


//
// Define the methods for the bx_tap_pktmover derived class
//

// the constructor
bx_tap_pktmover_c::bx_tap_pktmover_c(const char *netif,
				       const char *macaddr,
				       eth_rx_handler_t rxh,
				       void *rxarg,
				       char *script)
{
  int flags;
  char filename[BX_PATHNAME_LEN];
  if (strncmp (netif, "tap", 3) != 0) {
    BX_PANIC (("eth_tap: interface name (%s) must be tap0..tap15", netif));
  }
  sprintf (filename, "/dev/%s", netif);

#if defined(__linux__)
  // check if the TAP devices is running, and turn on ARP.  This is based
  // on code from the Mac-On-Linux project. http://http://www.maconlinux.org/
  int sock = socket(AF_INET, SOCK_DGRAM, 0);
  if (sock < 0) {
    BX_PANIC (("socket creation: %s", strerror(errno)));
    return;
  }
  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));
  strncpy(ifr.ifr_name, netif, sizeof(ifr.ifr_name));
  if(ioctl(sock, SIOCGIFFLAGS, &ifr) < 0) {
    BX_PANIC (("SIOCGIFFLAGS on %s: %s", netif, strerror(errno)));
    close(sock);
    return;
  }
  if (!(ifr.ifr_flags & IFF_RUNNING)) {
    BX_PANIC (("%s device is not running", netif));
    close(sock);
    return;
  }
  if ((ifr.ifr_flags & IFF_NOARP)){
    BX_INFO(("turn on ARP for %s device", netif));
    ifr.ifr_flags &= ~IFF_NOARP;
    if (ioctl(sock, SIOCSIFFLAGS, &ifr) < 0) {
      BX_PANIC (("SIOCSIFFLAGS: %s", strerror(errno)));
      close(sock);
      return;
    }
  }
  close(sock);
#endif

  fd = open (filename, O_RDWR);
  if (fd < 0) {
    BX_PANIC(("open failed on %s: %s", netif, strerror(errno)));
    return;
  }

  /* set O_ASYNC flag so that we can poll with read() */
  if ((flags = fcntl(fd, F_GETFL)) < 0) {
    BX_PANIC(("getflags on tap device: %s", strerror(errno)));
  }
  flags |= O_NONBLOCK;
  if (fcntl(fd, F_SETFL, flags) < 0) {
    BX_PANIC(("set tap device flags: %s", strerror(errno)));
  }

  BX_INFO(("eth_tap: opened %s device", netif));

  /* Execute the configuration script */
  char intname[IFNAMSIZ];
  strcpy(intname,netif);
  if((script != NULL) && (strcmp(script, "") != 0) && (strcmp(script, "none") != 0))
  {
    if (execute_script(script, intname) < 0)
      BX_ERROR(("execute script '%s' on %s failed", script, intname));
  }

  // Start the rx poll
  this->rx_timer_index =
    bx_pc_system.register_timer(this, this->rx_timer_handler, 1000,
				1, 1, "eth_tap"); // continuous, active
  this->rxh   = rxh;
  this->rxarg = rxarg;
  memcpy(&guest_macaddr[0], macaddr, 6);
#if BX_ETH_TAP_LOGGING
  // eventually Bryce wants txlog to dump in pcap format so that
  // tcpdump -r FILE can read it and interpret packets.
  txlog = fopen ("ne2k-tx.log", "wb");
  if (!txlog) BX_PANIC (("open ne2k-tx.log failed"));
  txlog_txt = fopen ("ne2k-txdump.txt", "wb");
  if (!txlog_txt) BX_PANIC (("open ne2k-txdump.txt failed"));
  fprintf (txlog_txt, "tap packetmover readable log file\n");
  fprintf (txlog_txt, "net IF = %s\n", netif);
  fprintf (txlog_txt, "MAC address = ");
  for (int i=0; i<6; i++)
    fprintf (txlog_txt, "%02x%s", 0xff & macaddr[i], i<5?":" : "");
  fprintf (txlog_txt, "\n--\n");
  fflush (txlog_txt);

  rxlog = fopen ("ne2k-rx.log", "wb");
  if (!rxlog) BX_PANIC (("open ne2k-rx.log failed"));
  rxlog_txt = fopen ("ne2k-rxdump.txt", "wb");
  if (!rxlog_txt) BX_PANIC (("open ne2k-rxdump.txt failed"));
  fprintf (rxlog_txt, "tap packetmover readable log file\n");
  fprintf (rxlog_txt, "net IF = %s\n", netif);
  fprintf (rxlog_txt, "MAC address = ");
  for (int i=0; i<6; i++)
    fprintf (rxlog_txt, "%02x%s", 0xff & macaddr[i], i<5?":" : "");
  fprintf (rxlog_txt, "\n--\n");
  fflush (rxlog_txt);

#endif
}

void bx_tap_pktmover_c::sendpkt(void *buf, unsigned io_len)
{
  Bit8u txbuf[BX_PACKET_BUFSIZE];
  txbuf[0] = 0;
  txbuf[1] = 0;
#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || \
   defined(__APPLE__)  || defined(__OpenBSD__) // Should be fixed for other *BSD
  memcpy(txbuf, buf, io_len);
  unsigned int size = write(fd, txbuf, io_len);
  if (size != io_len) {
#else
  memcpy(txbuf+2, buf, io_len);
  unsigned int size = write(fd, txbuf, io_len+2);
  if (size != io_len+2) {
#endif
    BX_PANIC(("write on tap device: %s", strerror(errno)));
  } else {
    BX_DEBUG(("wrote %d bytes + 2 byte pad on tap", io_len));
  }
#if BX_ETH_TAP_LOGGING
  BX_DEBUG(("sendpkt length %u", io_len));
  // dump raw bytes to a file, eventually dump in pcap format so that
  // tcpdump -r FILE can interpret them for us.
  int n = fwrite(buf, io_len, 1, txlog);
  if (n != 1) BX_ERROR(("fwrite to txlog failed, io_len = %u", io_len));
  // dump packet in hex into an ascii log file
  fprintf(txlog_txt, "NE2K transmitting a packet, length %u\n", io_len);
  Bit8u *charbuf = (Bit8u *)buf;
  for (n=0; n<(int)io_len; n++) {
    if (((n % 16) == 0) && n>0)
      fprintf(txlog_txt, "\n");
    fprintf(txlog_txt, "%02x ", charbuf[n]);
  }
  fprintf(txlog_txt, "\n--\n");
  // flush log so that we see the packets as they arrive w/o buffering
  fflush(txlog);
  fflush(txlog_txt);
#endif
}

void bx_tap_pktmover_c::rx_timer_handler(void *this_ptr)
{
  bx_tap_pktmover_c *class_ptr = (bx_tap_pktmover_c *) this_ptr;
  class_ptr->rx_timer();
}

void bx_tap_pktmover_c::rx_timer()
{
  int nbytes;
  Bit8u buf[BX_PACKET_BUFSIZE];
  Bit8u *rxbuf;
  if (fd<0) return;
  nbytes = read (fd, buf, sizeof(buf));

  // hack: discard first two bytes
#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__APPLE__)  // Should be fixed for other *BSD
  rxbuf = buf;
#else
  rxbuf = buf+2;
  nbytes-=2;
#endif

#if defined(__linux__)
  // hack: TAP device likes to create an ethernet header which has
  // the same source and destination address FE:FD:00:00:00:00.
  // Change the dest address to FE:FD:00:00:00:01.
  if (!memcmp(&rxbuf[0], &rxbuf[6], 6)) {
    rxbuf[5] = guest_macaddr[5];
  }
#endif

  if (nbytes>0)
    BX_DEBUG (("tap read returned %d bytes", nbytes));
  if (nbytes<0) {
    if (errno != EAGAIN)
      BX_ERROR (("tap read error: %s", strerror(errno)));
    return;
  }
#if BX_ETH_TAP_LOGGING
  if (nbytes > 0) {
    BX_DEBUG (("receive packet length %u", nbytes));
    // dump raw bytes to a file, eventually dump in pcap format so that
    // tcpdump -r FILE can interpret them for us.
    int n = fwrite (rxbuf, nbytes, 1, rxlog);
    if (n != 1) BX_ERROR (("fwrite to rxlog failed, nbytes = %d", nbytes));
    // dump packet in hex into an ascii log file
    fprintf (rxlog_txt, "NE2K received a packet, length %u\n", nbytes);
    for (n=0; n<nbytes; n++) {
      if (((n % 16) == 0) && n>0)
	fprintf (rxlog_txt, "\n");
      fprintf (rxlog_txt, "%02x ", rxbuf[n]);
    }
    fprintf (rxlog_txt, "\n--\n");
    // flush log so that we see the packets as they arrive w/o buffering
    fflush (rxlog);
    fflush (rxlog_txt);
  }
#endif
  BX_DEBUG(("eth_tap: got packet: %d bytes, dst=%x:%x:%x:%x:%x:%x, src=%x:%x:%x:%x:%x:%x\n", nbytes, rxbuf[0], rxbuf[1], rxbuf[2], rxbuf[3], rxbuf[4], rxbuf[5], rxbuf[6], rxbuf[7], rxbuf[8], rxbuf[9], rxbuf[10], rxbuf[11]));
  if (nbytes < 60) {
    BX_INFO (("packet too short (%d), padding to 60", nbytes));
    nbytes = 60;
  }
  (*rxh)(rxarg, rxbuf, nbytes);
}

#endif /* if BX_NETWORKING && defined HAVE_ETHERTAP */
