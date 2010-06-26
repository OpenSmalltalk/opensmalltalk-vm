#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"
#include "omap5912.h"

/*ywc 2005-03-30*/
#include "skyeye_flash.h"

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"

//ywc,2004-11-30,declare a external array which stores touchscreen event information
extern unsigned int Pen_buffer[8];	// defined in skyeye_lcd.c
//ywc,2004-11-30,declare a external array which stores touchscreen event information,end

//define omap uart interrupt type
#define REC_LINE_STA	0x6
#define RX_TM_OUT	0xc
#define RHR_INT		0x4
#define THR_INT		0x2
//chy 2005-09-19, the define of omap27x_io_t is in omap.h
//static omap5912_io_t omap5912_io;
static struct omap5912_io_t omap5912_io;

static void
omap5912_io_reset ()
{
	memset(&omap5912_io, 0, sizeof(struct omap5912_io_t));
#if 1
	omap5912_io.timer.mpu_read_timer[0] = 0xea5f/500;
	omap5912_io.timer.mpu_load_timer[0] = 0xea5f/500;
	omap5912_io.timer.mpu_read_timer[1] = 0xffffffff/(50*1024*1024);
	omap5912_io.timer.mpu_load_timer[1] = 0xffffffff/(50*1024*1024);
#endif
#if 1
	omap5912_io.uart.lsr = 0x60;
	omap5912_io.uart.iir = 0x1;
	omap5912_io.uart.tcr = 0xf;
	omap5912_io.uart.mdr1 = 0x7;
	omap5912_io.uart.blr = 0x40;
	omap5912_io.uart.wer = 0x7f;
#endif
	omap5912_io.uart.msr = 0x90;
	
	omap5912_io.os_timer.os_timer_tick_cntr = (0xff);

	omap5912_io.ic.mpu_l2_mir = 0xffffffff;
	omap5912_io.ic.mpu_l2_itr = 0x0;
	omap5912_io.ic.mpu_l1_mir = 0xffffffff;
	omap5912_io.ic.mpu_l1_itr = 0x0;
}
static
omap_set_intr (u32 interrupt)
{
}

static int
omap_pending_intr (u32 interrupt)
{
}

static void
omap5912_update_l2_int (ARMul_State * state)
{
	ARMword requests;
	int i;	
	//printf(" here mpu2_itr data = %x\n", omap5912_io.ic.mpu_l2_itr);
	requests = omap5912_io.ic.mpu_l2_itr & ((~omap5912_io.ic.mpu_l2_mir) & 0xffffffff);
//	printf("mpu2 requests %x\n",requests);
//	printf(" here mpu1_itr data = %x\n", omap5912_io.ic.mpu_l1_itr);

	if ((requests & (1<<14)))			       //uart1 14
	{
		omap5912_io.ic.mpu_l1_itr |= 0x1;             //l2 interrupt mapped to l1 IRQ0
		//printf("requests_l2_test\n");
	}
	#if 1
		for (i=31; i>=0; i--)
		{
			if (omap5912_io.ic.mpu_l1_itr & (1 << i))
				break;
		}
		if (i <=31)
		{
			omap5912_io.ic.mpu_l1_sir_irq_code = i;
		}
	#endif
//	printf(" here mpu1_itr data = %x\n", omap5912_io.ic.mpu_l1_itr);
}

static void
omap5912_update_int (ARMul_State * state)
{
	//uart1 and os timer int is mapped to l2 int
        ARMword requests;

	//printf("irq sig initial: %x\n", state->NirqSig);
	omap5912_update_l2_int(state);

	//printf(" here test  mpu1_itr data = %x\n", omap5912_io.ic.mpu_l1_itr);
	requests = omap5912_io.ic.mpu_l1_itr & ((~omap5912_io.ic.mpu_l1_mir) & 0xffffffff);
	//printf("requests %x\n",requests);
	state->NirqSig = (requests) ? LOW : HIGH;
	state->NfiqSig = HIGH;

	//printf("irq sig in l1:%x\n", state->NirqSig);

}

static void
omap_update_intr (void *mach)
{
        struct machine_config *mc = (struct machine_config *) mach;
        ARMul_State *state = (ARMul_State *) mc->state;
	omap5912_update_int(state);
}


static void
omap5912_io_do_cycle (ARMul_State * state)
{
	struct timeval tv;
	unsigned char buf;
	int i = 0;

	tv.tv_sec = 0;
	tv.tv_usec = 0;
	/** mpu timer interrupt update*/
#if 1
		if ((omap5912_io.timer.mpu_cntl_timer[0] & 0x23) == 0x23) //bit5 enable clock; bit1 auto or oneshot;bit0 start decrem
		{
			//omap5912_io.timer.mpu_read_timer[0] &= 0x0000000f;
			omap5912_io.timer.mpu_read_timer[0]--;
			//printf("omap5912_io.timer.mpu_load_timer[0] = %x\n",omap5912_io.timer.mpu_load_timer[0]);
			//printf("omap5912_io.timer.mpu_read_timer[0] = %x\n",omap5912_io.timer.mpu_read_timer[0]);

			if (omap5912_io.timer.mpu_read_timer[0] == 0)
			{
				//printf("omap5912_io.timer.mpu_read_timer[0] = %x\n",omap5912_io.timer.mpu_read_timer[0]);
				omap5912_io.timer.mpu_read_timer[0] = (omap5912_io.timer.mpu_load_timer[0]);

				//printf("omap5912_io.timer.mpu_read_timer[0] = %x\n",omap5912_io.timer.mpu_read_timer[0]);
				omap5912_io.ic.mpu_l1_itr |= (1 << 26);
				/*shoulod add some code to determin which priority the interrpt is!1*/
		#if 1
				for (i=31; i>=0; i--)
				{
					if (omap5912_io.ic.mpu_l1_itr & (1 << i))
						break;
				}
				if (i <=31)
				{
					omap5912_io.ic.mpu_l1_sir_irq_code = i;
					//omap5912_io.ic.mpu_l1_itr &= ~(1 << i);
				}
		#endif
				omap5912_update_int(state);
				return;
			}	
			//omap5912_update_int(state);
		}
#endif

	/*uart interrupt update*/
#if 0
	if ((omap5912_io.uart.ier & 0xf) == 0x5)
	{
		//printf("uart_lsr%x\n", omap5912_io.uart.lsr);
		//printf("uart_ier%x\n", omap5912_io.uart.ier);
		if (skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0)
		{
			//if (buf == 1) buf = 3;

			//printf("buf%x\n", buf);
			omap5912_io.uart.rhr = buf;
			omap5912_io.uart.lsr |= (0x1); //bit 0: no data in receive bugger
			//omap5912_io.uart.iir |= RHR_INT;
		}
		//omap5912_io.uart.iir &= 0x0 ;
		if ((omap5912_io.uart.ier & 0x1) && (omap5912_io.uart.lsr & 0x1))
		{
			omap5912_io.uart.iir = RHR_INT;
			omap5912_io.ic.mpu_l2_itr |= (1<<14);
		#if 1
		for (i=31; i>=0; i--)
		{
			if (omap5912_io.ic.mpu_l2_itr & (1 << i))
				break;
		}
		if (i <=31)
		{
			omap5912_io.ic.mpu_l2_sir_irq = i;
			//printf("i = %d\n", i);
		}
		#endif
		}
		omap5912_update_int(state);
		return;
		
	}
#endif
		omap5912_update_int(state);
}

