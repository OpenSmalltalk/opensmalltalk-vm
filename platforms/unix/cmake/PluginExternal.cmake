ADD_LIBRARY (@plugin@ MODULE @plugin_sources@)
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
