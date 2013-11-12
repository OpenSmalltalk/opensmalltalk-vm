ADD_DEFINITIONS (-DSQUEAK_BUILTIN_PLUGIN=1 ${@plugin@_definitions})
LINK_DIRECTORIES (${@plugin@_link_directories})
INCLUDE_DIRECTORIES (${@plugin@_include_directories}
    ${bld}
    ${src}/vm
    ${cross}/vm
    ${src}/plugins/@plugin@
    ${unix}/vm
    ${unix}/plugins/@plugin@
    ${unix}/@plugin@
    ${cross}/plugins/@plugin@
)

ADD_LIBRARY (@plugin@ STATIC @plugin_sources@)
