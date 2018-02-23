#
# C99 can drive a car by now.
CC=c99
#
#
XLDFLAGS=	-ldl
#
# For platform builds, use

#XLDFLAGS=	-lcrypto -lssl
#XCFLAGS=	-DSQSSL_OPENSSL_LINKED

# otherwise the OpenSSL libs will be looked up at runtime.
#
#
