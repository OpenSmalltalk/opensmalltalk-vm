#include <stdarg.h>
#define COG 1
#define FOR_COG_PLUGIN 1

// Requires per-target include paths:
// ../../processors/IA32/bochs ../../processors/IA32/bochs/instrument/stubs
#include <bochs.h>
#include <cpu/cpu.h>
#include <iodev/iodev.h>

#define min(a,b) ((a)<=(b)?(a):(b))
/*
 * Define setjmp and longjmp to be the most minimal setjmp/longjmp available
 * on the platform.
 */
#if !WIN32
# define setjmp(jb) _setjmp(jb)
# define longjmp(jb,v) _longjmp(jb,v)
#endif

BOCHSAPI BX_CPU_C bx_cpu;

extern "C" {

#include "BochsX64Plugin.h"

static int            cpu_has_been_reset = 0;

#define LOGSIZE 4096
static char           bochs_log[LOGSIZE + 1];
static int            blidx = 0;

static unsigned char *theMemory = 0;
static unsigned long  theMemorySize;
static unsigned long  minReadAddress;
static unsigned long  minWriteAddress;
static int            theErrorAcorn;
static bx_address     last_read_address = (bx_address)-1; /* for RMW cycles */

	   void			(*prevInterruptCheckChain)() = 0;
       long           resetCPU(void *cpu);

	void *
	newCPU()
	{
		if (!cpu_has_been_reset) {
			resetCPU(&bx_cpu);
			cpu_has_been_reset = 1;
		}
		return &bx_cpu;
	}

	long
	resetCPU(void *cpu)
	{
		BX_CPU_C *anx64 = (BX_CPU_C *)cpu;

		if (anx64 != &bx_cpu)
			return BadCPUInstance;

		blidx = 0;
#define RESET_FROM_COG BX_RESET_HARDWARE + 1
		bx_cpu.reset(RESET_FROM_COG);
		// Origin the code, data & stack segments at 0
		bx_cpu.parse_selector(0x0000,&bx_cpu.sregs[BX_SEG_REG_CS].selector);
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.base  = 0;
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.d_b   = 1; // 32-bit seg
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.l     = 1; // 64-bit seg
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.limit = 0xffff;
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled = 0xffffffff;
		bx_cpu.parse_selector(0x0000,&bx_cpu.sregs[BX_SEG_REG_DS].selector);
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.base  = 0;
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.d_b   = 1; // 32-bit seg
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.l     = 1; // 64-bit seg
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.limit = 0xffff;
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.limit_scaled = 0xffffffff;
		bx_cpu.parse_selector(0x0000,&bx_cpu.sregs[BX_SEG_REG_SS].selector);
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.base  = 0;
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.d_b   = 1; // 32-bit seg
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.l     = 1; // 64-bit seg
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.limit = 0xffff;
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.limit_scaled = 0xffffffff;

		bx_cpu.gen_reg[BX_64BIT_REG_RAX].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_RBX].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_RCX].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_RDX].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_RSP].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_RBP].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_RSI].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_RDI].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_R8].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_R9].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_R10].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_R11].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_R12].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_R13].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_R14].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_R15].dword.erx = 0;
		bx_cpu.gen_reg[BX_64BIT_REG_RIP].dword.erx = 0;
		bx_cpu.efer.set_LMA(1); /* Hack.  The old version we use have doesn't support set_EFER */
		bx_cpu.SetCR0(0x80000101); // Enter protected mode
		return bx_cpu.cpu_mode == BX_MODE_LONG_64
				? 0
				: InitializationError;
	}

	long
	singleStepCPUInSizeMinAddressReadWrite(void *cpu,
									void *memory, ulong byteSize,
									ulong minAddr, ulong minWriteMaxExecAddr)
	{
		BX_CPU_C *anx64 = (BX_CPU_C *)cpu;

		if (anx64 != &bx_cpu)
			return BadCPUInstance;
		theMemory = (unsigned char *)memory;
		theMemorySize = byteSize;
		minReadAddress = minAddr;
		minWriteAddress = minWriteMaxExecAddr;
		if ((theErrorAcorn = setjmp(anx64->jmp_buf_env)) != 0) {
			anx64->gen_reg[BX_64BIT_REG_RIP].dword.erx = anx64->prev_rip;
			return theErrorAcorn;
		}

		blidx = 0;
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled
			= minWriteMaxExecAddr > 0 ? minWriteMaxExecAddr - 1 : 0;
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.limit_scaled =
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.limit_scaled = byteSize;
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.limit = minWriteMaxExecAddr >> 16;
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.limit =
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.limit = byteSize >> 16;
		anx64->eipFetchPtr = theMemory;
		anx64->eipPageWindowSize = minWriteMaxExecAddr;
		anx64->cpu_single_step();

		return blidx == 0 ? 0 : SomethingLoggedError;
	}

	long
	runCPUInSizeMinAddressReadWrite(void *cpu, void *memory, ulong byteSize,
									ulong minAddr, ulong minWriteMaxExecAddr)
	{
		BX_CPU_C *anx64 = (BX_CPU_C *)cpu;

		if (anx64 != &bx_cpu)
			return BadCPUInstance;
		theMemory = (unsigned char *)memory;
		theMemorySize = byteSize;
		minReadAddress = minAddr;
		minWriteAddress = minWriteMaxExecAddr;
		if ((theErrorAcorn = setjmp(anx64->jmp_buf_env)) != 0) {
			anx64->gen_reg[BX_64BIT_REG_RIP].dword.erx = anx64->prev_rip;
			return theErrorAcorn;
		}

		blidx = 0;
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.limit_scaled
			= minWriteMaxExecAddr > 0 ? minWriteMaxExecAddr - 1 : 0;
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.limit_scaled =
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.limit_scaled = byteSize;
		bx_cpu.sregs[BX_SEG_REG_CS].cache.u.segment.limit = minWriteMaxExecAddr >> 16;
		bx_cpu.sregs[BX_SEG_REG_DS].cache.u.segment.limit =
		bx_cpu.sregs[BX_SEG_REG_SS].cache.u.segment.limit = byteSize >> 16;
		anx64->eipFetchPtr = theMemory;
		anx64->eipPageWindowSize = minWriteMaxExecAddr;
		bx_pc_system.kill_bochs_request = 0;
		anx64->cpu_loop(0 /* = "run forever" until exception or interupt */);
		if (anx64->stop_reason != STOP_NO_REASON) {
			anx64->gen_reg[BX_64BIT_REG_RIP].dword.erx = anx64->prev_rip;
			if (theErrorAcorn == NoError)
				theErrorAcorn = ExecutionError;
			return theErrorAcorn;
		}
		return blidx == 0 ? 0 : SomethingLoggedError;
	}

	/*
	 * Currently a dummy for Bochs.
	 */
	void
	flushICacheFromTo(void *cpu, ulong saddr, ulong eaddr)
	{
#if BX_SUPPORT_ICACHE
# error not yet implemented
#endif
	}

	long
	disassembleForAtInSize(void *cpu, ulong laddr,
							void *memory, ulong byteSize)
	{
		BX_CPU_C *anx64 = (BX_CPU_C *)cpu;

		Bit8u  instr_buf[16];
		size_t i=0;

		static char letters[] = "0123456789ABCDEF";
		static disassembler bx_disassemble;
		long remainsInPage = byteSize - laddr;

		if (remainsInPage < 0) {
			theErrorAcorn = MemoryBoundsError;
			return -MemoryBoundsError;
		}

		memcpy(instr_buf, (char *)memory + laddr, min(15,byteSize - laddr));
		i = sprintf(bochs_log, "%08lx: ", laddr);
		bx_disassemble.set_syntax_att();
		unsigned isize = bx_disassemble.disasm(
							anx64->sregs[BX_SEG_REG_CS].cache.u.segment.d_b,
							anx64->sregs[BX_SEG_REG_CS].cache.u.segment.l,
							anx64->get_segment_base(BX_SEG_REG_CS), laddr,
							instr_buf,
							bochs_log+i);
		if (isize <= remainsInPage) {
		  i=strlen(bochs_log);
		  bochs_log[i++] = ' ';
		  bochs_log[i++] = ':';
		  bochs_log[i++] = ' ';
		  for (unsigned j=0; j<isize; j++) {
			bochs_log[i++] = letters[(instr_buf[j] >> 4) & 0xf];
			bochs_log[i++] = letters[(instr_buf[j] >> 0) & 0xf];
			bochs_log[i++] = ' ';
		  }
		}
		bochs_log[blidx = i] = 0;
		return isize;
	}

	void
	forceStopRunning(void)
	{
		if (prevInterruptCheckChain)
			prevInterruptCheckChain();
		bx_pc_system.kill_bochs_request = 1;
		bx_cpu.async_event = 1;
	}

	long
	errorAcorn(void) { return theErrorAcorn; }

	char *
	getlog(long *len)
	{
		*len = blidx;
		return bochs_log;
	}
} // extern "C"

