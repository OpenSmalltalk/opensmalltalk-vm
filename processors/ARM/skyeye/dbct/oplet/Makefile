CFLAGS=-I$(PWD)/../include
all: reg_gen movl_gen shift_gen
reg_gen:reg_gen.c
	gcc $(CFLAGS) -o reg_gen reg_gen.c
movl_gen:movl_gen.c
	gcc $(CFLAGS) -o movl_gen movl_gen.c
shift_gen:shift_gen.c
	gcc $(CFLAGS) -o shift_gen shift_gen.c
clean:
	rm -f reg_gen movl_gen shift_gen
