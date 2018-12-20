include ../../Makefile.plugin

# This seems broken, but in the generated FT2Plugin.c there is an
# include<tttables.h> which should be include<freetype/tttables.h>
# so we simply add it to the include path. Eeek.
INCLUDES+= -I$(WIN32DIR)/freetype

# Add the freetype libs to the build
EXTRALIBS=$(WIN32DIR)/freetype.a