/*
 * With COG we implement the paging access_read/write_linear level here
 * to access data to/from the current Bitmap memory object.  This is hence
 * a simplified subset of cpu/paging.cc.
 */
#define LOG_THIS BX_CPU_THIS_PTR

#define BX_PHY_ADDRESS_MASK ((((Bit64u)(1)) << BX_PHY_ADDRESS_WIDTH) - 1)

#define BX_PHY_ADDRESS_RESERVED_BITS \
      (~BX_PHY_ADDRESS_MASK & BX_CONST64(0xfffffffffffff))

// bit [11] of the TLB lpf used for TLB_HostPtr valid indication
#define TLB_LPFOf(laddr) AlignedAccessLPFOf(laddr, 0x7ff)

  void BX_CPP_AttrRegparmN(2)
BX_CPU_C::pagingCR0Changed(Bit32u oldCR0, Bit32u newCR0)
{
  // Modification of PG,PE flushes TLB cache according to docs.
  // Additionally, the TLB strategy is based on the current value of
  // WP, so if that changes we must also flush the TLB.
  if ((oldCR0 & 0x80010001) != (newCR0 & 0x80010001))
    TLB_flush(); // Flush Global entries also.
}

  void BX_CPP_AttrRegparmN(2)
BX_CPU_C::pagingCR4Changed(Bit32u oldCR4, Bit32u newCR4)
{
  // Modification of PGE,PAE,PSE flushes TLB cache according to docs.
  if ((oldCR4 & 0x000000b0) != (newCR4 & 0x000000b0))
    TLB_flush(); // Flush Global entries also.

}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::SetCR3(bx_address val)
{
  // flush TLB even if value does not change
#if BX_SUPPORT_GLOBAL_PAGES
  if (BX_CPU_THIS_PTR cr4.get_PGE())
    TLB_flushNonGlobal(); // Don't flush Global entries.
  else
#endif
    TLB_flush();          // Flush Global entries also.

  {
#if BX_PHY_ADDRESS_WIDTH == 32
    if (val & BX_CONST64(0x000fffff00000000)) {
      BX_PANIC(("SetCR3() 0x%08x%08x: Only 32 bit physical address space is emulated !", GET32H(val), GET32L(val)));
    }
#endif
    if (val & BX_PHY_ADDRESS_RESERVED_BITS) {
      BX_ERROR(("SetCR3(): Attempt to write to reserved bits of CR3"));
      exception(BX_GP_EXCEPTION, 0, 0);
    }
    BX_CPU_THIS_PTR cr3_masked = val & BX_CONST64(0x000ffffffffff000);
  }

  BX_CPU_THIS_PTR cr3 = val;
}

