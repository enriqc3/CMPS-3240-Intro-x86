# CMPS-3240-Intro-x86
Introduction to the x86 assembly language

## Objectives

* Know how to generate x86 assembly mnemonics (GAS syntax) from C code with GCC
* Know how to assemble an executable binary from x86 assembly code
* Become acquainted with GAS syntax of x86 assembly code

## Prerequisites

* Know about the compiler, assembler and linker. Refer to Appendix A-1. Note that the book covers MIPS, and we will be using x86 for labs. These languages are different.
* Read about x86 assembly. We will be using GAS syntax specifically (not NASM). Some helpful resources are posted in the reference section. Read sections 0-8 in reference 4. Read reference 5 for a helpful explanation of instructions and how the stack works (passing arguments between subroutines). Finally, Read reference 6 for a helpful breakdown of what we intend to do with today's lab. They used a different version of GCC so our version will be slightly different.

## Requirements

### General

* Some experience with C language `printf()`

### Software

This lab requires the following software: `gcc`, `make`, `git`. `odin.cs.csubak.edu` has these already installed.

### Compatability

| Linux | Mac | Windows |
| :--- | :--- | :--- |
| Must be on `odin.cs.csubak.edu`<sup>*</sup> | No<sup>*</sup> | No<sup>*</sup> |

<sup>*</sup>Differences in GCC version and OS/kernel versions will cause big differences in how C code is translated to machine code.  

This lab requires you to assemble an x86 program, the syntax and calling conventions of which are specific down to the operating system and version of GCC you are using. This lab manual is written assuming that you're on the department's server, `odin.cs.csubak.edu`. Future labs may have relaxed compatability with other environments.

## Background

Today's lab consists of the following tasks:
1. Study a version of hello world in C language
1. Use `gcc` to generate x86 assembly code
1. Study x86 assembly code
1. Modify the assembly code
1. Use gcc again to assemble a working binary from the x86 assembly code

This lab is a learning-by-doing lab, so there is not much background. Assuming you've already remotely connected to odin, clone this repository and change into that directory:

```shell
$ git clone https://github.com/DrAlbertCruz/CMPS-3240-Introduction-x86.git
$ cd CMPS-3240-Introduction-x86
```

## Approach

### Part 1 - `hello.s`

Use your favorite CUI text editor to open up `hello.c`:

```shell
$ vim hello.c
```

As you study the contents of this file, it should be familiar to you. `stdio.h` contains the `printf()` function which is used to display a string literal to the screen. We also declare a number of variables in the scope of `main()`:

```c
int i = 86;
char j = 12;
float k = 1.0;
double l = 3.14;
int *ptr = 0; // Null
```

Take some time remember what the size each of these should be. For example, a `char` is how many bytes? Is it signed or unsigned? Recall we `return 0;` from `main()` if the program completes without any errors. Enter `:q` to quit vim. You've probably used `gcc` to compile C code into a binary executable, but we're going to use it to generate assembly source code for us to look at. Execute the `hello.s` target in the makefile like so:

```shell
$ make hello.s
gcc -Wall -O0 -o hello.s -S hello.c
```

The `-O0` flag is also used to prevent the compiler from doing any optimizations. Normally the compiler will do advanced things to make our code faster and we want to prevent it from making changes under the hood that we do not explicitly want to implement. The `-S` flag will tell `gcc` that we want assembly code. Now view this file:

```shell
$ vim hello.s
```

Let's step through this line by line. The first few lines:

```
    .file   "hello.c"
```

Lines that start with a period are generally assembler directives and not assembly code. They do not make it to the binary version of your code. `.file` lets the debugger know the original file name that generated this assembly code. It does not run any commands.<sup>1</sup>

```
    .section    .rodata
.LC2:
    .string "Hello world!"
```

 `.section .rodata` declares that the following lines are read-only parts of memory. The items in this section are variables stored in memory and are organized by the identifier, data type and the literal value. You can think of the variables declared in this section as global and `const`. *The compiler may have given your code a different identifier than LC2*.
 
 `.LC2:` is a tag, it indicates that the rest of the contents of the line, or what immidiately follows the line, should be associated with the identifier in the tag. Note that when we declared the string literal "Hello world!" we did not associate it with an identifier. We plugged it into the function call directly, with:
 
 ``` c
 printf( "Hello world!" );
 ```
 
