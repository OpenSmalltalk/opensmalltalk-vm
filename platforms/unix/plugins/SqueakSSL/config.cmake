#
# For platform builds, use

# PLUGIN_REQUIRE_PACKAGE (OPENSSL openssl)
# add_definitions(-DSQSSL_OPENSSL_LINKED) 

# otherwise the OpenSSL libs will be looked up at runtime.
#
#