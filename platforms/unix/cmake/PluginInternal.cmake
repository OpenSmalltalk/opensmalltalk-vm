ADD_LIBRARY (@plugin@ STATIC @plugin_sources@)
ADD_DEFINITIONS (-DSQUEAK_BUILTIN_PLUGIN=1)
INCLUDE_DIRECTORIES (
    ${bld}
    ${src}/vm
    ${cross}/vm
    ${src}/plugins/@plugin@
    ${src}/vm/intplugins/@plugin@
    ${unix}/vm
    ${unix}/plugins/@plugin@
    ${unix}/@plugin@
    ${cross}/plugins/@plugin@
)
