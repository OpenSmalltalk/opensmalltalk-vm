/////////////////////////////////////////////////////////////////////////
// $Id: eth_fbsd.cc,v 1.34 2008/01/26 22:24:01 sshwarts Exp $
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

// Peter Grehan (grehan@iprg.nokia.com) coded all of this
// NE2000/ether stuff.

// eth_fbsd.cc - A FreeBSD packet filter implementation of
// an ethernet pktmover. There are some problems and limitations
// with FreeBSD:
//   - the source address of the frame is overwritten by
//    the hosts's source address. This causes problems with
//    learning bridges - since they cannot determine where
//    BOCHS 'is', they broadcast the frame to all ports.
//   - packets cannot be sent from BOCHS to the host
//   - TCP performance seems to be abysmal; I think this is
//     a timing problem somewhere.
//   - I haven't handled the case where multiple frames arrive
//     in a single BPF read.
//
//   The /dev/bpf* devices need to be set up with the appropriate
//  permissions for this to work.
//
//   The config line in .bochsrc should look something like:
//
//  ne2k: ioaddr=0x280, irq=9, mac=00:a:b:c:1:2, ethmod=fbsd, ethdev=fxp0
//

// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE
// is used to know when we are exporting symbols and when we are importing.
#define BX_PLUGGABLE

#define NO_DEVICE_INCLUDES
#include "iodev.h"

#if BX_NETWORKING && defined(ETH_FBSD)

#include "eth.h"

#define LOG_THIS bx_devices.pluginNE2kDevice->

extern "C" {
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/bpf.h>
#include <errno.h>
};

#define BX_BPF_POLL  1000    // Poll for a frame every 250 usecs

#define BX_BPF_INSNSIZ  8    // number of bpf insns

// template filter for a unicast mac address and all
// multicast/broadcast frames
static const struct bpf_insn macfilter[] = {
    BPF_STMT(BPF_LD|BPF_W|BPF_ABS, 2),                  // A <- P[2:4]
    BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, 0xaaaaaaaa, 0, 2),  // if A != 0xaaaaaaa GOTO LABEL-1
    BPF_STMT(BPF_LD|BPF_H|BPF_ABS, 0),                  // A <- P[0:2]
    BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, 0x0000aaaa, 2, 0),  // if A == 0xaaaa GOTO ACCEPT
    // LABEL-1
    BPF_STMT(BPF_LD|BPF_B|BPF_ABS, 0),                  // A <- P[0:1]
    BPF_JUMP(BPF_JMP|BPF_JSET|BPF_K, 0x01, 0, 1),       // if !(A & 1) GOTO LABEL-REJECT
    // LABEL-ACCEPT
    BPF_STMT(BPF_RET, 1514),                            // Accept packet
    // LABEL-REJECT
    BPF_STMT(BPF_RET, 0),                               // Reject packet
};

// template filter for all frames
static const struct bpf_insn promiscfilter[] = {
  BPF_STMT(BPF_RET, 1514)
};

//
//  Define the class. This is private to this module
//
class bx_fbsd_pktmover_c : public eth_pktmover_c {
public:
  bx_fbsd_pktmover_c(const char *netif,
		     const char *macaddr,
		     eth_rx_handler_t rxh,
		     void *rxarg, char *script);
  void sendpkt(void *buf, unsigned io_len);

private:
  char *fbsd_macaddr[6];
  int bpf_fd;
  static void rx_timer_handler(void *);
  void rx_timer(void);
  int rx_timer_index;
  struct bpf_insn filter[BX_BPF_INSNSIZ];
  FILE *ne2klog, *ne2klog_txt;
};


//
//  Define the static class that registers the derived pktmover class,
// and allocates one on request.
//
class bx_fbsd_locator_c : public eth_locator_c {
public:
  bx_fbsd_locator_c(void) : eth_locator_c("fbsd") {}
protected:
  eth_pktmover_c *allocate(const char *netif,
			   const char *macaddr,
			   eth_rx_handler_t rxh,
			   void *rxarg, char *script) {
    return (new bx_fbsd_pktmover_c(netif, macaddr, rxh, rxarg, script));
  }
} bx_fbsd_match;


//
// Define the methods for the bx_fbsd_pktmover derived class
//