static void
omap5912_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	omap_ioreg_t ioregaddr = addr;

#if 1
	if ((addr >= UART1_RHR) && (addr <= UART1_WER))
	{
		switch (addr) { 
		/**uart 1*/
		case UART1_THR:
		{	
			int i;
			//omap5912_io.uart.thr = data;
			//omap5912_io.uart.dll = data;
			unsigned char c = data;
			if (skyeye_uart_write(-1, &c, 1, NULL) < 0)
			{
				return;
			}
			//omap5912_io.uart.iir = 0x1;
			omap5912_io.uart.lsr = 0x60;
			//omap5912_io.uart.iir = THR_INT & (0xff);
		#if 1
			//if transmit interrupt comes
			if ((omap5912_io.uart.ier & 0xf) == 0x2)
			//if ((omap5912_io.uart.iir & 0xf) == THR_INT)
			{
				//printf("whyhere\n");
				omap5912_io.ic.mpu_l2_itr |= (1<<14);
				for (i=31; i>=0; i--)
				{	
					if (omap5912_io.ic.mpu_l2_itr & (1 << i))
						break;
				}
				if (i <=31)
				{
					omap5912_io.ic.mpu_l2_sir_irq = i;
				}

				omap5912_update_int(state);
			}
		#endif

		}
			//printf("data in thr=%x\n", data);
			break;
		
		case  UART1_IER:
			omap5912_io.uart.ier = data;
		//	omap5912_io.uart.dlh = data;
		//	printf("data in ier=%x\n", data);
			break;
		case UART1_FCR:
			omap5912_io.uart.fcr = data;
		//	omap5912_io.uart.efr = data;
			break;
		case UART1_LCR:
			omap5912_io.uart.lcr = data;
			break;
		case UART1_MCR:
			omap5912_io.uart.mcr = data;
		//	omap5912_io.uart.xon1 = data;
			break;
		case UART1_XON2:
			omap5912_io.uart.xon2 = data;
			break;
		case UART1_TCR:
			omap5912_io.uart.tcr = data;
			//omap5912_io.uart.xoff1 = data;
			break;
		case UART1_SPR:
			omap5912_io.uart.spr = data;
			//omap5912_io.uart.tlr = data;
			//omap5912_io.uart.xoff2 = data;
			break;
		case UART1_MDR1:
			omap5912_io.uart.mdr1 = data;
			break;
		case UART1_MDR2:
			omap5912_io.uart.mdr2 = data;
			break;
		case UART1_TXFLL:
			omap5912_io.uart.txfll = data;
			break;
		case UART1_TXFLH:
			omap5912_io.uart.txflh = data;
			break;
		case UART1_RXFLL:
			omap5912_io.uart.rxfll = data;
			break;
		case UART1_SFREGH: 
			omap5912_io.uart.sfregh = data;
			//omap5912_io.uart.rxflh = data;
			break;
		case UART1_BLR:
			omap5912_io.uart.blr = data;
			break;
		case UART1_ACREG:
			omap5912_io.uart.acreg = data;
			break;
		case UART1_SCR:
			omap5912_io.uart.scr = data;
			break;
		case UART1_SSR:
			omap5912_io.uart.ssr = data;
			break;
		case UART1_EBLR:
			omap5912_io.uart.eblr = data;
			break;
		case UART1_SYSC:
			omap5912_io.uart.sysc = data;
			break;
		case UART1_SYSS:
			omap5912_io.uart.syss = data;
			break;
		case UART1_WER:
			omap5912_io.uart.wer = data;
			break;
		default:
			break;
		}//?endswitch
	}//endif
