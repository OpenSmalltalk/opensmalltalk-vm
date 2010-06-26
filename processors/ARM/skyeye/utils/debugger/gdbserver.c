/* debugger: Remote server for GDB.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

#include "skyeye2gdb.h"
#include "skyeye_types.h"
#include <setjmp.h>
#include <stdio.h>
#include <string.h>
#include <sys/file.h>

#ifdef __BEOS__
#include <BeBuild.h>
#endif

//koodailar remove it for mingw 2005.12.18--------------------------------------
#ifndef __MINGW32__
// Anthony Lee 2007-02-02 : for BeOS R5.0.x
#if (defined(__BEOS__) && B_BEOS_VERSION < 0x510)
#include <net/socket.h>
#define PF_INET AF_INET
#else
#include <sys/select.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <sys/ioctl.h>
#endif
#endif
//end --------------------------------------------------------------------------

#include <signal.h>
#include <fcntl.h>

// Anthony Lee 2006-08-22 : for WinSock2
#ifdef __MINGW32__
#undef WORD
#undef byte
#include <windows.h>
#endif

#if (defined(__MINGW32__) || (defined(__BEOS__) && B_BEOS_VERSION < 0x510))
#define Read(a, b, c)	recv(a, b, c, 0)
#define Write(a, b, c)	send(a, b, c, 0)
#define Close(a)	closesocket(a)
#else
#define Read(a, b, c)	read(a, b, c)
#define Write(a, b, c)	write(a, b, c)
#define Close(a)	close(a)
#endif

#undef DEBUG_RDI
//#define DEBUG_RDI
#ifdef DEBUG_RDI
	#define	DBG_RDI(args...) printf(args)
#else
	#define DBG_RDI(args...) 
#endif
extern register_defs_t *current_reg_type;
typedef unsigned long CORE_ADDR;

#ifdef DEBUG_RDI
	int remote_debug = 1;
#else
	int remote_debug = 0;
#endif
static int remote_desc;
jmp_buf toplevel;
int extended_protocol;
int general_thread;
int cont_thread;


unsigned char *registers;

struct SkyEye_ICE skyeye_ice;
/* Open a connection to a remote debugger.
   NAME is the filename used for communication.  */


void
remote_open (char *name)
{
	int save_fcntl_flags;

	char *port_str;
	int port;
	struct sockaddr_in sockaddr;
	int tmp;
	struct protoent *protoent;
	int tmp_desc;

	port_str = strchr (name, ':');

	port = atoi (port_str + 1);

#ifndef __MINGW32__
	if ((tmp_desc = socket (PF_INET, SOCK_STREAM, 0)) < 0) perror ("Can't open socket");
#else
	if ((tmp_desc = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) == INVALID_SOCKET) perror("Can't open socket");
#endif

	/* Allow rapid reuse of this port. */
	tmp = 1;
	setsockopt (tmp_desc, SOL_SOCKET, SO_REUSEADDR, (char *) &tmp,
		    sizeof (tmp));

	sockaddr.sin_family = PF_INET;
	sockaddr.sin_port = htons (port);
	sockaddr.sin_addr.s_addr = INADDR_ANY;

	if (bind (tmp_desc, (struct sockaddr *) &sockaddr, sizeof (sockaddr))
	    || listen (tmp_desc, 1))
		perror ("Can't bind address");

	tmp = sizeof (sockaddr);
	remote_desc = accept (tmp_desc, (struct sockaddr *) &sockaddr, &tmp);
	if (remote_desc == -1)
		perror ("Accept failed");

	/* 2007-02-02 disabled on BeOS R5.0.x by Anthony Lee */
#if !(defined(__BEOS__) && B_BEOS_VERSION < 0x510)
	/* Enable TCP keep alive process. */
	tmp = 1;
	setsockopt (tmp_desc, SOL_SOCKET, SO_KEEPALIVE, (char *) &tmp,
		    sizeof (tmp));

	/* Tell TCP not to delay small packets.  This greatly speeds up
	   interactive response. */
	tmp = 1;
	setsockopt (remote_desc, 6 /* PROTO_TCP */ , TCP_NODELAY,
		    (char *) &tmp, sizeof (tmp));
#endif

	Close (tmp_desc);	/* No longer need this */

#ifndef __MINGW32__
	signal (SIGPIPE, SIG_IGN);	/* If we don't do this, then gdbserver simply
					   exits when the remote side dies.  */
#endif

#if 0				//chy 20050729-------------------
#if defined(F_SETFL) && defined (FASYNC)
	save_fcntl_flags = fcntl (remote_desc, F_GETFL, 0);
	fcntl (remote_desc, F_SETFL, save_fcntl_flags | FASYNC);
	disable_async_io ();
#endif /* FASYNC */
#endif //chy 20050729-------------------
	fprintf (stderr, "Remote debugging using %s\n", name);
}