// the constructor
//
// Open a bpf file descriptor, and attempt to bind to
// the specified netif (Replicates libpcap open code)
//
bx_fbsd_pktmover_c::bx_fbsd_pktmover_c(const char *netif,
				       const char *macaddr,
				       eth_rx_handler_t rxh,
				       void *rxarg,
				       char *script)
{
  char device[sizeof "/dev/bpf000"];
  int tmpfd;
  int n = 0;
  struct ifreq ifr;
  struct bpf_version bv;
  struct bpf_program bp;
  u_int v;

  memcpy(fbsd_macaddr, macaddr, 6);

  do {
    (void)sprintf(device, "/dev/bpf%d", n++);
    this->bpf_fd = open(device, O_RDWR);
	BX_DEBUG(("tried %s, returned %d (%s)",device,this->bpf_fd,strerror(errno)));
	if(errno == EACCES)
		break;
  } while (this->bpf_fd == -1);

  if (this->bpf_fd == -1) {
    BX_PANIC(("eth_freebsd: could not open packet filter: %s", strerror(errno)));
    return;
  }

  if (ioctl(this->bpf_fd, BIOCVERSION, (caddr_t)&bv) < 0) {
    BX_PANIC(("eth_freebsd: could not retrieve bpf version"));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }
  if (bv.bv_major != BPF_MAJOR_VERSION || bv.bv_minor < BPF_MINOR_VERSION) {
    BX_PANIC(("eth_freebsd: bpf version mismatch between compilation and runtime"));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }

  // Set buffer size
  v = BX_PACKET_BUFSIZE;
  if (ioctl(this->bpf_fd, BIOCSBLEN, (caddr_t)&v) < 0) {
    BX_PANIC(("eth_freebsd: could not set buffer size: %s", strerror(errno)));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }

  (void)strncpy(ifr.ifr_name, netif, sizeof(ifr.ifr_name));
  if (ioctl(this->bpf_fd, BIOCSETIF, (caddr_t)&ifr) < 0) {
    BX_PANIC(("eth_freebsd: could not enable interface '%s': %s", netif, strerror(errno)));
    close(this->bpf_fd);
    this->bpf_fd == -1;
  }

  // Verify that the device is an ethernet.
  if (ioctl(this->bpf_fd, BIOCGDLT, (caddr_t)&v) < 0) {
    BX_PANIC(("eth_freebsd: could not retrieve datalink type: %s", strerror(errno)));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }
  if (v != DLT_EN10MB) {
    BX_PANIC(("eth_freebsd: incorrect datalink type %d, expected 10mb ethernet", v));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }

  // Put the device into promisc mode. This could be optimised
  // to filter on a MAC address, broadcast, and all-multi,
  // but this will do for now.
  //
  if (ioctl(this->bpf_fd, BIOCPROMISC, NULL) < 0) {
    BX_PANIC(("eth_freebsd: could not enable promisc mode: %s", strerror(errno)));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }

  v = 1;
  if (ioctl(this->bpf_fd, BIOCIMMEDIATE, &v) < 0) {
    BX_PANIC(("eth_freebsd: could not enable immediate mode"));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }

  // Set up non-blocking i/o
  v = 1;
  if (ioctl(this->bpf_fd, FIONBIO, &v) < 0) {
    BX_PANIC(("eth_freebsd: could not enable non-blocking i/o: %s", strerror(errno)));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }

  // Install a filter
#ifdef notdef
  memcpy(&this->filter, promiscfilter, sizeof(promiscfilter));
  bp.bf_len   = 1;
#else
  memcpy(&this->filter, macfilter, sizeof(macfilter));
  this->filter[1].k =
      (macaddr[2] & 0xff) << 24 |
    (macaddr[3] & 0xff) << 16 |
    (macaddr[4] & 0xff) << 8  |
    (macaddr[5] & 0xff);
  this->filter[3].k =
      (macaddr[0] & 0xff) << 8 |
    (macaddr[1] & 0xff);
  bp.bf_len   = 8;
#endif
  bp.bf_insns = &this->filter[0];
  if (ioctl(this->bpf_fd, BIOCSETF, &bp) < 0) {
    BX_PANIC(("eth_freebsd: could not set filter: %s", strerror(errno)));
    close(this->bpf_fd);
    this->bpf_fd = -1;
    return;
  }

  // Start the rx poll
  this->rx_timer_index =
    bx_pc_system.register_timer(this, this->rx_timer_handler, BX_BPF_POLL,
				1, 1, "eth_fbsd"); // continuous, active

  this->rxh   = rxh;
  this->rxarg = rxarg;

#if BX_ETH_FBSD_LOGGING
  // eventually Bryce wants ne2klog to dump in pcap format so that
  // tcpdump -r FILE can read it and interpret packets.
  ne2klog = fopen ("ne2k.raw", "wb");
  if (!ne2klog) BX_PANIC (("open ne2k-tx.log failed"));
  ne2klog_txt = fopen ("ne2k.txt", "wb");
  if (!ne2klog_txt) BX_PANIC (("open ne2k-txdump.txt failed"));
  fprintf (ne2klog_txt, "null packetmover readable log file\n");
  fprintf (ne2klog_txt, "net IF = %s\n", netif);
  fprintf (ne2klog_txt, "MAC address = ");
  for (int i=0; i<6; i++)
    fprintf (ne2klog_txt, "%02x%s", 0xff & macaddr[i], i<5?":" : "");
  fprintf (ne2klog_txt, "\n--\n");
  fflush (ne2klog_txt);
#endif
}

