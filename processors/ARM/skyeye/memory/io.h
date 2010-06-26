#ifndef __MEMORY_IO_H__
#define __MEMORY_IO_H__

void io_reset(void* state);
void io_do_cycle(void * state);
uint32_t io_read_byte(void* state, uint32_t addr);
uint32_t io_read_halfword(void* state, uint32_t addr);
uint32_t io_read_word(void* state, uint32_t addr);
void io_write_byte(void * state, uint32_t addr,uint32_t data);
void io_write_halfword(void * state, uint32_t addr, uint32_t data);
void io_write_word(void * state, uint32_t addr, uint32_t data);
int io_read(short size, uint32_t addr, uint32_t * value);
int io_write(short size, uint32_t addr, uint32_t value);
#endif
