INCLUDE_DIRECTORIES (${unix}/plugins/AsynchFilePlugin)
TARGET_LINK_LIBRARIES(@plugin@ ${@plugin@_libs})
EXPECT_UNDEFINED_SYMBOLS ()