// the output routine - called with pre-formatted ethernet frame.
void
bx_fbsd_pktmover_c::sendpkt(void *buf, unsigned io_len)
{
#if BX_ETH_FBSD_LOGGING
  BX_DEBUG (("sendpkt length %u", io_len));
  // dump raw bytes to a file, eventually dump in pcap format so that
  // tcpdump -r FILE can interpret them for us.
  int n = fwrite (buf, io_len, 1, ne2klog);
  if (n != 1) BX_ERROR (("fwrite to ne2klog failed", io_len));
  // dump packet in hex into an ascii log file
  fprintf (ne2klog_txt, "NE2K TX packet, length %u\n", io_len);
  Bit8u *charbuf = (Bit8u *)buf;
  for (n=0; n<io_len; n++) {
    if (((n % 16) == 0) && n>0)
      fprintf (ne2klog_txt, "\n");
    fprintf (ne2klog_txt, "%02x ", charbuf[n]);
  }
  fprintf (ne2klog_txt, "\n--\n");
  // flush log so that we see the packets as they arrive w/o buffering
  fflush (ne2klog);
  fflush (ne2klog_txt);
#endif
  int status;

  if (this->bpf_fd != -1)
    status = write(this->bpf_fd, buf, io_len);
}

// The receive poll process
void
bx_fbsd_pktmover_c::rx_timer_handler(void *this_ptr)
{
  bx_fbsd_pktmover_c *class_ptr = (bx_fbsd_pktmover_c *) this_ptr;

  class_ptr->rx_timer();
}


void
bx_fbsd_pktmover_c::rx_timer(void)
{
  int nbytes = 0;
    unsigned char rxbuf[BX_PACKET_BUFSIZE];
  struct bpf_hdr *bhdr;
    struct bpf_stat bstat;
    static struct bpf_stat previous_bstat;
    int counter = 10;
#define phdr ((unsigned char*)bhdr)

    bhdr = (struct bpf_hdr *) rxbuf;
  nbytes = read(this->bpf_fd, rxbuf, sizeof(rxbuf));

    while (phdr < (rxbuf + nbytes)) {
	if (ioctl(this->bpf_fd, BIOCGSTATS, &bstat) < 0) {
	    BX_PANIC(("eth_freebsd: could not stat filter: %s", strerror(errno)));
	}
	if (bstat.bs_drop > previous_bstat.bs_drop) {
	    BX_INFO (("eth_freebsd: %d packets dropped by the kernel.",
		      bstat.bs_drop - previous_bstat.bs_drop));
	}
	previous_bstat = bstat;
	if (bhdr->bh_caplen < 20 || bhdr->bh_caplen > 1514) {
	    BX_ERROR(("eth_freebsd: received too weird packet length: %d", bhdr->bh_caplen));
	}

    // filter out packets sourced from this node
	if (memcmp(bhdr + bhdr->bh_hdrlen + 6, this->fbsd_macaddr, 6)) {
	    (*rxh)(rxarg, phdr + bhdr->bh_hdrlen, bhdr->bh_caplen);
    }
	
#if BX_ETH_FBSD_LOGGING
  /// hey wait there is no receive data with a NULL ethernet, is there....
    BX_DEBUG (("receive packet length %u", nbytes));
    // dump raw bytes to a file, eventually dump in pcap format so that
    // tcpdump -r FILE can interpret them for us.
	if (1 != fwrite (bhdr, bhdr->bh_caplen, 1, ne2klog)) {
	    BX_PANIC (("fwrite to ne2klog failed: %s", strerror(errno)));
	}
    // dump packet in hex into an ascii log file
	fprintf (this->ne2klog_txt, "NE2K RX packet, length %u\n", bhdr->bh_caplen);
    Bit8u *charrxbuf = (Bit8u *)rxbuf;
	int n;
	for (n=0; n<bhdr->bh_caplen; n++) {
      if (((n % 16) == 0) && n>0)
	fprintf (this->ne2klog_txt, "\n");
	    fprintf (this->ne2klog_txt, "%02x ", phdr[n]);
    }
    fprintf (this->ne2klog_txt, "\n--\n");
    // flush log so that we see the packets as they arrive w/o buffering
    fflush (this->ne2klog);
    fflush (this->ne2klog_txt);
#endif

	// Advance bhdr and phdr pointers to next packet
	bhdr = (struct bpf_hdr*) ((char*) bhdr + BPF_WORDALIGN(bhdr->bh_hdrlen + bhdr->bh_caplen));
  }
}

#endif /* if BX_NETWORKING && defined(ETH_FBSD) */