#endif	
	if ((ioregaddr >= MPU_L1_ILR0) && (ioregaddr <=MPU_L1_ILR31))
	{
		int offset = (ioregaddr - MPU_L1_ILR0)/4;
		omap5912_io.ic.mpu_l1_ilr[offset] = data;
		//printf("mpu l1 ilr[%d] 0x%x\n",offset,data);
		return;
	}
	if ((ioregaddr >= MPU_L2_ILR0) && (ioregaddr <=MPU_L2_ILR31))
	{
		int offset = (ioregaddr - MPU_L2_ILR0)/4;
		omap5912_io.ic.mpu_l2_ilr[offset] = data;
		//printf("mpu l2 ilr[%d] 0x%x\n",offset/4,data);
		return;
	}
	if ((ioregaddr >= MPU_L2_ILR0_S1) && (ioregaddr <=MPU_L2_ILR31_S1))
	{
		int offset = (ioregaddr - MPU_L2_ILR0_S1)/4;
		omap5912_io.ic.mpu_l2_ilr_s1[offset] = data;
		//printf("mpu l2 ilr[%d] 0x%x\n",offset/4,data);
		return;
	}
	if ((ioregaddr >= MPU_L2_ILR0_S2) && (ioregaddr <=MPU_L2_ILR31_S2))
	{
		int offset = (ioregaddr - MPU_L2_ILR0_S2)/4;
		omap5912_io.ic.mpu_l2_ilr_s2[offset] = data;
		//printf("mpu l2 ilr[%d] 0x%x\n",offset/4,data);
		return;
	}
	if ((ioregaddr >= MPU_L2_ILR0_S3) && (ioregaddr <=MPU_L2_ILR31_S3))
	{
		int offset = (ioregaddr - MPU_L2_ILR0_S3)/4;
		omap5912_io.ic.mpu_l2_ilr_s3[offset] = data;
		//printf("mpu l2 ilr[%d] 0x%x\n",offset/4,data);
		return;
	}

	switch (ioregaddr) { 
		/*os timer*/
		case OS_TIMER_TICK_VAL:
			omap5912_io.os_timer.os_timer_tick_val = data & (0x00ffffff);
			break;
		case OS_TIMER_CTRL:
			omap5912_io.os_timer.os_timer_ctrl = data;
			printf("timeros control register %x\n", data);
			break;
		/*
		case TIMER_32K_SYNCHRONIZED:
			omap5912_io.timer_32k_synchronized = data;
			printf("write 32k synchronized%x\n", data);
			break;
		*/
		/*mpu timer*/
		case MPU_CNTL_TIMER1:
			omap5912_io.timer.mpu_cntl_timer[0] = data;
			break;
		case MPU_LOAD_TIMER1:
			//omap5912_io.timer.mpu_load_timer[0] = 1000/8/6; //what size should be set?
			omap5912_io.timer.mpu_load_timer[0] = data/1000; //what size should be set?
			//printf("timer1 load register %x\n", omap5912_io.timer.mpu_load_timer[0]);
			break;
		case MPU_CNTL_TIMER2:
			omap5912_io.timer.mpu_cntl_timer[1] = data;
			break;
		case MPU_LOAD_TIMER2:
			//omap5912_io.timer.mpu_load_timer[1] = (0xffffffff)/(100*1024*1024); //what size should be set?
			omap5912_io.timer.mpu_load_timer[1] = data; //what size should be set?
			//printf("timer2 load register %x\n", omap5912_io.timer.mpu_load_timer[1]);
			break;
		case MPU_CNTL_TIMER3:
			omap5912_io.timer.mpu_cntl_timer[2] = data;
			break;
		case MPU_LOAD_TIMER3:
			omap5912_io.timer.mpu_load_timer[2] = data;
			break;
		
		/**uart 1*/
#if 0
		case UART1_THR:
		{	omap5912_io.uart.thr = (data & 0xff);
			unsigned char c = (data & 0xff);
			j = skyeye_uart_write(-1, &c, 1, NULL);
			omap5912_io.uart.lsr |= 0x60;
		//	printf("here,j =%d\n", j);
		}
			break;
#endif
		/** interrupt control*/
		case MPU_L2_ITR:
			omap5912_io.ic.mpu_l2_itr = data;
			//printf("write mpu2_itr data = %x\n", data);
			break;
		case MPU_L2_MIR:
			omap5912_io.ic.mpu_l2_mir = data;
			//printf("write mpu2_imr data = %x\n", data);
			break;
		case MPU_L2_CONTROL:
		#if 1
			{
			int i;
			i = omap5912_io.ic.mpu_l2_sir_irq;
			//printf("sirirq i = %x\n", i);
			omap5912_io.ic.mpu_l2_itr &= ~(1 << i);
			}
			#endif

			omap5912_io.ic.mpu_l2_control = data;
			//printf("write mpu2_control data = %x\n", data);
			break;
		case MPU_L2_ISR:
			omap5912_io.ic.mpu_l2_isr = data;
	//	printf("write mpu2_l2 isr data = %x\n", data);
			break;
		case MPU_L2_OCP_CFG:
			omap5912_io.ic.mpu_l2_ocp_cfg = data;
			//printf("write mpu2_l2 ocp cfg  data = %x\n", data);
			break;
		case MPU_L1_ITR:
			omap5912_io.ic.mpu_l1_itr = (data &0xffffffff);
			//printf("write mpu1_itr data = %x\n", data);
			break;
		case MPU_L1_MIR:
			omap5912_io.ic.mpu_l1_mir = data;
			//printf("write mpu1_imr data = %x\n", data);
			break;
		case MPU_L1_CONTROL:
			#if 1
			{
			int i;
			i = omap5912_io.ic.mpu_l1_sir_irq_code;
			//printf("sirirq i = %x\n", i);
			omap5912_io.ic.mpu_l1_itr &= ~(1 << i);
			}
			#endif
			omap5912_io.ic.mpu_l1_control = data;
			//printf("write mpu_l1 control data = %x\n", data);
			break;
		case MPU_L1_ISR:
			omap5912_io.ic.mpu_l1_isr = data;
			//printf("write mpu_l1 isr data = %x\n", data);
			break;
		case MPU_L1_ENHANCEED_CNTL:
			omap5912_io.ic.mpu_l1_enhanceed_cntl = data;
			//printf("write mpu_l1 enhaced data = %x\n", data);
			break;
		/** gpio1*/
		case GPIO1_SYSCONFIG:
			omap5912_io.gpio[0].gpio_sysconfig = data;
			break;
		case GPIO1_IRQSTATUS1:
			omap5912_io.gpio[0].gpio_irqstatus1 = data;
			break;
		case GPIO1_IRQENABLE1:
			omap5912_io.gpio[0].gpio_irqenable1 = data;
			break;
		case GPIO1_IRQSTATUS2:
			omap5912_io.gpio[0].gpio_irqstatus2 = data;
			break;
		case GPIO1_IRQENABLE2:
			omap5912_io.gpio[0].gpio_irqenable2 = data;
			break;
		case GPIO1_WAKEUPENABLE:
			omap5912_io.gpio[0].gpio_wakeupenable = data;
			break;
	//	case GPIO1_DATAIN:
	//		omap5912_io.gpio[0].gpio_datain = data;
	//		break;
		case GPIO1_DATAOUT:
			omap5912_io.gpio[0].gpio_dataout = data;
			break;
		case GPIO1_DIRECTION:
			omap5912_io.gpio[0].gpio_direction = data;
			break;
		case GPIO1_EDGE_CTRL1:
			omap5912_io.gpio[0].gpio_edge_ctrl1 = data;
			break;
		case GPIO1_EDGE_CTRL2:
			omap5912_io.gpio[0].gpio_edge_ctrl2 = data;
			break;
		case GPIO1_CLEAR_IRQENABLE1:
			omap5912_io.gpio[0].gpio_clear_irqenable1 = data;
			break;
		case GPIO1_CLEAR_IRQENABLE2:
			omap5912_io.gpio[0].gpio_clear_irqenable2 = data;
			break;
		case GPIO1_CLEAR_WAKEUPENA:
			omap5912_io.gpio[0].gpio_clear_wakeupena = data;
			break;
		case GPIO1_CLEAR_DATAOUT:
			omap5912_io.gpio[0].gpio_clear_dataout = data;
			break;
		case GPIO1_SET_IRQENABLE1:
			omap5912_io.gpio[0].gpio_set_irqenable1 = data;
			break;
		case GPIO1_SET_IRQENABLE2:
			omap5912_io.gpio[0].gpio_set_irqenable2 = data;
			break;
		case GPIO1_SET_WAKEUPENA:
			omap5912_io.gpio[0].gpio_set_wakeupena = data;
			break;
		case GPIO1_SET_DATAOUT:
			omap5912_io.gpio[0].gpio_set_dataout = data;
			break;	
		/** gpio2*/
		case GPIO2_SYSCONFIG:
			omap5912_io.gpio[1].gpio_sysconfig = data;
			break;
		case GPIO2_IRQSTATUS1:
			omap5912_io.gpio[1].gpio_irqstatus1 = data;
			break;
		case GPIO2_IRQENABLE1:
			omap5912_io.gpio[1].gpio_irqenable1 = data;
			break;
		case GPIO2_IRQSTATUS2:
			omap5912_io.gpio[1].gpio_irqstatus2 = data;
			break;
		case GPIO2_IRQENABLE2:
			omap5912_io.gpio[1].gpio_irqenable2 = data;
			break;
		case GPIO2_WAKEUPENABLE:
			omap5912_io.gpio[1].gpio_wakeupenable = data;
			break;
		case GPIO2_DATAOUT:
			omap5912_io.gpio[1].gpio_dataout = data;
			break;
		case GPIO2_DIRECTION:
			omap5912_io.gpio[1].gpio_direction = data;
			break;
		case GPIO2_EDGE_CTRL1:
			omap5912_io.gpio[1].gpio_edge_ctrl1 = data;
			break;
		case GPIO2_EDGE_CTRL2:
			omap5912_io.gpio[1].gpio_edge_ctrl2 = data;
			break;
		case GPIO2_CLEAR_IRQENABLE1:
			omap5912_io.gpio[1].gpio_clear_irqenable1 = data;
			break;
		case GPIO2_CLEAR_IRQENABLE2:
			omap5912_io.gpio[1].gpio_clear_irqenable2 = data;
			break;
		case GPIO2_CLEAR_WAKEUPENA:
			omap5912_io.gpio[1].gpio_clear_wakeupena = data;
			break;
		case GPIO2_CLEAR_DATAOUT:
			omap5912_io.gpio[1].gpio_clear_dataout = data;
			break;
		case GPIO2_SET_IRQENABLE1:
			omap5912_io.gpio[1].gpio_set_irqenable1 = data;
			break;
		case GPIO2_SET_IRQENABLE2:
			omap5912_io.gpio[1].gpio_set_irqenable2 = data;
			break;
		case GPIO2_SET_WAKEUPENA:
			omap5912_io.gpio[1].gpio_set_wakeupena = data;
			break;
		case GPIO2_SET_DATAOUT:
			omap5912_io.gpio[1].gpio_set_dataout = data;
			break;	
		/** gpio2*/
		case GPIO3_SYSCONFIG:
			omap5912_io.gpio[2].gpio_sysconfig = data;
			break;
		case GPIO3_IRQSTATUS1:
			omap5912_io.gpio[2].gpio_irqstatus1 = data;
			break;
		case GPIO3_IRQENABLE1:
			omap5912_io.gpio[2].gpio_irqenable1 = data;
			break;
		case GPIO3_IRQSTATUS2:
			omap5912_io.gpio[2].gpio_irqstatus2 = data;
			break;
		case GPIO3_IRQENABLE2:
			omap5912_io.gpio[2].gpio_irqenable2 = data;
			break;
		case GPIO3_WAKEUPENABLE:
			omap5912_io.gpio[2].gpio_wakeupenable = data;
			break;
		case GPIO3_DATAOUT:
			omap5912_io.gpio[2].gpio_dataout = data;
			break;
		case GPIO3_DIRECTION:
			omap5912_io.gpio[2].gpio_direction = data;
			break;
		case GPIO3_EDGE_CTRL1:
			omap5912_io.gpio[2].gpio_edge_ctrl1 = data;
			break;
		case GPIO3_EDGE_CTRL2:
			omap5912_io.gpio[2].gpio_edge_ctrl2 = data;
			break;
		case GPIO3_CLEAR_IRQENABLE1:
			omap5912_io.gpio[2].gpio_clear_irqenable1 = data;
			break;
		case GPIO3_CLEAR_IRQENABLE2:
			omap5912_io.gpio[2].gpio_clear_irqenable2 = data;
			break;
		case GPIO3_CLEAR_WAKEUPENA:
			omap5912_io.gpio[2].gpio_clear_wakeupena = data;
			break;
		case GPIO3_CLEAR_DATAOUT:
			omap5912_io.gpio[2].gpio_clear_dataout = data;
			break;
		case GPIO3_SET_IRQENABLE1:
			omap5912_io.gpio[2].gpio_set_irqenable1 = data;
			break;
		case GPIO3_SET_IRQENABLE2:
			omap5912_io.gpio[2].gpio_set_irqenable2 = data;
			break;
		case GPIO3_SET_WAKEUPENA:
			omap5912_io.gpio[2].gpio_set_wakeupena = data;
			break;
		case GPIO3_SET_DATAOUT:
			omap5912_io.gpio[2].gpio_set_dataout = data;
			break;	
		/** gpio4*/
		case GPIO4_SYSCONFIG:
			omap5912_io.gpio[3].gpio_sysconfig = data;
			break;
		case GPIO4_IRQSTATUS1:
			omap5912_io.gpio[3].gpio_irqstatus1 = data;
			break;
		case GPIO4_IRQENABLE1:
			omap5912_io.gpio[3].gpio_irqenable1 = data;
			break;
		case GPIO4_IRQSTATUS2:
			omap5912_io.gpio[3].gpio_irqstatus2 = data;
			break;
		case GPIO4_IRQENABLE2:
			omap5912_io.gpio[3].gpio_irqenable2 = data;
			break;
		case GPIO4_WAKEUPENABLE:
			omap5912_io.gpio[3].gpio_wakeupenable = data;
			break;
		case GPIO4_DATAOUT:
			omap5912_io.gpio[3].gpio_dataout = data;
			break;
		case GPIO4_DIRECTION:
			omap5912_io.gpio[3].gpio_direction = data;
			break;
		case GPIO4_EDGE_CTRL1:
			omap5912_io.gpio[3].gpio_edge_ctrl1 = data;
			break;
		case GPIO4_EDGE_CTRL2:
			omap5912_io.gpio[3].gpio_edge_ctrl2 = data;
			break;
		case GPIO4_CLEAR_IRQENABLE1:
			omap5912_io.gpio[3].gpio_clear_irqenable1 = data;
			break;
		case GPIO4_CLEAR_IRQENABLE2:
			omap5912_io.gpio[3].gpio_clear_irqenable2 = data;
			break;
		case GPIO4_CLEAR_WAKEUPENA:
			omap5912_io.gpio[3].gpio_clear_wakeupena = data;
			break;
		case GPIO4_CLEAR_DATAOUT:
			omap5912_io.gpio[3].gpio_clear_dataout = data;
			break;
		case GPIO4_SET_IRQENABLE1:
			omap5912_io.gpio[3].gpio_set_irqenable1 = data;
			break;
		case GPIO4_SET_IRQENABLE2:
			omap5912_io.gpio[3].gpio_set_irqenable2 = data;
			break;
		case GPIO4_SET_WAKEUPENA:
			omap5912_io.gpio[3].gpio_set_wakeupena = data;
			break;
		case GPIO4_SET_DATAOUT:
			omap5912_io.gpio[3].gpio_set_dataout = data;
			break;	
		case ULPD_CLOCK_CTRL:
			omap5912_io.mpu_cfg.ulpd_clock_ctrl = data;
			break;
		case SOFT_REQ_REG:
		 	omap5912_io.mpu_cfg.soft_req_reg = data;
			break;
		case SOFT_REQ_REG2:
		 	omap5912_io.mpu_cfg.soft_req_reg2 = data;
			break;
		case MOD_CONF_CTRL_0:
			omap5912_io.mpu_cfg.mod_conf_ctrl_0 = data;
			break;
		case FUNC_MUX_CTRL_10:
			omap5912_io.mpu_cfg.func_mux_ctrl_10 = data;
			break;
		case PULL_DWN_CTRL_4:
			omap5912_io.mpu_cfg.pull_dwn_ctrl_4 = data; 
			break;
		case EMIFS_CS1_CONFIG:
			omap5912_io.mpu_cfg.emifs_cs1_config = data;
			break;
		case ARM_CKCTL:
			omap5912_io.mpu_cfg.arm_ckctl = data;
			break;
		case ARM_IDLECT1:
			omap5912_io.mpu_cfg.arm_idlect1 = data;
			break;
		case ARM_IDLECT2:
			omap5912_io.mpu_cfg.arm_idlect2 = data;
			break;
		case ARM_RSTCT1:
			omap5912_io.mpu_cfg.arm_rstct1 = data;
			break;
		case ARM_RSTCT2:
			omap5912_io.mpu_cfg.arm_rstct2 = data;
			break;
		case ARM_SYSST:
			omap5912_io.mpu_cfg.arm_sysst = data;
			break;
		case DPLL1_CTL_REG:
			omap5912_io.mpu_cfg.dpll1_ctl_reg = data;
			break;

		default:
			//SKYEYE_DBG ("io_write_word(0x%08x) = 0x%08x\n", addr, data);
        	       //fprintf(stderr, "ERROR: %s(0x%08x) = 0x%08x\n", __FUNCTION__, addr ,data);
			break;
	}//?switch_end
	return;
			 
}