void
remote_close ()
{
	Close (remote_desc);
}

/* Convert hex digit A to a number.  */

static int
fromhex (int a)
{
	if (a >= '0' && a <= '9')
		return a - '0';
	else if (a >= 'a' && a <= 'f')
		return a - 'a' + 10;
	else if (a >= 'A' && a <= 'F')
		return a - 'A' + 10;
	else
		perror ("Reply contains invalid hex digit");
}

/* Convert number NIB to a hex digit.  */

static int
tohex (int nib)
{
	if (nib < 10)
		return '0' + nib;
	else
		return 'a' + nib - 10;
}

/* Send a packet to the remote machine, with error checking.
   The data of the packet is in BUF.  Returns >= 0 on success, -1 otherwise. */

int
putpkt (char *buf)
{
	int i;
	unsigned char csum = 0;
	char buf2[2000];
	char buf3[1];
	int cnt = strlen (buf);
	char *p;

	/* Copy the packet into buffer BUF2, encapsulating it
	   and giving it a checksum.  */

	p = buf2;
	*p++ = '$';

	for (i = 0; i < cnt; i++) {
		csum += buf[i];
		*p++ = buf[i];
	}
	*p++ = '#';
	*p++ = tohex ((csum >> 4) & 0xf);
	*p++ = tohex (csum & 0xf);

	*p = '\0';

	/* Send it over and over until we get a positive ack.  */

	do {
		int cc;

		if (Write (remote_desc, buf2, p - buf2) != p - buf2) {
			perror ("putpkt(write)");
			return -1;
		}

		if (remote_debug)
			DBG_RDI ("putpkt (\"%s\"); [looking for ack]\n", buf2);
		cc = Read (remote_desc, buf3, 1);
		if (remote_debug)
			DBG_RDI ("[received '%c' (0x%x)]\n", buf3[0], buf3[0]);
		if (cc <= 0) {
			if (cc == 0)
				fprintf (stderr, "putpkt(read): Got EOF\n");
			else
				perror ("putpkt(read)");

			return -1;
		}
	}
	while (buf3[0] != '+');

	return 1;		/* Success! */
}


/* 2007-02-02 disabled by Anthony Lee : not used */
#if 0
/* Come here when we get an input interrupt from the remote side.  This
   interrupt should only be active while we are waiting for the child to do
   something.  About the only thing that should come through is a ^C, which
   will cause us to send a SIGINT to the child.  */

static void
input_interrupt ()
{
	int cc;
	char c;

	cc = Read (remote_desc, &c, 1);

	if (cc != 1 || c != '\003') {
		fprintf (stderr, "input_interrupt, cc = %d c = %d\n", cc, c);
		return;
	}

	DBG_RDI ("SkyEye debugger: input_interrupt: get a ctrl-c\n");
	skyeye_exit (-1);
	//kill (inferior_pid, SIGINT);
}


void
enable_async_io ()
{
	signal (SIGIO, input_interrupt);
}

void
disable_async_io ()
{
	signal (SIGIO, SIG_IGN);
}
#endif

/* Returns next char from remote GDB.  -1 if error.  */

static int
readchar ()
{
	static char buf[BUFSIZ];
	static int bufcnt = 0;
	static char *bufp;

	if (bufcnt-- > 0)
		return *bufp++ & 0x7f;

	bufcnt = Read (remote_desc, buf, sizeof (buf));

	if (bufcnt <= 0) {
		if (bufcnt == 0)
			fprintf (stderr, "readchar: Got EOF\n");
		else
			perror ("readchar");

		return -1;
	}

	bufp = buf;
	bufcnt--;
	return *bufp++ & 0x7f;
}

