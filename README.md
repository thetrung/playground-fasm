Playground FASM
======================
A sum of all bite-size puzzles/examples to learn Flat Assembler (FASM), piece by piece.

### Easy-Going Window PE 4.0
Later on my highway-to-assembly-hell, after exhausted by dealing with Linux frictions, I realize the OS itself isn't engineered for Assembly Language like FASM, but C-Style as 1st citizen everywhere with a lengthy nested struct that require you to rebalance stack on your own by counting ( or guessing ) its size. Which making the last resolve to independent binary compiling in 1-shot is relying on `syscall` and write my own `TUI` on top of it for anything-GUI related.

So instead of fighting the losing game, I took a 2 weeks-long break from such headache that keep eating my energy. 

while diving into retro/vintage PC from 90s-2000s, I realize window efficiency was so impressive that DOS/win95/98 accidentally become the real-time OS that is both flexible & deterministic at runtime that industrial machines have been using it for decades. While Linux itself have to wait for quite long time to have something called `PREEMPT_RT` to make-up terribly for such thing. Because in fact, Linux never was designed for deterministic, but async-based, preemptive nature for multithreading system.

So even when I hate Windows since its recent versions, I'm back to winXP to compare what a simple GUI app written in FASM look like, and I was impressd with how simple it is to do it without any linking, you just compile & run the .exe file ! And the winAPI is way easier, more unified to use than the fragmented nature of Linux. This is when I decided to split my playground into OS-specific, and run window experiments with `Wine` before I may decide to actually re-install WinXP again..

### dependency-hell on Linux
Major issues when we want to write FASM on x86-64 SysV Linux, is dealing with external C library/framework everywhere to expand the limitations made by the kernel itself to access its features that can't be done with syscall. And since it doesn't have such unified & lightweight loader like `Window Loader` to load imported functions table, but rely on runtime-linker to load shared library, result in bigger binary just for meta-data.

First example is accessing framebuffer/gpu resources need to be done via either x11 / glx or drm / gbm / kms at its lowest level. It's like, you want to solve complexity but have to deal with all complexity first to find the most "direct way" to talk with hardware via Linux Kernel & its Drivers.

No wonder why people love FASM, just want to write their own OS anyway. So no more `dependency-hell`. 

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