void
omap5912_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	return omap5912_io_write_word(state, addr, (data & 0xff));
	//return omap5912_io_write_word(state, addr, data);
}

void
omap5912_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	return omap5912_io_write_word(state, addr, (data & 0xffff));
	//return omap5912_io_write_word(state, addr, data);
}



ARMword
omap5912_io_read_word (ARMul_State * state, ARMword addr)
{
	ARMword data = -1;

	if ((addr >= UART1_RHR) && (addr <= UART1_WER))
	{
		switch(addr)
		{
				/**uart 1*/
		case UART1_RHR:
		//	omap5912_io.uart.iir &= ~(0x1);
			data = omap5912_io.uart.rhr & 0xff;

			omap5912_io.uart.lsr = (0x1);
			//printf("read_uart, read_num%x %x\n", data, read_num);
			//printf("uart1_lsr read %x\n", omap5912_io.uart.lsr);
			//data = omap5912_io.uart.dll;
			break;
		case UART1_IER:
			data = omap5912_io.uart.ier;
		//	printf("uart1_ier read %x\n", data);
			//data = omap5912_io.uart.dlh;
			break;
		case UART1_IIR:
			data = omap5912_io.uart.iir;
		//	omap5912_io.uart.lsr = 0x20;
		//	omap5912_io.uart.iir = 0x1;
		//	omap5912_io.uart.iir = 0x0;
		//printf("uart1_iir read %x\n", data);
			//data = omap5912_io.uart.efr;
			break;
		case UART1_LCR:
			data = omap5912_io.uart.lcr;
			//printf("uart1_lcr read %x\n", data);
			break;
		case UART1_MCR:
			data = omap5912_io.uart.mcr;
			//printf("uart1_mcr read %x\n", data);
			//data = omap5912_io.uart.xon1;
			break;
		case UART1_LSR:
			data = omap5912_io.uart.lsr;
			//	data = omap5912_io.uart.xon2;
			if (data & 0x60)
			{
				//omap5912_io.uart.iir = THR_INT;
				//omap5912_io.uart.ier = 0x2;
			}
			if (data & 0x1)
			{
				//omap5912_io.uart.iir = RHR_INT;
				//omap5912_io.uart.ier = 0x2;
			}

		//	printf("uart1_lsr read %x\n", data);
			break;
		case UART1_MSR:
			data = omap5912_io.uart.msr;
			//printf("uart1_msr read %x\n", data);
			//data = omap5912_io.uart.tcr;
			//data = omap5912_io.uart.xoff1;
			break;
		case UART1_SPR:
			data = omap5912_io.uart.spr;
			//data = omap5912_io.uart.tlr;
			//data = omap5912_io.uart.xoff2;
			break;
		case UART1_MDR1:
			data = omap5912_io.uart.mdr1;
			break;
		case UART1_MDR2:
			data = omap5912_io.uart.mdr2;
			break;
		case UART1_SFLSR:
			data = omap5912_io.uart.sflsr;
			break;
		case UART1_RESUME:
			data = omap5912_io.uart.resume;
			break;
		case UART1_SFREGL:
			data = omap5912_io.uart.sfregl;
			break;
		case UART1_SFREGH:
			data = omap5912_io.uart.sfregh;
			break;
		case UART1_UASR:
			data = omap5912_io.uart.uasr;
			//data = omap5912_io.uart.blr;
			break;
		case UART1_ACREG:
			data = omap5912_io.uart.acreg;
			break;
		case UART1_SCR:
			data = omap5912_io.uart.scr;
			break;
		case UART1_SSR:
			data = omap5912_io.uart.ssr;
			break;
		case UART1_EBLR:
			data = omap5912_io.uart.eblr;
			break;
		case UART1_MVR:
			data = omap5912_io.uart.mvr;
			break;
		case UART1_SYSC:
			data = omap5912_io.uart.sysc;
			break;
		case UART1_SYSS:
			data = omap5912_io.uart.syss;
			break;
		case UART1_WER:
			data = omap5912_io.uart.wer;
			break;
		default:
			break;
		}//?endswitch	
		return data;
	}
	if ((addr >= MPU_L1_ILR0) && (addr <=MPU_L1_ILR31))
	{
		int offset = (addr - MPU_L1_ILR0)/4;
		//printf("read mpu l1 ilr[%d] 0x%x\n",offset,omap5912_io.ic.mpu_l1_ilr[offset]);
		return omap5912_io.ic.mpu_l1_ilr[offset];
	}
	if ((addr >= MPU_L2_ILR0) && (addr <=MPU_L2_ILR31))
	{
		int offset = (addr - MPU_L2_ILR0)/4;
		return omap5912_io.ic.mpu_l2_ilr[offset];
	}

	if ((addr >= MPU_L2_ILR0_S1) && (addr <=MPU_L2_ILR31_S1))
	{
		int offset = (addr - MPU_L2_ILR0_S1)/4;
		return omap5912_io.ic.mpu_l2_ilr_s1[offset];
	}
	if ((addr >= MPU_L2_ILR0_S2) && (addr <=MPU_L2_ILR31_S2))
	{
		int offset = (addr - MPU_L2_ILR0_S2)/4;
		return omap5912_io.ic.mpu_l2_ilr_s2[offset];
	}
	if ((addr >= MPU_L2_ILR0_S3) && (addr <=MPU_L2_ILR31_S3))
	{
		int offset = (addr - MPU_L2_ILR0_S3)/4;
		return omap5912_io.ic.mpu_l2_ilr_s3[offset];
	}

	switch (addr) { 
		/*os timer*/
		case OS_TIMER_TICK_VAL:
			data = omap5912_io.os_timer.os_timer_tick_val * (0x00ffffff);
			break;
		case OS_TIMER_TICK_CNTR:
			data = omap5912_io.os_timer.os_timer_tick_cntr & (0x00ffffff);
			printf("os timer tick count value\n");
			break;
		case OS_TIMER_CTRL:
			data = omap5912_io.os_timer.os_timer_ctrl;
			printf("os timer control%x\n", data);
			break;
		case TIMER_32K_SYNCHRONIZED:
			data = omap5912_io.timer_32k_synchronized;
			//printf("32k synchronized%x\n", data);
			break;
		/*mpu timer*/
		case MPU_CNTL_TIMER1: 
			data = omap5912_io.timer.mpu_cntl_timer[0];
			//printf("timer 1 read control %x\n", omap5912_io.timer.mpu_cntl_timer[0]);
			break;
		case MPU_READ_TIMER1:
			data = omap5912_io.timer.mpu_read_timer[0];
			//printf("timer 1 read %x\n", data);
			break;
		case MPU_CNTL_TIMER2: 
			data = omap5912_io.timer.mpu_cntl_timer[1];
			//printf("timer 2 read control %x\n", omap5912_io.timer.mpu_cntl_timer[1]);
			break;
		case MPU_READ_TIMER2:
			data = omap5912_io.timer.mpu_read_timer[1];
			//printf("timer 2 read %x\n", data);
			break;
		case MPU_CNTL_TIMER3: 
			data = omap5912_io.timer.mpu_cntl_timer[2];
			break;
		case MPU_READ_TIMER3:
			data = omap5912_io.timer.mpu_read_timer[2];
			break;
		/**interrupt controller*/
		case MPU_L2_ITR:
			data = omap5912_io.ic.mpu_l2_itr;
			//printf("read mpu l2 itr %x\n",data);
			break;
		case MPU_L2_MIR:
			data = omap5912_io.ic.mpu_l2_mir;
			//printf("readmpu l2 mir %x\n",data);
			break;
		case MPU_L2_SIR_IRQ:
			data = omap5912_io.ic.mpu_l2_sir_irq;
			//omap5912_update_l2_int(state);
			//printf("read mpu l2 sir irq %d\n",data);
			break;
		case MPU_L2_SIR_FIQ:
			data = omap5912_io.ic.mpu_l2_sir_fiq;
			break;
		case MPU_L2_CONTROL:
			data = omap5912_io.ic.mpu_l2_control;
			break;
		case MPU_L2_STATUS:
			data = omap5912_io.ic.mpu_l2_status;
			break;
		case MPU_L2_OCP_CFG:
			data = omap5912_io.ic.mpu_l2_ocp_cfg;
			break;
		case MPU_L1_ITR:
			data = omap5912_io.ic.mpu_l1_itr;
			break;
		case MPU_L1_MIR:
			data = omap5912_io.ic.mpu_l1_mir;
			//printf("mpul1 mir read %x\n", data);
			break;
		case MPU_L1_SIR_IRQ_CODE:
			data = omap5912_io.ic.mpu_l1_sir_irq_code;
			//printf("mpul1 sir_irq code read %x\n", data);
			break;
		case MPU_L1_SIR_FIQ_CODE:
			data = omap5912_io.ic.mpu_l1_sir_fiq_code;
			//omap5912_io.ic.mpu_l1_itr &= ~(1 << data);
			break;
		case MPU_L1_CONTROL:
			data = omap5912_io.ic.mpu_l1_control;
			//printf("mpul1 control read %x\n", data);
			break;
		case MPU_L1_ISR:
			data = omap5912_io.ic.mpu_l1_isr;
			//printf(" mpul1_isr %x \n", data);
			break;
		case MPU_L1_ENHANCEED_CNTL:
			data = omap5912_io.ic.mpu_l1_enhanceed_cntl;
			break;
		/** gpio1*/
		case GPIO1_REVISION:
			data = omap5912_io.gpio[0].gpio_reversion;
			break;
		case GPIO1_SYSSTATUS:
			data = omap5912_io.gpio[0].gpio_sysstatus;
			break;
		case GPIO1_SYSCONFIG:
			data = omap5912_io.gpio[0].gpio_sysconfig;
			break;
		case GPIO1_IRQSTATUS1:
			data = omap5912_io.gpio[0].gpio_irqstatus1;
			break;
		case GPIO1_IRQENABLE1:
			data = omap5912_io.gpio[0].gpio_irqenable1;
			break;
		case GPIO1_IRQSTATUS2:
			data = omap5912_io.gpio[0].gpio_irqstatus2;
			break;
		case GPIO1_IRQENABLE2:
			data = omap5912_io.gpio[0].gpio_irqenable2;
			break;
		case GPIO1_WAKEUPENABLE:
			data = omap5912_io.gpio[0].gpio_wakeupenable;
			break;
		case GPIO1_DATAIN:
			data = omap5912_io.gpio[0].gpio_datain;
			break;
		case GPIO1_DATAOUT:
			data = omap5912_io.gpio[0].gpio_dataout;
			break;
		case GPIO1_DIRECTION:
			data = omap5912_io.gpio[0].gpio_direction;
			break;
		case GPIO1_EDGE_CTRL1:
			data = omap5912_io.gpio[0].gpio_edge_ctrl1;
			break;
		case GPIO1_EDGE_CTRL2:
			data = omap5912_io.gpio[0].gpio_edge_ctrl2;
			break;
		case GPIO1_CLEAR_IRQENABLE1:
			data = omap5912_io.gpio[0].gpio_clear_irqenable1;
			break;
		case GPIO1_CLEAR_IRQENABLE2:
			data = omap5912_io.gpio[0].gpio_clear_irqenable2;
			break;
		case GPIO1_CLEAR_WAKEUPENA:
			data = omap5912_io.gpio[0].gpio_clear_wakeupena;
			break;
		case GPIO1_CLEAR_DATAOUT:
			data = omap5912_io.gpio[0].gpio_clear_dataout;
			break;
		case GPIO1_SET_IRQENABLE1:
			data = omap5912_io.gpio[0].gpio_set_irqenable1;
			break;
		case GPIO1_SET_IRQENABLE2:
			data = omap5912_io.gpio[0].gpio_set_irqenable2;
			break;
		case GPIO1_SET_WAKEUPENA:
			data = omap5912_io.gpio[0].gpio_set_wakeupena;
			break;
		case GPIO1_SET_DATAOUT:
			data = omap5912_io.gpio[0].gpio_set_dataout;
			break;	
		/** gpio2*/
		case GPIO2_REVISION:
			data = omap5912_io.gpio[1].gpio_reversion;
			break;
		case GPIO2_SYSSTATUS:
			data = omap5912_io.gpio[1].gpio_sysstatus;
			break;
		case GPIO2_SYSCONFIG:
			data = omap5912_io.gpio[1].gpio_sysconfig;
			break;
		case GPIO2_IRQSTATUS1:
			data = omap5912_io.gpio[1].gpio_irqstatus1;
			break;
		case GPIO2_IRQENABLE1:
			data = omap5912_io.gpio[1].gpio_irqenable1;
			break;
		case GPIO2_IRQSTATUS2:
			data = omap5912_io.gpio[1].gpio_irqstatus2;
			break;
		case GPIO2_IRQENABLE2:
			data = omap5912_io.gpio[1].gpio_irqenable2;
			break;
		case GPIO2_WAKEUPENABLE:
			data = omap5912_io.gpio[1].gpio_wakeupenable;
			break;
		case GPIO2_DATAIN:
			data = omap5912_io.gpio[1].gpio_datain;
			break;
		case GPIO2_DATAOUT:
			data = omap5912_io.gpio[1].gpio_dataout;
			break;
		case GPIO2_DIRECTION:
			data = omap5912_io.gpio[1].gpio_direction;
			break;
		case GPIO2_EDGE_CTRL1:
			data = omap5912_io.gpio[1].gpio_edge_ctrl1;
			break;
		case GPIO2_EDGE_CTRL2:
			data = omap5912_io.gpio[1].gpio_edge_ctrl2;
			break;
		case GPIO2_CLEAR_IRQENABLE1:
			data = omap5912_io.gpio[1].gpio_clear_irqenable1;
			break;
		case GPIO2_CLEAR_IRQENABLE2:
			data = omap5912_io.gpio[1].gpio_clear_irqenable2;
			break;
		case GPIO2_CLEAR_WAKEUPENA:
			omap5912_io.gpio[1].gpio_clear_wakeupena;
			break;
		case GPIO2_CLEAR_DATAOUT:
			data = omap5912_io.gpio[1].gpio_clear_dataout;
			break;
		case GPIO2_SET_IRQENABLE1:
			data = omap5912_io.gpio[1].gpio_set_irqenable1;
			break;
		case GPIO2_SET_IRQENABLE2:
			data = omap5912_io.gpio[1].gpio_set_irqenable2;
			break;
		case GPIO2_SET_WAKEUPENA:
			data = omap5912_io.gpio[1].gpio_set_wakeupena;
			break;
		case GPIO2_SET_DATAOUT:
			data = omap5912_io.gpio[1].gpio_set_dataout;
			break;	
		/** gpio2*/
		case GPIO3_REVISION:
			data = omap5912_io.gpio[2].gpio_reversion;
			break;
		case GPIO3_SYSSTATUS:
			data = omap5912_io.gpio[2].gpio_sysstatus;
			break;
		case GPIO3_SYSCONFIG:
			data = omap5912_io.gpio[2].gpio_sysconfig;
			break;
		case GPIO3_IRQSTATUS1:
			data = omap5912_io.gpio[2].gpio_irqstatus1;
			break;
		case GPIO3_IRQENABLE1:
			data = omap5912_io.gpio[2].gpio_irqenable1;
			break;
		case GPIO3_IRQSTATUS2:
			data = omap5912_io.gpio[2].gpio_irqstatus2;
			break;
		case GPIO3_IRQENABLE2:
			data = omap5912_io.gpio[2].gpio_irqenable2;
			break;
		case GPIO3_WAKEUPENABLE:
			data = omap5912_io.gpio[2].gpio_wakeupenable;
			break;
		case GPIO3_DATAIN:
			data = omap5912_io.gpio[2].gpio_datain;
			break;
		case GPIO3_DATAOUT:
			data = omap5912_io.gpio[2].gpio_dataout;
			break;
		case GPIO3_DIRECTION:
			data = omap5912_io.gpio[2].gpio_direction;
			break;
		case GPIO3_EDGE_CTRL1:
			data = omap5912_io.gpio[2].gpio_edge_ctrl1;
			break;
		case GPIO3_EDGE_CTRL2:
			data = omap5912_io.gpio[2].gpio_edge_ctrl2;
			break;
		case GPIO3_CLEAR_IRQENABLE1:
			data = omap5912_io.gpio[2].gpio_clear_irqenable1;
			break;
		case GPIO3_CLEAR_IRQENABLE2:
			data = omap5912_io.gpio[2].gpio_clear_irqenable2;
			break;
		case GPIO3_CLEAR_WAKEUPENA:
			data = omap5912_io.gpio[2].gpio_clear_wakeupena;
			break;
		case GPIO3_CLEAR_DATAOUT:
			data = omap5912_io.gpio[2].gpio_clear_dataout;
			break;
		case GPIO3_SET_IRQENABLE1:
			data = omap5912_io.gpio[2].gpio_set_irqenable1;
			break;
		case GPIO3_SET_IRQENABLE2:
			data = omap5912_io.gpio[2].gpio_set_irqenable2;
			break;
		case GPIO3_SET_WAKEUPENA:
			data =omap5912_io.gpio[2].gpio_set_wakeupena;
			break;
		case GPIO3_SET_DATAOUT:
			data = omap5912_io.gpio[2].gpio_set_dataout;
			break;	
		/** gpio4*/
		case GPIO4_REVISION:
			data = omap5912_io.gpio[3].gpio_reversion;
			break;
		case GPIO4_SYSSTATUS:
			data = omap5912_io.gpio[3].gpio_sysstatus;
			break;

		case GPIO4_SYSCONFIG:
			data = omap5912_io.gpio[3].gpio_sysconfig;
			break;
		case GPIO4_IRQSTATUS1:
			data = omap5912_io.gpio[3].gpio_irqstatus1;
			break;
		case GPIO4_IRQENABLE1:
			data = omap5912_io.gpio[3].gpio_irqenable1;
			break;
		case GPIO4_IRQSTATUS2:
			data = omap5912_io.gpio[3].gpio_irqstatus2;
			break;
		case GPIO4_IRQENABLE2:
			data = omap5912_io.gpio[3].gpio_irqenable2;
			break;
		case GPIO4_WAKEUPENABLE:
			data = omap5912_io.gpio[3].gpio_wakeupenable;
			break;
		case GPIO4_DATAIN:
			data = omap5912_io.gpio[3].gpio_datain;
			break;
		case GPIO4_DATAOUT:
			data = omap5912_io.gpio[3].gpio_dataout;
			break;
		case GPIO4_DIRECTION:
			data = omap5912_io.gpio[3].gpio_direction;
			break;
		case GPIO4_EDGE_CTRL1:
			data = omap5912_io.gpio[3].gpio_edge_ctrl1;
			break;
		case GPIO4_EDGE_CTRL2:
			data = omap5912_io.gpio[3].gpio_edge_ctrl2;
			break;
		case GPIO4_CLEAR_IRQENABLE1:
			data= omap5912_io.gpio[3].gpio_clear_irqenable1;
			break;
		case GPIO4_CLEAR_IRQENABLE2:
			data = omap5912_io.gpio[3].gpio_clear_irqenable2;
			break;
		case GPIO4_CLEAR_WAKEUPENA:
			data = omap5912_io.gpio[3].gpio_clear_wakeupena;
			break;
		case GPIO4_CLEAR_DATAOUT:
			data = omap5912_io.gpio[3].gpio_clear_dataout;
			break;
		case GPIO4_SET_IRQENABLE1:
			data = omap5912_io.gpio[3].gpio_set_irqenable1;
			break;
		case GPIO4_SET_IRQENABLE2:
			data = omap5912_io.gpio[3].gpio_set_irqenable2;
			break;
		case GPIO4_SET_WAKEUPENA:
			data = omap5912_io.gpio[3].gpio_set_wakeupena;
			break;
		case GPIO4_SET_DATAOUT:
			data = omap5912_io.gpio[3].gpio_set_dataout;
			break;	
		case ULPD_CLOCK_CTRL:
			data = omap5912_io.mpu_cfg.ulpd_clock_ctrl;
			break;
		case SOFT_REQ_REG:
		 	data = omap5912_io.mpu_cfg.soft_req_reg;
			break;
		case SOFT_REQ_REG2:
		 	data = omap5912_io.mpu_cfg.soft_req_reg2;
			break;
		case MOD_CONF_CTRL_0:
			data = omap5912_io.mpu_cfg.mod_conf_ctrl_0;
			break;
		case FUNC_MUX_CTRL_10:
			data = omap5912_io.mpu_cfg.func_mux_ctrl_10;
			break;
		case PULL_DWN_CTRL_4:
			data = omap5912_io.mpu_cfg.pull_dwn_ctrl_4;
			break;
		case EMIFS_CS1_CONFIG:
			data = omap5912_io.mpu_cfg.emifs_cs1_config;
			break;
		case DIE_ID_LSB:
			data = omap5912_io.mpu_cfg.die_id_lsb;
			break;
		case DIE_ID_MSB:
			data = omap5912_io.mpu_cfg.die_id_msb;
			break;
		case PROD_ID_REG0:
			data = omap5912_io.mpu_cfg.prod_id_reg0;
			break;
		case PROD_ID_REG1:
			data = omap5912_io.mpu_cfg.prod_id_reg1;
			break;
		case ARM_CKCTL:
			data = omap5912_io.mpu_cfg.arm_ckctl;
			break;
		case ARM_IDLECT1:
			data = omap5912_io.mpu_cfg.arm_idlect1;
			break;
		case ARM_IDLECT2:
			data = omap5912_io.mpu_cfg.arm_idlect2;
			break;
		case ARM_RSTCT1:
			data = omap5912_io.mpu_cfg.arm_rstct1;
			break;
		case ARM_RSTCT2:
			data = omap5912_io.mpu_cfg.arm_rstct2;
			break;
		case ARM_SYSST:
			data = omap5912_io.mpu_cfg.arm_sysst;
			break;
		case DPLL1_CTL_REG:
			data = omap5912_io.mpu_cfg.dpll1_ctl_reg;
			break;

		default:
			//fprintf(stderr, "ERROR: %s(0x%08x) \n", __FUNCTION__, addr);
			data = -1;
			break;
	}//?switch_end
	
	return data;

}

