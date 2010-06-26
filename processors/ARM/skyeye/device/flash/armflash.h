//ywc 2005-1-21 for flash simulation
ARMword flash_read_byte (ARMul_State * state, ARMword addr);
void flash_write_byte (ARMul_State * state, ARMword addr, ARMword data);
ARMword flash_read_halfword (ARMul_State * state, ARMword addr);
void flash_write_halfword (ARMul_State * state, ARMword addr, ARMword data);
ARMword flash_read_word (ARMul_State * state, ARMword addr);
void flash_write_word (ARMul_State * state, ARMword addr, ARMword data);
