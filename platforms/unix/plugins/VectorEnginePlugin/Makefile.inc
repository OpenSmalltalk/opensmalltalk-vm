# Disable compiler optimization. Adding this to XCFLAGS will effectively
# override any previous definition of -O in CFLAGS
XCFLAGS=$(X_CFLAGS) -O0