/* Read a packet from the remote machine, with error checking,
   and store it in BUF.  Returns length of packet, or negative if error. */

int
getpkt (char *buf)
{
	char *bp;
	unsigned char csum, c1, c2;
	int c;

	while (1) {
		csum = 0;

		while (1) {
			c = readchar ();
			if (c == '$')
				break;
			if (remote_debug)
				DBG_RDI ("[getpkt: discarding char '%c']\n",
					c);
			if (c < 0)
				return -1;
		}

		bp = buf;
		while (1) {
			c = readchar ();
			if (c < 0)
				return -1;
			if (c == '#')
				break;
			*bp++ = c;
			csum += c;
		}
		*bp = 0;

		c1 = fromhex (readchar ());
		c2 = fromhex (readchar ());

		if (csum == (c1 << 4) + c2)
			break;

		fprintf (stderr,
			 "Bad checksum, sentsum=0x%x, csum=0x%x, buf=%s\n",
			 (c1 << 4) + c2, csum, buf);
		Write (remote_desc, "-", 1);
	}

	if (remote_debug)
		DBG_RDI ("getpkt (\"%s\");  [sending ack] \n", buf);

	Write (remote_desc, "+", 1);

	if (remote_debug)
		DBG_RDI ("[sent ack]\n");
	return bp - buf;
}

void
write_ok (char *buf)
{
	buf[0] = 'O';
	buf[1] = 'K';
	buf[2] = '\0';
}

void
write_enn (char *buf)
{
	buf[0] = 'E';
	buf[1] = '0';
	buf[2] = '1';
	buf[3] = '\0';
}
static void
convert_int_to_ascii (char *from, char *to, int n)
{
	int nib;
	char ch;
	while (n--) {
		ch = *from++;
		nib = ((ch & 0xf0) >> 4) & 0x0f;
		*to++ = tohex (nib);
		nib = ch & 0x0f;
		*to++ = tohex (nib);
	}
	*to++ = 0;
}

static void
convert_ascii_to_int (char *from, char *to, int n)
{
	int nib1, nib2;
	while (n--) {
		nib1 = fromhex (*from++);
		nib2 = fromhex (*from++);
		*to++ = (((nib1 & 0x0f) << 4) & 0xf0) | (nib2 & 0x0f);
	}
}

static char *
outreg (int regno, char *buf)
{
	int regsize = current_reg_type->register_raw_size(regno);

	*buf++ = tohex (regno >> 4);
	*buf++ = tohex (regno & 0xf);
	*buf++ = ':';
	convert_int_to_ascii (&registers[current_reg_type->register_byte (regno)], buf,
			      regsize);
	buf += 2 * regsize;
	*buf++ = ';';

	return buf;
}

void
prepare_resume_reply (char *buf, char status, unsigned char signo)
{
	int nib;

	*buf++ = status;

	/* FIXME!  Should be converting this signal number (numbered
	   according to the signal numbering of the system we are running on)
	   to the signal numbers used by the gdb protocol (see enum target_signal
	   in gdb/target.h).  */
	nib = ((signo & 0xf0) >> 4);
	*buf++ = tohex (nib);
	nib = signo & 0x0f;
	*buf++ = tohex (nib);

	if (status == 'T') {
		buf = outreg (current_reg_type->pc_regnum, buf);
		buf = outreg (current_reg_type->fp_regnum, buf);
		buf = outreg (current_reg_type->sp_regnum, buf);

	}
	/* For W and X, we're done.  */
	*buf++ = 0;
}

static void
decode_m_packet (char *from, CORE_ADDR * mem_addr_ptr, unsigned int *len_ptr)
{
	int i = 0, j = 0;
	char ch;
	*mem_addr_ptr = *len_ptr = 0;

	while ((ch = from[i++]) != ',') {
		*mem_addr_ptr = *mem_addr_ptr << 4;
		*mem_addr_ptr |= fromhex (ch) & 0x0f;
	}

	for (j = 0; j < 4; j++) {
		if ((ch = from[i++]) == 0)
			break;
		*len_ptr = *len_ptr << 4;
		*len_ptr |= fromhex (ch) & 0x0f;
	}
}