ARMword
omap5912_io_read_byte (ARMul_State * state, ARMword addr)
{
	
	return (omap5912_io_read_word(state, addr) & 0xff);
}

ARMword
omap5912_io_read_halfword (ARMul_State * state, ARMword addr)
{
	return (omap5912_io_read_word(state, addr) & 0xffff);
}


void
omap5912_mach_init (ARMul_State * state, machine_config_t * mc)
{
	//chy 2003-08-19, setprocessor
	ARMul_SelectProcessor (state, ARM_v5_Prop | ARM_v5e_Prop);
	//chy 2004-05-09, set lateabtSig
	state->lateabtSig = LOW;

	state->Reg[1] = 515;	/*mainstone machine id. */
	omap5912_io_reset ();

	mc->mach_io_do_cycle = omap5912_io_do_cycle;
	mc->mach_io_reset = omap5912_io_reset;
	mc->mach_io_read_byte = omap5912_io_read_byte;
	mc->mach_io_write_byte = omap5912_io_write_byte;
	mc->mach_io_read_halfword = omap5912_io_read_halfword;
	mc->mach_io_write_halfword = omap5912_io_write_halfword;
	mc->mach_io_read_word = omap5912_io_read_word;
	mc->mach_io_write_word = omap5912_io_write_word;
	mc->mach_update_int = omap5912_update_int;

	mc->mach_set_intr = omap_set_intr;
	mc->mach_pending_intr = omap_pending_intr;
	mc->mach_update_intr = omap_update_intr;

	mc->state = (void *) state;
}
