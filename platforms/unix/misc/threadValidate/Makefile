INCLUDES=-I. -I../../../Cross/vm -I../../../../src/vm -I../../vm
# __USE_GNU declares pthread_yield
CFLAGS=-g2 -O1 -msse2 -Wall -D_GNU_SOURCE
LDFLAGS=-lpthread

all: testi testt

testi: sqTicker.c sqUnixHeartbeat.c threadValidate.c
	cc -o $@ -DITIMER_HEARTBEAT=1 -DYIELD_IN_TICKER $(CFLAGS) $(INCLUDES) $^ $(LDFLAGS)

testt: sqTicker.c sqUnixHeartbeat.c threadValidate.c
	cc -o $@ -DONLY_ONE_THREAD_PRIORITY=1 $(CFLAGS) $(INCLUDES) $^ $(LDFLAGS)