static void
decode_M_packet (char *from, CORE_ADDR * mem_addr_ptr, unsigned int *len_ptr,
		 char *to)
{
	int i = 0;
	char ch;
	*mem_addr_ptr = *len_ptr = 0;

	while ((ch = from[i++]) != ',') {
		*mem_addr_ptr = *mem_addr_ptr << 4;
		*mem_addr_ptr |= fromhex (ch) & 0x0f;
	}

	while ((ch = from[i++]) != ':') {
		*len_ptr = *len_ptr << 4;
		*len_ptr |= fromhex (ch) & 0x0f;
	}

	convert_ascii_to_int (&from[i++], to, *len_ptr);
}

static void
decode_DP_playload (char * buffer, int tp_id, action *parent_action)
{
	int i=0;
	char ch;
	action* current_action;
	unsigned int remaining_step;
	unsigned int pass_count,remaining_pass;
	unsigned int mask;
	unsigned offset, length;
	int base_reg;
	
	switch (buffer[i])
	{
		case 'E':
			{
				i=i+2;
				remaining_step=0;
				while ((ch = buffer[i++]) != ':')
				{
					remaining_step = remaining_step << 4;
					remaining_step |= fromhex (ch) & 0x0f;
				}
				
				pass_count=0;
				while (((ch = buffer[i]) != '-') &&((ch = buffer[i]) != '\0'))
				{
					pass_count = pass_count << 4;
					pass_count |= fromhex (ch) & 0x0f;
					i++;
				}
				
				set_tracepoint_status(tp_id, TRACEPOINT_ENABLED);
				set_tracepoint_remaining_step(tp_id, remaining_step );
				set_tracepoint_pass_count(tp_id, pass_count );
				set_tracepoint_remaining_pass(tp_id, pass_count );
	
			}
			break;
		case 'D':
			{
				i=i+2;
				remaining_step=0;
				while ((ch = buffer[i++]) != ':')
				{
					remaining_step = remaining_step << 4;
					remaining_step |= fromhex (ch) & 0x0f;
				}
				
				pass_count=0;
				while (((ch = buffer[i]) != '-') &&((ch = buffer[i]) != '\0'))
				{
					pass_count = pass_count << 4;
					pass_count |= fromhex (ch) & 0x0f;
					i++;
				}
				
				set_tracepoint_status(tp_id, TRACEPOINT_DISABLED);
				set_tracepoint_remaining_step(tp_id, remaining_step );
				set_tracepoint_pass_count(tp_id, pass_count );
				set_tracepoint_remaining_pass(tp_id, pass_count );
			}
			break;
		case 'R':
			{
				i++;
				
				mask=0;
				while (((ch = buffer[i]) != '-') &&((ch = buffer[i]) != '\0'))
				{
					mask  = mask << 4;
					mask |= fromhex (ch) & 0x0f;
					i++;
				}
				current_action = prepare_action(tp_id, parent_action);
				set_action_type (current_action, ACTION_COLLECT);
				set_action_data_type(current_action,COLLECT_REGISTERS);
				set_rc_action_mask(current_action, mask);
			}
			break;
		case 'M':
			{
				i++;
				
				//get base_reg
				if (buffer[i]=='-')
				{
					base_reg=-1;
					while ((ch = buffer[i++]) != ',');
				}
				else
				{
					base_reg=0;
					i++;
					while (((ch = buffer[i]) != ',') &&((ch = buffer[i]) != '\0'))
					{
						base_reg  = base_reg << 4;
						base_reg |= fromhex (ch) & 0x0f;
						i++;
					}
					
				}
				
				//get offset
				offset=0;
				while (((ch = buffer[i]) != ',') &&((ch = buffer[i]) != '\0'))
				{
					offset  = offset << 4;
					offset |= fromhex (ch) & 0x0f;
					i++;
				}
				
				//get_length
				length=0;
				i++;
				while (((ch = buffer[i]) != '-') &&((ch = buffer[i]) != '\0'))
				{
					length  = length << 4;
					length |= fromhex (ch) & 0x0f;
					i++;
				}
				
				current_action = prepare_action(tp_id, parent_action);
				set_action_type (current_action, ACTION_COLLECT);
				set_action_data_type(current_action,COLLECT_MEMORY);
				set_mc_action_base_reg(current_action,base_reg);
				set_mc_action_offset(current_action,offset);
				set_mc_action_length(current_action,length);
			}
			break;
		case 'X':
			break;
		case 'S':
			{
				i++;
				current_action = prepare_action(tp_id, parent_action);
				set_action_type (current_action, ACTION_WHILE);
				set_wa_step_count(current_action,get_tracepoint_remaining_step(tp_id));
				set_wa_remaining_steps(current_action,get_tracepoint_remaining_step(tp_id));
				
				decode_DP_playload (&buffer[i], tp_id, current_action);
			}
			break;
		default :;
	}
}

