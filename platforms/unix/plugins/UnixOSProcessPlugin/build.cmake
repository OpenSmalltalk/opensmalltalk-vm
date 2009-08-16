INCLUDE_DIRECTORIES (${cross}/plugins/FilePlugin ${cross}/plugins/SocketPlugin)
ADD_DEFINITIONS (-DSQAIO_H=\"sqaio.h\")
EXPECT_UNDEFINED_SYMBOLS ()
