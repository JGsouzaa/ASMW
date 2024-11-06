global _start
; SYSCALL CONSTANTS

	%define SYS_WRITE 1
	%define SYS_EXIT 60
	%define SYS_SOCKET 41
	%define SYS_BIND 49
	%define SYS_LISTEN 50
	%define SYS_ACCEPT 43
	%define SYS_CLOSE 3

	%define AF_INET 2 		;Ipv4 internet protocol , for ipv6 = 10 and unix domain = 1
	%define SOCK_STREAM 1 		;TCP, for udp = 2, raw = 3
	%define SOCK_PROTOCOL 0		;TCP will be used

	%define BACKLOG 3		;define 3 pending conections

	%define NEWLINE 0xA

	%define EXIT_STATUS 1
	%define STDOUT 1

	%define CR 0xD
	%define LF 0xA

;;SYSCALL MACROS

%macro syscall2 2
	mov rax, %1
	mov rdi, %2
	syscall

%endmacro

%macro syscall3 3
	mov rax, %1
	mov rdi, %2
	mov rsi, %3
	syscall

%endmacro

%macro syscall4 4
	mov rax, %1
	mov rdi, %2
	mov rsi, %3
	mov rdx, %4
	syscall

%endmacro

%macro syscall5 5
	mov rax, %1
	mov rdi, %2
	mov rsi, %3
	mov rdx, %4
	mov r10, %5
	syscall

%endmacro

;;WRITE
%macro printf 2
	syscall4 SYS_WRITE, STDOUT, %1, %2
%endmacro

;;EXIT
%macro return 0
	syscall2 SYS_EXIT, EXIT_STATUS
%endmacro


section .data
	msg db 'Teste', 0
	msg_len equ $ - msg

	newline db NEWLINE
	newline_len equ $ - newline

	socket_creating_msg db 'INFO: Creating socket...', 0
	socket_creating_msg_len equ $ - socket_creating_msg
	socket_err_msg db 'ERROR: Failed to create socket!', 0
	socket_err_msg_len equ $ - socket_err_msg
	socket_ok_msg db 'SUCCESS: Socket created successfully!', 0
	socket_ok_msg_len equ $ - socket_ok_msg
	socket_addr:
		family: dw AF_INET ;[2 bytes]
		port: dd 0x800C ;port 3200 [4 bytes]
		ip_address: dd 0 ;[4 bytes]
		sin_zero: dq 0 ; [8 bytes]
	socket_addr_len equ 18

	binding_msg db 'INFO: Binding the socket...', 0
	binding_msg_len equ $ - binding_msg
	bind_err_msg db 'ERROR: Failed to bind the socket!', 0
	bind_err_msg_len equ $ - bind_err_msg
	bind_ok_msg db 'SUCCESS: Bind process ended successfully!', 0
	bind_ok_msg_len equ $ - bind_ok_msg

	listen_err_msg db 'ERROR: FAIL in listening process!', 0
	listen_err_msg_len equ $ - listen_err_msg
	listen_ok_msg db 'INFO: Listening on port 3200', 0
	listen_ok_msg_len equ $ - listen_ok_msg


	acc_ok_msg db 'SUCCESS: Accepting connections...', 0
	acc_ok_msg_len equ $ - acc_ok_msg
	acc_err_msg db 'ERROR: Fail to accept connections...', 0
	acc_err_msg_len equ $ - acc_err_msg

	acc_addr:
		.family: dw 0 ;[2 bytes]
		.port: dw 0 ; [2 bytes]
		.ip_address: dd 0 ;[4 bytes]
		.sin_zero: dq 0 ; [8 bytes]
	acc_addr_len equ 16
	flags db 0

	response:
	    headline: db "HTTP/1.1 200 OK", CR, LF
	    content_type: db "Content-Type: text/html", CR, LF
	    content_length: db "Content-Length: 22", CR, LF
	    crlf: db CR, LF
	    body: db "<h1>Assembly web </h1>"
	response_len equ $ - response

section .bss
	socket_fd resb 1

section .text

_start:

	call .createsocket
	test rax, rax
	js .return

	call .bindsocket
	test rax, rax
	js .return

	call .listen
	test rax, rax
	js .return

	call .accept
	test rax, rax
	js .return
	call .writeresponse
;	call .return

.return:
	return

.print:
	printf msg, msg_len
	ret

.createsocket:
	printf socket_creating_msg, socket_creating_msg_len
	printf newline, newline_len
	syscall4 SYS_SOCKET, AF_INET, SOCK_STREAM, SOCK_PROTOCOL
	test rax, rax
	js .socket_error
	mov [socket_fd], rax
	jmp .socket_success

.socket_error:
	printf socket_err_msg, socket_err_msg_len
	printf newline, newline_len
	ret

.socket_success:
	printf socket_ok_msg, socket_ok_msg_len
	printf newline, newline_len
	ret

.bindsocket:
	printf binding_msg, binding_msg_len
	printf newline, newline_len

	syscall4 SYS_BIND, [socket_fd], socket_addr, socket_addr_len
	test rax, rax
	js .bind_error
	jmp .bind_success
	ret

.bind_error:
	printf bind_err_msg, bind_err_msg_len
	printf newline, newline_len
	ret

.bind_success:
	printf bind_ok_msg, bind_ok_msg_len
	printf newline, newline_len
	ret

.listen:
	syscall3 SYS_LISTEN, [socket_fd], BACKLOG
	test rax, rax
	js .listen_error
	jmp .listen_success
	ret

.listen_error:
	printf listen_err_msg, listen_err_msg_len
	printf newline, newline_len
	ret

.listen_success:
	printf listen_ok_msg, listen_ok_msg_len
	printf newline, newline_len
	ret

.accept:
	syscall5 SYS_ACCEPT, [socket_fd], [acc_addr], acc_addr_len, flags
;//Review this structure -> acc_addr
	mov r8, rax
	;test rax, rax
	;js .accept_error
	;jmp .accept_success
	call .writeresponse
	call .closeconnection
	jmp .accept
;	ret

.accept_error:
	printf acc_err_msg, acc_err_msg_len
	printf newline, newline_len
	ret

.accept_success:
	printf acc_ok_msg, acc_ok_msg_len
	printf newline, newline_len
	ret

.writeresponse:
	syscall4 SYS_WRITE, r8, response, response_len
	ret

.closeconnection:
	syscall2 SYS_CLOSE, r8
	ret