The compiler created a read-only variable for us automatically called `.LC0`. `.string` indicates that the data type is a string. If thought-of in terms of C code, it would look like this:
 
 ```c
 char* LC2 = "Hello world!";
 printf( LC2 );
 ```
 
Moving on, now consider: 
 
 ```
.text
    .globl main
    .type   main, @function
main:
```

`.text` indicates the start of code. `.globl main` and `.type main, @function` are compiler directives for the debugger and linker that indicate the start of the main function. `main:` is the real identifier here that indicates the following lines are the start of our `main()` function. Ignore the rest of the directives from here on out, they're beyond the scope of the lab.

```
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $32, %rsp
    movl    $86, -4(%rbp)
    movb    $12, -5(%rbp)
    movss   .LC0(%rip), %xmm0
    movss   %xmm0, -12(%rbp)
    movsd   .LC1(%rip), %xmm0
    movsd   %xmm0, -24(%rbp)
    movq    $0, -32(%rbp)
```

There's a whole lot going on here. Before we move on you must understand that x86 instructions, unlike MIPS, must specify the word length in the operation name. For example: `pushq` is a `push` command with word length `q` indicating quad word. In x86, a word is 16-bits, thus 4 * 16 = 64 bits. `movl` means `mov` with word length `l`. Here is a table explaining common formats:

| Suffix | Meaning | Length |
| :--- | :--- | :--- |
| b | Byte | 8 bit |
| s | Short | 16 bit integer or 32-bit floating point |
| w | Word | 16 bit |
| l | Long | 32 bit integer or 64-bit floating point |
| q | Quad/Quadword | 64 bit |
| t | Ten bytes | 80-bit floating point |

This whole chunk of code sets up the stack, the part of memory that can be used by this function for storing temporary variables, and passing and returning command line arguments (if needed). Registers in GAS x86 syntax start with a `%`, so the registers in this chunk of code are `%rbp` and `%rsp`. `%rsp` points to the beginning of a function's part of the stack and `%rbp` points to the end. Note that as `main` is called, the stack currently points to the part of the stack of the function that called us. Often the first step in a function is to set up the stack for our use and this is called *setting up a stack frame*.<sup>2</sup>

The first command we see is `pushq`, which saves the contents of the `%rbp` register onto the stack. There are a few important concepts here:
1. When we set up our stack frame, we need to restore everything to how it was before. So, we save `%rbp` so we can remember where the stack pointed to before our function was called.
1. We do not store `%rbp` in registers because there are a finite number of registers and we do not know if other subroutines will clobber any register. It is important that we do not lose track of this address, so we place it on the stack in a specific spot. The *calling convention* you are using dictates where it is placed. 

Moving on, `movq %rsp, %rbp` replaces the contents of `%rbp` with `%rsp`. This brings the start of the stack to the end of where it was previously. We claim a portion of the stack for ourselves by incrementing the stack pointer `%rsp`, and this command is carried out with `subq $32, %rsp`. Literal constants in GAS x86 are prefixed with `$`. 

Note the command `movl $86, -4(%rbp)`. Recall that we instantiated an integer with a value of 86. We called it `i`, but it appears that this name was lost. It is just an integer living at the memory address `-4(%rbp)`, which evaluates to: `%rbp` - 4. This also verifies the idea of scope. `i` was created within the scope of the `main` block. Later on, after `main` finishes, it should not be accessible by the previous function. This is implemented by reverting the stack to it's original state by moving the stack pointer. This is called *popping the stack* (which you should look forward to later on in the code). *Aside: This does not actually zero out or remove the value from the stack, it just moves the base and stack pointers. If someone knows where to look on the stack this is a potential security vulnerability, but discussion of it is beyond the scope of the class.*

Based on initialization values and suffixes of the operation, you should be able to track down where each variable "lives" on the stack. For example, we initialized a `char`, a single byte, to `$12`, and it's pretty clearly the `movb $12, -5(%rbp)` command. Also note the spacing. Because it is only a byte, it is located 1 byte away from `i`. The floating point values are different in many ways:

