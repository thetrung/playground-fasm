#include <sys/syscall.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <stdio.h>

// rdi rsi rdx r10 r8 r9
socket = SYS_socket
bind = SYS_bind
listen = SYS_listen
accept = SYS_accept
read = SYS_read
open = SYS_open
close = SYS_close
write = SYS_write
exit = SYS_exit
shutdown = SYS_shutdown

shut_rd = SHUT_RD
af_inet = AF_INET
sock_stream = SOCK_STREAM
o_rdonly = O_RDONLY

//   SOCK_STREAM = 1,
//   SOCK_DGRAM = 2,
//   SOCK_RAW = 3,
//   SOCK_RDM = 4,
//   SOCK_SEQPACKET = 5,
//   SOCK_DCCP = 6,
//   SOCK_PACKET = 10,
//   SOCK_CLOEXEC = 02000000,
//   SOCK_NONBLOCK = 00004000
//
// Use command to get all constants :
// > gcc -E -P constant.c > constant.txt  
// result :
// socket = 41
// bind = 49
// listen = 50
// accept = 43
// open = 2
// close = 3
// read = 0
// write = 1
// exit = 60
// shutdown = 48
// shut_rd = 0
// af_inet = 2
// sock_stream = 1
// o_rdonly = 0