#include  "types.h"
bu8 io_read_byte (bu32 addr);
bu16 io_read_word (bu32 addr);
bu32 io_read_long (bu32 addr);
void io_write_byte (bu32 addr, bu8 v);
void io_write_word (bu32 addr, bu16 v);
void io_write_long (bu32 addr, bu32 v);