static void
decode_DP_packet(char * buffer, char * response)
{
	int i=0;
	int cont=0;
	char ch;
	unsigned int tp_number =0;
	unsigned int tp_address=0;
	int tp_id=-1; //tp_id is the position of the tracepoint on the skyeye_ice.tps array
	
	if (buffer [0]=='-')
	{
		i=1;
		cont= 1;
	}
	//getting tp_number
	while ((ch = buffer[i++]) != ':')
	{
		tp_number = tp_number << 4;
		tp_number |= fromhex (ch) & 0x0f;
	}
	//getting tp_address
	while ((ch = buffer[i++]) != ':')
	{
		tp_address = tp_address << 4;
		tp_address |= fromhex (ch) & 0x0f;
	}
	
	if ((tp_id=find_tp_id (tp_number,tp_address))!=-1)
	{
	}
	else
	{
		tp_id=add_tracepoint (tp_number,tp_address);
	}

	decode_DP_playload (&buffer[i], tp_id, NULL);
	return;
}

static void
decode_Frame_packet(char *buffer, char* response)
{
	int i;
	char ch;
	unsigned int frame_number;
	unsigned int tracepoint_number;
	
	start_trace_focusing ();
	switch (buffer[0])
	{
		case 'p': //pc
			{
				i=3;
			}
			break;
		case 't': //tdp
			{
				i=4;
				tracepoint_number=0;
				while ((ch = buffer[i]) != '\0')
			{
				tracepoint_number  = tracepoint_number << 4;
				tracepoint_number |= fromhex (ch) & 0x0f;
				i++;
			}
			if (select_frame_buffer_by_tpn (tracepoint_number,&frame_number))
			{
				sprintf (response,"F%xT%x",frame_number,tracepoint_number);
			}
			else
			{
				sprintf (response,"F-1");
			  }

			}
			break;
		case 'r': //range
			{
				i=6;
			}
			break;
		case 'o': //outside
			{
				i=8;
			}
			break;
		default: //a frame number or an error
			{
				i=0;
				
				
				frame_number=0;
				while ((ch = buffer[i]) != '\0')
				{
					frame_number  = frame_number << 4;
					frame_number |= fromhex (ch) & 0x0f;
					i++;
				}
			
				//is it a tfind start none?
				if (frame_number==0xFFFFFFFF)
				{
					stop_trace_focusing ();
					
					sprintf (response,"OK");
				}else
				{
					if (select_frame_buffer_by_fn (&tracepoint_number,frame_number))
					{
						sprintf (response,"F%xT%x",frame_number,tracepoint_number);
					}
					else
					{
						sprintf (response,"F-1");
					}
				}
			}
	}
}

static void
decode_ro_packet (char *buffer,char *response)
{
	char ch;
	int i;
	unsigned int *address;
	unsigned int start_address;
	unsigned int end_address;
	
	i=0;
	start_address=0;
	end_address=0;
	
	address = &start_address;
	while ((ch = buffer[i]) != '\0')
	{
		switch (ch)
		{
			case ',':
				{
					address=&end_address;
					i++;
				}
				break;
			case ':':
				{
					address = &start_address;
					add_ro_region(start_address, end_address);
					start_address=0;
					end_address=0;
					
					address=&start_address;
					i++;
				}
				break;
			default :
				{
				  *address  = *address << 4;
				  *address |= fromhex (ch) & 0x0f;
				  i++;
				}
		}
	}
	if ((ch==0)&&((start_address!=0)||(end_address!=0)))
	{
		add_ro_region(start_address, end_address);
	}
	sprintf(response,"OK");
}

