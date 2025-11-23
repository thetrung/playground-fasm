CC=fasm
CFLAGS=-dynamic-linker /lib64/ld-linux-x86-64.so.2
CLIBS=-lc
CLEAR=*.o *.dump
.PHONY: default build

default: build

build: time malloc print_float

time: time.asm
	$(CC) time.asm
	ld time.o $(CLIBS) $(CFLAGS) -o time

malloc: malloc.asm
	$(CC) malloc.asm
	ld malloc.o $(CLIBS) $(CFLAGS) -o malloc

print_float: print_float.asm
	$(CC) print_float.asm
	ld print_float.o $(CLIBS) $(CFLAGS) -o print_float

clean: 
	rm -f \
	time time.o \
	malloc malloc.o \
	print_float.o print_float
