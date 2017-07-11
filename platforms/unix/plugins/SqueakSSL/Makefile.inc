#XLDFLAGS=	-lcrypto -lssl
XLDFLAGS=	-Wl,--no-as-needed -lrt -Wl,-Bstatic -lcrypto -lssl -Wl,-Bdynamic -lrt