// Called to initialize the TLB upon startup.
// Unconditional initialization of all TLB entries.
void BX_CPU_C::TLB_init(void)
{
  TLB_flush();
}

void BX_CPU_C::TLB_flush(void)
{
}

void BX_CPU_C::TLB_flushNonGlobal(void)
{
}

void BX_CPU_C::TLB_invlpg(bx_address laddr)
{
}

void BX_CPP_AttrRegparmN(1) BX_CPU_C::INVLPG(bxInstruction_c* i)
{
#if BX_CPU_LEVEL >= 4
    BX_ERROR(("INVLPG: priviledge check failed, generate #GP(0)"));
    exception(BX_GP_EXCEPTION, 0, 0);
#else
	BX_INFO(("INVLPG: required i486, use --enable-cpu=4 option"));
	exception(BX_UD_EXCEPTION, 0, 0);
#endif
}

// error checking order - page not present, reserved bits, protection
#define ERROR_NOT_PRESENT       0x00
#define ERROR_PROTECTION        0x01
#define ERROR_RESERVED          0x08
#define ERROR_CODE_ACCESS       0x10

/* PSE PDE4M: bits [21:17] */
#define PAGING_PSE_PDE4M_RESERVED_BITS \
    (BX_PHY_ADDRESS_RESERVED_BITS | BX_CONST64(0x003E0000))

