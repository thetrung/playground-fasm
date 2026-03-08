default: build run clean

run:
	./arg11
	./glx_cube

build: arg11 glx_cube


arg11: arg11.c
	gcc arg11.c -S -masm=intel
	# gcc will generate AT&T syntax by default.
	as arg11.s -o arg11.o -msyntax=intel
	# as need -msyntax if not AT&T syntax.
	gcc arg11.o -o arg11

glx_cube: glx_cube.c
	gcc glx_cube.c -o glx_cube -lX11 -lGL -lm
	gcc glx_cube.c -S -masm=intel

clean:
	rm -rf \
	arg11.o arg11.s arg11 \
	glx_cube.s glx_cube

