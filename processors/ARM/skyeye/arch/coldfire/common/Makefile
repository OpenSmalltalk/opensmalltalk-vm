CROSS_COMPILE ?=
EXTRA_CFLAGS ?=

CC = $(CROSS_COMPILE)gcc -g
CFLAGS := $(CFLAGS) $(EXTRA_CFLAGS)

coldfire:memory.o addressing.o i.o cycle.o handlers.o exception.o ../tracer/tracer.o board.o ram.o
memory.o:memory.c
	$(CC) $(CFLAGS) -c -I../tracer memory.c
addressing.o:addressing.c
	$(CC) $(CFLAGS) -c -I../tracer addressing.c
i.o:i.c
	$(CC) $(CFLAGS) -c -I../tracer i.c
cycle.o:cycle.c
	$(CC) $(CFLAGS) -c -I../tracer cycle.c
handlers.o:handlers.c
	$(CC) $(CFLAGS) -c -I../tracer handlers.c
exception.o:exception.c
	$(CC) $(CFLAGS) -c -I../tracer exception.c
board.o:board.c
	$(CC) $(CFLAGS) -c -I../tracer board.c
ram.o:ram.c
	$(CC) $(CFLAGS) -c -I../tracer ram.c
clean:
	rm -f *.o 
