ADD_DEFINITIONS (${@plugin@_definitions})
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

ADD_LIBRARY (@plugin@ MODULE @plugin_sources@)

TARGET_LINK_LIBRARIES (@plugin@ ${@plugin@_link_libraries})

INSTALL (TARGETS @plugin@ LIBRARY DESTINATION @plgdir@)
