# Spur VM with VM profiler and threaded heartbeat
FLAVORS = debug assert itimerheartbeat immutability
INSTALLDIR=sqcogspur64linuxht
GCCVERSION := $(shell gcc -dumpversion | cut -d. -f1-2)

WRKDIR = $(CURDIR)/work
ifeq "$(findstring debug, $(FLAVOR))" "debug"
CFLAGS += -g3 -O0 -DDEBUGVM=1
WRKDIR := $(WRKDIR)-debug
INSTALLDIR := debug/$(INSTALLDIR)
else ifeq "$(findstring assert, $(FLAVOR))" "assert"
CFLAGS += -g3 -O1 -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -DDEBUGVM=0
WRKDIR := $(WRKDIR)-assert
INSTALLDIR := assert/$(INSTALLDIR)
else
CFLAGS += -g -DDEBUGVM=0 -DNDEBUG
# Some gcc versions create a broken VM using -O2
ifeq "$(GCCVERSION)" "3.4"
CFLAGS += -O1 -fwrapv
else
CFLAGS += -O2
INSTALLDIR := $(INSTALLDIR)
endif
endif

ifeq "$(findstring itimerheartbeat, $(FLAVOR))" "itimerheartbeat"
CFLAGS += -DITIMER_HEARTBEAT=1
WRKDIR := $(WRKDIR)-itimerheartbeat
INSTALLDIR := $(INSTALLDIR:ht=)
endif

ifeq "$(findstring immutability, $(FLAVOR))" "immutability"
CFLAGS += -DIMMUTABLITY=1
WRKDIR := $(WRKDIR)-immutability
endif

build: configure
	cd $(WRKDIR) && make

configure: $(WRKDIR)/.configure-done

$(WRKDIR)/.configure-done:
	mkdir -p $(WRKDIR)
	cp plugins.int plugins.ext $(WRKDIR)
	cd $(WRKDIR) && \
	../../platforms/unix/config/configure \
		--without-npsqueak \
		--with-vmversion=5.0 \
		--with-src=spur64src \
		CC="gcc -m64" \
		CXX="g++ -m64" \
		CFLAGS="$(CFLAGS) -msse2 -D_GNU_SOURCE -DCOGMTVM=0" \
		LIBS="-lpthread -luuid" \
		LDFLAGS=-Wl,-z,now && \
	touch $@

install:
	cd $(WRKDIR) && $(MAKE) install-squeak install-plugins prefix=`(cd ../../;pwd)`/products/$(INSTALLDIR) 2>&1 | tee LOG

all:
	make &
	FLAVOR=debug make &
	FLAVOR=assert make &
	FLAVOR=itimerheartbeat make &
	FLAVOR="debug itimerheartbeat" make &
	FLAVOR="assert itimerheartbeat" make &

clean:
	rm -rf $(WRKDIR)
