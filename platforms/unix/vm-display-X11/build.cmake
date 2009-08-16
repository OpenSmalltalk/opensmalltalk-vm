INCLUDE_DIRECTORIES (
    ${cross}/plugins/B3DAcceleratorPlugin
    ${cross}/plugins/FilePlugin
    /usr/X11R6/include
    /usr/X11R7/include
)
TARGET_LINK_LIBRARIES (@plugin@
    ${X11_LIBRARIES}
    -L/usr/X11/lib
    GL
)
EXPECT_UNDEFINED_SYMBOLS ()
