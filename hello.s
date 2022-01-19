#Enrique Tapia
	.file	"hello.c"
	.text
	.section	.rodata
.LC2:
	.string	"Hello, I'm working!\n"
	.text
	.globl	main
	.type	main, @function

.myString:
    .string "%d \n"

main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movl	$86, -4(%rbp)
	movb	$12, -5(%rbp)
	movss	.LC0(%rip), %xmm0
	movss	%xmm0, -12(%rbp)
	movsd	.LC1(%rip), %xmm0
	movsd	%xmm0, -24(%rbp)
	movq	$0, -32(%rbp)
	leaq	.LC2(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT

	leaq    .myString(%rip), %rdi
    movq    -4(%rbp), %rsi
    movl    $0, %eax
    call    printf@PLT

	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.section	.rodata
	.align 4
.LC0:
	.long	1065353216
	.align 8
.LC1:
	.long	1374389535
	.long	1074339512
	.ident	"GCC: (Debian 8.3.0-6) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