static int
decode_Q_packet (char *buffer, char *response)
{
	int i=0;

	//init
		
	if (buffer [i] !='T') //a valid trace request
	{
		return (0);
	}else
	{
		
		i=1;
	}

	switch (buffer [i])
	{
		case 'i'://init
			{
				init_tracepoints();
				write_ok (response);
				return (1);
			};
		case 'S'://start or stop
			{
				if (buffer [i+2]=='a') //start
				{
					start_trace_recording();
					write_ok (response);
					return (1);
				}else
				if (buffer [i+2]=='o') //stop
				{
					stop_trace_recording();
					write_ok (response);
					return (1);
				}else
				{
					return (0);
				}
			};
			break;
		case 'D'://DP
			{
				decode_DP_packet (&(buffer[i+3]),response);
				write_ok (response);
				return (1);
			}
			break;
		case 'F'://frame
			{
				decode_Frame_packet(&(buffer[i+6]),response);
				return (1);
			}
			break;
		case 'r':  //ro
			{
				decode_ro_packet (&(buffer[i+3]),response);
				return (1);
			}
		default :
			{
				return (0);
			}
	}

	return (0);
}

void
fetch_inferior_registers (int regno, unsigned char *memory)
{
	if (regno == -1 || regno == 0)
		for (regno = 0; regno < current_reg_type->num_regs; regno++)
			current_reg_type->fetch_register (regno,
					    &memory[current_reg_type->register_byte (regno)]);
	else
		current_reg_type->fetch_register (regno, &(memory[current_reg_type->register_byte (regno)]));
}

