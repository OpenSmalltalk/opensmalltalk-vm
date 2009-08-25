# B3DAccel depends on the main display plugin having GL (vm-display-X11) or AGL
# (vm-display-Quartz) as a dependency.  This lets 3D work in both X11 and Quartz
# on MacOS.

EXPECT_UNDEFINED_SYMBOLS ()