// Translate a linear address to a physical address
bx_phy_address BX_CPU_C::translate_linear(bx_address laddr, unsigned curr_pl, unsigned rw, unsigned access_type)
{
  return laddr;
}

#if BX_DEBUGGER || BX_DISASM || BX_INSTRUMENTATION || BX_GDBSTUB
bx_bool BX_CPU_C::dbg_xlate_linear2phy(bx_address laddr, bx_phy_address *phy)
{
    *phy = (bx_phy_address) laddr;
    return 1;
}
#endif

void BX_CPU_C::access_write_linear(bx_address laddr, unsigned len, unsigned curr_pl, void *data)
{
#if BX_X86_DEBUGGER
  hwbreakpoint_match(laddr, len, BX_WRITE);
#endif

	if (laddr < minWriteAddress
	 || laddr + len > theMemorySize)
		longjmp(bx_cpu.jmp_buf_env,MemoryBoundsError);
	memcpy(theMemory + laddr, data, len);
}

void BX_CPU_C::access_read_linear(bx_address laddr, unsigned len, unsigned curr_pl, unsigned xlate_rw, void *data)
{
  BX_ASSERT(xlate_rw == BX_READ || xlate_rw == BX_RW);

	if (laddr < minReadAddress
	 || laddr + len > theMemorySize)
		longjmp(bx_cpu.jmp_buf_env,MemoryBoundsError);
	last_read_address = laddr; /* for RMW write cycles below */
	memcpy(data, theMemory + laddr, len);
}

/*
 * With COG we implement the paging access_read/write_linear level here
 * to access data to/from the current Bitmap memory object.  This is hence
 * a simplified subset of the RMW operations in cpu/access32.cc
 */
  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::write_RMW_virtual_byte(Bit8u val8)
{
	if (last_read_address == (bx_address)-1)
		longjmp(bx_cpu.jmp_buf_env,PanicError);
	memcpy(theMemory + last_read_address, &val8, 1);
	last_read_address = (bx_address)-1;
}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::write_RMW_virtual_word(Bit16u val16)
{
	if (last_read_address == (bx_address)-1)
		longjmp(bx_cpu.jmp_buf_env,PanicError);
	memcpy(theMemory + last_read_address, &val16, 2);
	last_read_address = (bx_address)-1;
}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::write_RMW_virtual_dword(Bit32u val32)
{
	if (last_read_address == (bx_address)-1)
		longjmp(bx_cpu.jmp_buf_env,PanicError);
	memcpy(theMemory + last_read_address, &val32, 4);
	last_read_address = (bx_address)-1;
}

  void BX_CPP_AttrRegparmN(1)
BX_CPU_C::write_RMW_virtual_qword(Bit64u val64)
{
	if (last_read_address == (bx_address)-1)
		longjmp(bx_cpu.jmp_buf_env,PanicError);
	memcpy(theMemory + last_read_address, &val64, 8);
	last_read_address = (bx_address)-1;
}


// Cut-down parts of memory/misc_mem.cc for cpu/debugstuff.cc
bx_bool BX_MEM_C::dbg_fetch_mem(BX_CPU_C *cpu, bx_phy_address addr, unsigned len, Bit8u *buf)
{
	if (addr + len > theMemorySize)
		return 0;

	memcpy(buf, theMemory + addr, len);
	return 1;
}

// Cut-down cpu/smm.cc
void BX_CPP_AttrRegparmN(1)
BX_CPU_C::RSM(bxInstruction_c *i)
{
	BX_ERROR(("BX_CPU_C::RSM not yet implemented"));
	theErrorAcorn = UnsupportedOperationError;
	longjmp(bx_cpu.jmp_buf_env,1);
}

void
BX_CPU_C::enter_system_management_mode(void)
{
	BX_ERROR(("BX_CPU_C::enter_system_management_mode not yet implemented"));
	theErrorAcorn = UnsupportedOperationError;
	longjmp(bx_cpu.jmp_buf_env,1);
}

// Cut-down cpu/io_pro.cc
  Bit32u BX_CPP_AttrRegparmN(2)
bx_devices_c::inp(Bit16u addr, unsigned io_len)
{
	BX_ERROR(("BX_CPU_C::inp not yet implemented"));
	theErrorAcorn = UnsupportedOperationError;
	longjmp(bx_cpu.jmp_buf_env,1);
	return 0;
}

  void BX_CPP_AttrRegparmN(3)