static void
store_inferior_registers (int regno, unsigned char *memory)
{
	if (regno == -1 || regno == 0)
		for (regno = 0; regno < current_reg_type->num_regs; regno++)
			current_reg_type->store_register (regno,
					    &(memory[current_reg_type->register_byte (regno)]));
	else
		current_reg_type->store_register (regno, &(memory[current_reg_type->register_byte (regno)]));
}
int
sim_debug ()
{
	static char own_buf[8000], mem_buf[8000];
	char *p;
	char ch, status;
	int i = 0;
	unsigned char signal;
	unsigned int len,addr;
	CORE_ADDR mem_addr;
	int type,size;

	registers = (unsigned char *)malloc(current_reg_type->register_bytes);

	//chy 2006-04-12 init skyeye_ice
	skyeye_ice.num_bps=0;

	if (setjmp (toplevel)) {
		fprintf (stderr, "Exiting\n");
		skyeye_exit (1);
	}
	while (1) {
		remote_open ("host:12345");

	      restart:
		setjmp (toplevel);
		while (getpkt (own_buf) > 0) {
			unsigned char sig;
			i = 0;
			ch = own_buf[i++];
			switch (ch) {
			case 'd':
				remote_debug = !remote_debug;
				break;
#if 0				// chy 2005-07-30
			case '!':
				extended_protocol = 1;
				prepare_resume_reply (own_buf, status,
						      signal);
				break;
#endif //chy
			case '?':
				status = 'S';
				signal = 5;
				prepare_resume_reply (own_buf, status,
						      signal);
				break;
#if 0				// chy 2005-07-30
			case 'H':
				switch (own_buf[1]) {
				case 'g':
					general_thread =
						strtol (&own_buf[2], NULL,
							16);
					write_ok (own_buf);
					fetch_inferior_registers (0);
					break;
				case 'c':
					cont_thread =
						strtol (&own_buf[2], NULL,
							16);
					write_ok (own_buf);
					break;
				default:
					/* Silently ignore it so that gdb can extend the protocol
					   without compatibility headaches.  */
					own_buf[0] = '\0';
					break;
				}
				break;
#endif //chy 2005-07-30
			case 'g':
				if (get_trace_status() == TRACE_FOCUSING)
					trace_fetch_registers (-1, registers);
				else
					fetch_inferior_registers (-1, registers);
				convert_int_to_ascii (registers, own_buf,
						      current_reg_type->register_bytes);
				break;
			case 'G':
				convert_ascii_to_int (&own_buf[1], registers,
						      current_reg_type->register_bytes);
				store_inferior_registers (-1, registers);
				write_ok (own_buf);
				break;
			case 'm':
				decode_m_packet (&own_buf[1], &mem_addr,
						 &len);
				if ((get_trace_status() == TRACE_FOCUSING) && (is_in_ro_region(mem_addr,len) == 0))
					size = trace_read (mem_addr, mem_buf, len);
				else
					size = sim_read (mem_addr, mem_buf, len);
				if(size!=-1)
					convert_int_to_ascii (mem_buf, own_buf, len);
				else 
					write_enn (own_buf);
				break;
			case 'M':
				decode_M_packet (&own_buf[1], &mem_addr, &len,
						 mem_buf);
				//chy 2005-07-30  ARM_BREAKPOINT          0xe7ffdefe
				//bp_opcode_conv( (unsigned int) mem_addr, (unsigned int*)mem_buf );                    
				//chy 2006-04-12 debug
				//printf("SKYEYE, debugger M  addr 0x%x, word 0x%x, len 0x%x\n", mem_addr, *((unsigned int *)mem_buf), len);  
				if (sim_write (mem_addr, mem_buf, len) == len)
					write_ok (own_buf);
				else
					write_enn (own_buf);
				break;
			case 'Q':
				if (decode_Q_packet (&own_buf[1], own_buf) == 0) own_buf[0] = '\0';
				break;
			case 'q':
				switch (own_buf[1]) {
					case 'T':
						//Status
						if (get_trace_status() == TRACE_STARTED)
						{
							own_buf[0] = 'T';
							own_buf[1] = '1';
							own_buf[2] = '\0';
						} else {
							own_buf[0] = 'T';
							own_buf[1] = '0';
							own_buf[2] = '\0';
						}
						break;
					default:
						own_buf[0] = '\0';
						break;
				}
			break;
				/* chy 2005-07-28
				   case 'q':
				   switch (own_buf[1]) {
				   case 'C':
				   own_buf[0] = '\0';
				   break;
				   case 'O':
				   send_area(own_buf);
				   break;
				   default:
				   own_buf[0] = '\0';
				   break;
				   }
				   break;
				   case 'C':
				   convert_ascii_to_int (own_buf + 1, &sig, 1);
				   myresume (0, sig);
				   signal = mywait (&status);
				   prepare_resume_reply (own_buf, status, signal);
				   break;
				   case 'S':
				   convert_ascii_to_int (own_buf + 1, &sig, 1);
				   myresume (1, sig);
				   signal = mywait (&status);
				   prepare_resume_reply (own_buf, status, signal);
				   break;
				   chy */
			case 'c':
				//chy 2005-07-30
				//ARMul_DoProg (state);
				//sim_resume(0);
				gdbserver_cont();
				prepare_resume_reply (own_buf, status,
						      signal);
				break;
			case 's':
				//chy 2005-07-30
				//sim_resume(1);
				//sim_step_debug();
				//myresume (1, 0);
				//signal = mywait (&status);
				gdbserver_step();
				prepare_resume_reply (own_buf, status,
						      signal);
				break;
			case 'z':
				{
					p=&(own_buf[1]);
					type = strtoul(p, (char **)&p, 16);
					if (*p == ',')
					p++;
					addr = strtoul(p, (char **)&p, 16);
					if (*p == ',')
					p++;
					len = strtoul(p, (char **)&p, 16);
					//printf("SKYEYE:gdbserver z, type %d, addr %x, len %x\n",type, addr,len); 
					if (type == 0 || type == 1) {
					       if (sim_ice_breakpoint_remove(addr) < 0)
					                    goto remove_breakpoint_error;
					       write_ok(own_buf);
					} else {
					   remove_breakpoint_error:
						write_enn(own_buf);
					}
				}
				break;
			case 'Z':
				{
					p=&(own_buf[1]);
					type = strtoul(p, (char **)&p, 16);
					if (*p == ',')
					p++;
					addr = strtoul(p, (char **)&p, 16);
					if (*p == ',')
					p++;
					len = strtoul(p, (char **)&p, 16);
					//printf("SKYEYE:gdbserver Z, type %d, addr %x, len %x\n",type, addr,len); 
					if (type == 0 || type == 1) {
					       if (sim_ice_breakpoint_insert(addr) < 0)
					                    goto insert_breakpoint_error;
					       write_ok(own_buf);
					} else {
					   insert_breakpoint_error:
						write_enn(own_buf);
					}
				}
				break;
#if 0				// chy 2005-07-30
			case 'k':
				fprintf (stderr, "Killing inferior\n");
				kill_inferior ();
				/* When using the extended protocol, we start up a new
				   debugging session.   The traditional protocol will
				   exit instead.  */
				if (extended_protocol) {
					write_ok (own_buf);
					fprintf (stderr,
						 "GDBserver restarting\n");

					/* Wait till we are at 1st instruction in prog.  */
					//chy 20050729 go to restart
					//signal = start_inferior (&argv[2], &status);
					goto restart;
					break;
				}
				else {
					exit (0);
					break;
				}
			case 'T':
				if (mythread_alive
				    (strtol (&own_buf[1], NULL, 16)))
					write_ok (own_buf);
				else
					write_enn (own_buf);
				break;
			case 'R':
				/* Restarting the inferior is only supported in the
				   extended protocol.  */
				if (extended_protocol) {
					kill_inferior ();
					write_ok (own_buf);
					fprintf (stderr,
						 "GDBserver restarting\n");

					/* Wait till we are at 1st instruction in prog.  */
					//chy 20050729 go to restart
					//signal = start_inferior (&argv[2], &status);
					goto restart;
					break;
				}
				else {
					/* It is a request we don't understand.  Respond with an
					   empty packet so that gdb knows that we don't support this
					   request.  */
					own_buf[0] = '\0';
					break;
				}
#endif //chy 2005-07-30
			default:
				/* It is a request we don't understand.  Respond with an
				   empty packet so that gdb knows that we don't support this
				   request.  */
				DBG_RDI(stderr,"unknown command: %c\n",ch);
				own_buf[0] = '\0';
				break;
			}

			putpkt (own_buf);

			if (status == 'W')
				fprintf (stderr,
					 "\nChild exited with status %d\n",
					 sig);
			if (status == 'X')
				fprintf (stderr,
					 "\nChild terminated with signal = 0x%x\n",
					 sig);
			if (status == 'W' || status == 'X') {
				if (extended_protocol) {
					//chy 2005-07-30
					fprintf (stderr,
						 "CHY SkyEye: not Killing inferior\n");
					//kill_inferior ();
					write_ok (own_buf);
					fprintf (stderr,
						 "GDBserver restarting\n");

					/* Wait till we are at 1st instruction in prog.  */
					//chy 20050729 go to restart
					//signal = start_inferior (&argv[2], &status);
					goto restart;
					break;
				}
				else {
					fprintf (stderr,
						 "GDBserver exiting\n");
					skyeye_exit (0);
				}
			}
		}

		/* We come here when getpkt fails.

		   For the extended remote protocol we exit (and this is the only
		   way we gracefully exit!).

		   For the traditional remote protocol close the connection,
		   and re-open it at the top of the loop.  */
		if (extended_protocol) {
			remote_close ();
			skyeye_exit (0);
		}
		else {
			fprintf (stderr,
				 "Remote side has terminated connection.  GDBserver will reopen the connection.\n");

			remote_close ();
		}
	}
}

/*
 * stop when press Ctrl+c
 */
int remote_interrupt()
{
       static fd_set rfds;
       static struct timeval tv;

       tv.tv_sec = 0;
       tv.tv_usec = 0;
       FD_ZERO( &rfds );
       FD_SET( remote_desc, &rfds );

       if (select( remote_desc+1, &rfds, NULL, NULL, &tv ) == 1 )
       {
               int n;
               static char buf[100];

               n = Read( remote_desc, buf, sizeof(buf) );
               if ( n > 0 )
		       DBG_RDI("Got async char");
               if ( buf[0] == '\003' )
                       DBG_RDI(":Ctrl+C, interrupted.\n");
               return 1;
       }
       return 0;
}


