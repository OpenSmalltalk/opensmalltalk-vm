INCLUDE_DIRECTORIES (${cross}/plugins/SurfacePlugin ${@plugin@_include_dirs})
LINK_DIRECTORIES (${@plugin@_library_dirs})
TARGET_LINK_LIBRARIES (@plugin@ ${@plugin@_libraries})