* They are larger, and require more spacing.
* They have their own suffix `sd` and `ss` standing for scalar double and scalar single respectively.
* One does not enter a fractional literal at the machine language level. Fractional numbers are stored in their own format (IEEE-754) that does not translate to a readable number if the binary representation is converted to decimal. Note that the compiler placed these literals (which are essentially unreadable by us at this point) here:

```c
    .align 4
.LC0:
    .long   1065353216
```

Moving on past the stack, the following code calls `printf`. Note that to call `printf`, we must set up the arguments and then make the call:

```
    leaq    .LC0(%rip), %rdi
    movl    $0, %eax
    call    printf@PLT
```

`call` calls the `printf` function. According to System V, arguments are passed in registers: `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9` in that order. Additional arguments, if needed, are passed in stack slots immmediately above the return address.<sup>2</sup> For our code, we only pass one argument to `printf`, a pointer to the string literal `Hello world!`. Recall that we associated it with the identifier `LC0`. So, we pass a pointer to the string literal `.LC0`. The `lea` instruction loads the address, rather than the value, into a register. The `q` suffix indicates it's a quadword. `%rip` literally means 'here' and `.LC0(%rip)` grabs the difference of the address of the current instruction and `.LC0`. Note that we know the relative distance between `.LC0` and the current instruction but we are unsure of where exactly the first line of this program will be placed absolutely in memory. This is why `%rip` is used.

*You should probably look at reference 2 for an explanation of the different registers, and how they are related. E.g., rax is a 64 bit register. eax is the lower 32 bits of the rax register, and so on.*

Finally, we have two more instructions:

```
    movl    $0, %eax
    leave
    ret
````

`movl` move a 32-bit value holding 0 into the `eax` register. Function return values are passed through a single register, `%ax`. `leave` cleans up the stack for us. *Aside: In other assembly languages, such as MIPS, you need to manually move the stack pointers but x86 has a convienient instruction to pop the whole stack for us.* `ret` returns from the function. These last three instructions are `return 0;` in C.

Let's reassemble the program. The `assemble` target in the makefile will do this for us:

``` shell
$ make assemble
```

and you should get:

``` shell
$ ./hello.out
Hello world!
```

If you want to get creative at this point you can modify `hello.s` line 4 to say something else, and you might want to throw in a new line while youre at it (`\n`):

```
$ make assemble
$ ./hello.out
There is a realm of existence so far beyond your own you cannot even imagine it. I am beyond your comprehension. I am x.
```

### Part 2 - Print `i`

The goal of this part of the lab is to append the following instruction, after `Hello world!`:

```c
printf("Hello world!"); // Previously there
printf("%d%", i); // The new code we will implement, but through x86 and not C
```

First, we must insert `"%d%"`as a string literal. Add the following instructions to the `.rodata` section:

```
.myString:
    .string "%d"
```

after `.LC0`. Now, we insert a second call to `printf` via the following instructions:

```   
    leaq    .myString(%rip), %rdi
    movl    -4(%rbp), %rsi
    movl    $0, %eax
    call    printf@PLT
```

after `call printf@PLT`. The only differences between this second call and the first are that we refer to `.myString` that we inserted rather than `.LC0`, and that we provide a second argument in `%rsi`. Recall that the variable `i` is stored on the stack at memory address `-4(%rbp)`. I suppose we could have put `movl $86, %rsi` but in this scenario we want to print `i` (whatever value that might be). Save your changes and if everything went well you should get:

```
$ make assemble
$ ./hello.out
There is a realm of existence so far beyond your own you cannot even imagine it. I am beyond your comprehension. I am x.
86
```

## Check off

Demonstrate the output of part 2. You must completed this via x86, and not C.

## References

<sup>1</sup>https://en.wikibooks.org/wiki/X86_Assembly/GAS_Syntax

<sup>2</sup>https://www.lri.fr/~filliatr/ens/compil/x86-64.pdf

<sup>3</sup>https://stackoverflow.com/questions/6212665/why-is-eax-zeroed-before-a-call-to-printf

<sup>4</sup>https://www.nayuki.io/page/a-fundamental-introduction-to-x86-assembly-programming 

<sup>5</sup>http://flint.cs.yale.edu/cs421/papers/x86-asm/asm.html

<sup>6</sup>https://www3.nd.edu/~dthain/courses/cse40243/fall2015/intel-intro.html
