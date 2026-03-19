Playground FASM
======================
A sum of all bite-size puzzles/examples to learn Flat Assembler (FASM), piece by piece.

### syscall (no library)
- hello world : [hello.asm](https://github.com/thetrung/playground-fasm/blob/main/hello.asm)
- concat string : [concate_string.asm](https://github.com/thetrung/playground-fasm/blob/main/concat_string.asm)
- fibonacci & print numbers : [fib.asm](https://github.com/thetrung/playground-fasm/blob/main/fib.asm)

### call function from library
Need to run `make` to compile & link :
- time / lib64 : [time.asm](https://github.com/thetrung/playground-fasm/blob/main/time.asm)
- malloc / lib64 : [malloc.asm](https://github.com/thetrung/playground-fasm/blob/main/malloc.asm)
- printf / lib64 : [printf_float.asm](https://github.com/thetrung/playground-fasm/blob/main/printf_float.asm)
- x11 / lX11 : [x11.asm](https://github.com/thetrung/playground-fasm/blob/main/x11.asm)
- x11 + GLX / lGL : [glx.asm](https://github.com/thetrung/playground-fasm/blob/main/glx.asm)
- raylib : [raylib.asm](https://github.com/thetrung/playground-fasm/blob/main/raylib.asm)

### Linux X86-64 Macros
I'm building a [linux x86-64 macros](https://github.com/thetrung/playground-fasm/blob/main/linux64a.inc) library to assist with tricky problems like `simd, invoke, memcpy` for AMD64 ABI calling convention when dealing with SSE registers, SysV ABI ccall, C-Struct passing.. 

Depends on when function is called with :
- (any args) string/addr  -> 1-4 bytes address.
- (1~8 args) float/double -> XMM regs will be used.
- (6+ args)  int/long     -> \[RSP\] stack with alignment.
- (N args)   struct/obj   -> \[RSP\] stack but with accurate memory chunk size.  

Just include `linux64a.inc` to your file.

### FASM Package manager
This is what FASM is lacking to unite its fragile community brilliant minds - which may simplify many work with properly done library. Just a plan but I will make it into my TODO list.

Function: it may just simply manage a `.toml` file like cargo, then fetch every library from a git repo & auto regenerate `Makefile` to add it up in linker `ld` or `gcc` of your choice later.

### Run via Docker
- If you consider my minimal already-setup image based on `ubuntu-24.04/6.11.11-linuxkit`:

        docker pull deulamco/ubuntu-amd64:latest

- Else, start your own container :

        docker run --rm -it --platform linux/amd64 -v $(pwd):/local ubuntu:24.04

- Install packages :

        apt update -y && apt install fasm make binutils libc6-dev

- Save your container -> image to use later :

        docker ps
        docker commit asteartnh3 your_hub/repo_name:tag
        docker push your_hub/repo_name:tag

- Run :

        docker run -it -v $(pwd):/local your_hub/repo_name:tag

** This playground is based on x86-64 only, so we need a fixed environment to emulate it exclusively.
