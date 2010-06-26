#
# top level directory for RTEMS build tree
#
##
## $Id: Makefile.am,v 1.39.2.3 2007/02/22 12:13:33 ralf Exp $
##

INCLUDES = -I./ -I$(top_srcdir)/arch/arm -I$(top_srcdir)/arch/arm/common @COMMON_INCLUDES@


dev_uart = uart/skyeye_uart.c          uart/skyeye_uart_net.c   uart/skyeye_uart_stdio.c \
uart/skyeye_uart_cvt_dcc.c  uart/skyeye_uart_pipe.c
dev_flash = flash/armflash.c  flash/dev_flash_sst39lvf160.c \
flash/dev_flash_am29.c  flash/dev_flash_intel.c  flash/skyeye_flash.c
dev_nandflash = nandflash/dev_nandflash_s3c2410.c  nandflash/nandflash_smallblock.c  nandflash/skyeye_nandflash.c
dev_sound = sound/dev_sound_s3c44b0x.c  sound/skyeye_sound.c  sound/skyeye_sound_pcm.c
dev_lcd = lcd/dev_lcd_au1100.c  lcd/dev_lcd_s3c2410.c   lcd/skyeye_lcd.c \
lcd/dev_lcd_ep7312.c  lcd/dev_lcd_s3c44b0x.c lcd/dev_lcd_pxa.c
dev_net = net/dev_net_cs8900a.c  net/dev_net_s3c4510b.c net/skyeye_net_tuntap.c \
net/dev_net_rtl8019.c  net/skyeye_net.c    net/skyeye_net_vnet.c
dev_ts = touchscreen/dev_touchscreen_skyeye.c  touchscreen/skyeye_touchscreen.c
libdev_a_SOURCES = skyeye_device.c $(dev_uart) $(dev_flash) $(dev_nandflash) $(dev_sound) $(dev_net) $(dev_ts)

DEFS = -DMODET -g -O2 -D_FILE_OFFSET_BITS=64 -DSTANDALONE -DDEFAULT_INLINE=0 

if LCD
libdev_a_SOURCES += $(dev_lcd)
INCLUDES += @LCD_CFLAGS@
if GTK_LCD
libdev_a_SOURCES += lcd/skyeye_lcd_gtk.c
endif # GTK_LCD
if WIN32_LCD
libdev_a_SOURCES += lcd/skyeye_lcd_win32.c
endif # WIN32_LCD
endif # LCD

noinst_LIBRARIES =      libdev.a