bx_devices_c::outp(Bit16u addr, Bit32u value, unsigned io_len)
{
	BX_ERROR(("BX_CPU_C::outp not yet implemented"));
	theErrorAcorn = UnsupportedOperationError;
	longjmp(bx_cpu.jmp_buf_env,1);
}

// Cut-down gui/siminterface.cc

static logfunctions thePluginLog;
logfunctions *pluginlog = &thePluginLog;

// Dummy SIM object; we don't use the SIM interface or libgui.a
bx_simulator_interface_c *SIM = NULL;

#undef LOG_THIS
#define LOG_THIS bx_pc_system.

// Dummy pc_system object; we don't have a pc, but this contains the
//  bx_pc_system.kill_bochs_request flag we use to break out of loops.
bx_pc_system_c bx_pc_system;

// constructor
bx_pc_system_c::bx_pc_system_c()
{
  BX_ASSERT(numTimers == 0);

  // Timer[0] is the null timer.  It is initialized as a special
  // case here.  It should never be turned off or modified, and its
  // duration should always remain the same.
  ticksTotal = 0; // Reset ticks since emulator started.
  timer[0].inUse      = 1;
  timer[0].period     = 0xffffffff; // see NullTimerInterval in pc_system.cc
  timer[0].active     = 1;
  timer[0].continuous = 1;
  timer[0].funct      = (void (*)(void *))0; // see nullTimer in pc_system.cc
  timer[0].this_ptr   = this;
  numTimers = 1; // So far, only the nullTimer.
  kill_bochs_request = 0;
}

int bx_pc_system_c::Reset(unsigned type)
{
  // type is BX_RESET_HARDWARE or BX_RESET_SOFTWARE
  BX_INFO(("bx_pc_system_c::Reset(%s) called",type==BX_RESET_HARDWARE?"HARDWARE":"SOFTWARE"));

  // Always reset cpu
  for (int i=0; i<BX_SMP_PROCESSORS; i++) {
    BX_CPU(i)->reset(type);
  }

  return(0);
}

#undef LOG_THIS

// Cut-down bx_devices (see iodev/devices.cc)
bx_devices_c bx_devices;

// constructor for bx_devices_c
bx_devices_c::bx_devices_c()
{
  settype(DEVLOG);

  read_port_to_handler = NULL;
  write_port_to_handler = NULL;
  io_read_handlers.next = NULL;
  io_read_handlers.handler_name = NULL;
  io_write_handlers.next = NULL;
  io_write_handlers.handler_name = NULL;

  for (unsigned i=0; i < BX_MAX_IRQS; i++)
    irq_handler_name[i] = NULL;
}

bx_devices_c::~bx_devices_c()
{
  // nothing needed for now
  timer_handle = BX_NULL_TIMER_HANDLE;
}

// Versions of the iofunctions that libcpu uses that log to a buffer
//
// logfunctions::put(char const*)
// logfunctions::info(char const*, ...)
// logfunctions::panic(char const*, ...)
// logfunctions::ldebug(char const*, ...)
// logfunctions::settype(int)
// logfunctions::logfunctions()
// logfunctions::~logfunctions()
// logfunctions::error(char const*, ...)

logfunctions::logfunctions(void) {}

logfunctions::~logfunctions() {}

#define sprintlog(fmt,ap) \
do { \
	va_list ap; \
	va_start(ap, fmt); \
	int len = vsnprintf(bochs_log + blidx, LOGSIZE-blidx, fmt, ap); \
	if ((blidx = min(blidx + len, LOGSIZE)) < LOGSIZE - 1) { \
		bochs_log[blidx]   = '\r'; \
		bochs_log[++blidx] = 0; \
	} \
} while (0)

void logfunctions::put(const char *p)
{
	int len = strlen(p);
	strncpy(bochs_log + blidx, p, min(len,LOGSIZE-blidx));
	blidx = min(blidx + len, LOGSIZE);
	bochs_log[blidx] = 0;
}

void logfunctions::settype(int t) {}

void logfunctions::info(const char *fmt, ...) { sprintlog(fmt,ap); }

void logfunctions::error(const char *fmt, ...) { sprintlog(fmt,ap); }

void logfunctions::panic(const char *fmt, ...)
{
	sprintlog(fmt,ap);
	longjmp(bx_cpu.jmp_buf_env,PanicError);
}

void logfunctions::ldebug(const char *fmt, ...) { sprintlog(fmt,ap); }
