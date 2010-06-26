CROSS_COMPILE ?=
EXTRA_CFLAGS ?=

TOPSRCDIR	= ..
BUILD		= tracer.o
C_SRCS		= main.c


CC	= $(CROSS_COMPILE)gcc
CFLAGS	= -Wall -fomit-frame-pointer -g -O2 -I$(TOPSRCDIR) $(EXTRA_CFLAGS)

LD_R	= $(CROSS_COMPILE)ld -r
RM	= rm -f
LDFLAGS = 

OBJS = $(C_SRCS:.c=.o)

all: $(BUILD)

.c.o:
	$(CC) $(CFLAGS) -c $<

clean:
	$(RM) $(OBJS) $(BUILD) 

generated.channels.h:
	./mktracech.sh ..

distclean:
	$(RM) generated.channels.h

$(BUILD): generated.channels.h $(OBJS)
	$(LD_R) $(OBJS) -o $@

# Deps
tracer.o: generated.channels.h main.c tracer.h 

