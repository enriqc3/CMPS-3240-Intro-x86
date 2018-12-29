# CMPS-3240-Introduction-x86
Reverse "Hello world!"

## Objectives

* Know how to generate x86 assembly code from C code
* Know how to generate an executable binary from x86 assembly code
* Become acquainted with GAS syntax of x86 assembly code

## Prerequisites

Read about x86 assembly. We will be using GAS syntax specifically (not NASM). Some helpful resources:
* https://www.nayuki.io/page/a-fundamental-introduction-to-x86-assembly-programming - Sections 0-8.
* http://flint.cs.yale.edu/cs421/papers/x86-asm/asm.html - Helpful explanation of instructions and how the stack works (passing arguments between subroutines).
* https://www3.nd.edu/~dthain/courses/cse40243/fall2015/intel-intro.html - Helpful breakdown of what we intend to do with today's lab. Know that they used a different version of GCC so our version will be slightly different.

## Requirements

### General

* Knowledge of linux CLI
* Some experience with C language `printf`
* Some experience with `make`

### Software

This lab requires the following software:

* gcc
* make
* git

odin.cs.csubak.edu has these already installed.

### Compatability

| Linux | Mac | Windows |
| :--- | :--- | :--- |
| Yes, but must be on odin.cs.csubak.edu due to GCC and kernel differences | No | No |

This lab requires you to assemble an x86 program, the syntax and calling conventions of which are specific down to the operating system and version of GCC you are using. This lab manual is written assuming that you're on the department's server, odin.cs.csubak.edu. Future labs may have compatability with other environments.

## Background

Today's lab consists of the following tasks:
1. Study a version of hello world in C language
1. Use gcc to generate x86 assembly code
1. Study x86 assembly code, and tweak it a bit
1. Use gcc again to assemble a working binary from the x86 assembly code

This lab is a learning-by-doing lab, so there is not much background. Assuming you've already remotely connected to odin, clone this repository:

```shell
$ git clone https://github.com/DrAlbertCruz/CMPS-3240-Introduction-x86.git
```

There is a makefile that will help with compiling the code. For this lab manual I'm assuming you've worked with make files before. If you haven't the `makefile` included in this repository is simple enough to learn off of. Take the time to read the comments if this is your first time. Let's get started then...

## Approach

### Part 1 - `hello.s`

Use your favorite CUI text editor to open up `hello.c`:

```shell
$ vim hello.c
```

There should be no surprises here. `stdio.h` contains the `printf` function which is used to display a string literal to the screen. We also declare a variable in the scope of `main()` called `i`, and initialize it with the number 13. A prime number, my favorite number, and also a very specific number that will be easy to identify when we're looking at the assembly code. Recall that 0 is the appropriate value to return from `main` if the program completed without any errors. Enter `:q` to quit vim.

You've probably used gcc to compile C code into a binary executable, but we're going to use it to generate assembly source code for us to look at. Execute the `hello.s` target in the makefile like so:

```shell
$ make hello.s
gcc -Wall -O0 -o hello.s -S hello.c
hello.c: In function 'main':
hello.c:4:9: warning: unused variable 'i' [-Wunused-variable]
     int i = 13;
         ^
```

Ignore the warning. It is generated because we used the `-Wall` flag for gcc which let us know that our variable `i` was unused. The `-O0` flag is also used to prevent the compiler from doing any optimizations. Normally the compiler will do crazy things to make our code faster and we want to prevent it from making changes under the hood that we do not explicitly want to implement. Load this file:

```shell
$ vim hello.s
```

Let's step through this line by line. The first few lines:

```
    .file   "hello.c"
```

Lines that start with a period are generally assembler directives and not assembly code. `.file` lets the debugger know the original source code file that generated this assembly code. It does not run any commands.<sup>1</sup>

```
    .section    .rodata
.LC0:
    .string "Hello world!"
```

 `.section .rodata` declares that the following lines are read-only parts of memory. The items in this section are variables stored in memory and are organized by the identifier, data type and the literal value. 
 
 `.LC0:` is a tag, it indicates that the rest of the contents of the line, or what immidiately follows the line, should be associated with the identifier in the tag. Note that when we declared the string literal "Hello world!" we did not associate it with an identifier. The compiler created a read-only variable for us automatically called `.LC0`. `.string` indicates that the data type is a string.
 
 ```
    .text
 ```
 
 This indicates the start of code. 
 
 ```
    .globl main
    .type   main, @function
main:
```

These compiler directives are notes for the debugger and linker that indicate the start of the main function. `main:` is the real identifier here that indicates the next few lines are the start of our `main()` function. Ignore the rest of the directives for the time beyond, they're beyond the lab.

```
    pushq   %rbp
    movq    %rsp, %rbp
    subq    $16, %rsp
    movl    $13, -4(%rbp)
```

This whole chunk of code sets up the stack, the part of memory that can be used by this function for storing temporary variables, and passing and returning command line arguments. Registers in GAS x86 syntax start with a `%`, so the registers in this chunk of code are `%rbp` and `%rsp`. `%rsp` points to the beginning of a function's part of the stack and `%rbp` points to the end. Note that as `main` is called, the stack currently points to the part of the stack of the function that called us. Often the first step in a function is to set up the stack for our use and this is called *setting up a stack frame*.

The first command we see is `pushq`, which saves the contents of the `%rbp` register onto the stack. There are a few important concepts here:
1. When we set up our stack frame, we need to restore everything to how it was before. So, we save `%rbp` so we can remember where the stack pointed to before our function was called.
2. Instructions ussually have a suffix that indicates the size of the operation being carried out. In this scenario `pushq` has a `q` at the end, indicating that it is a quad word. Here is a table explaining the different sizes of operations. A word is 16 bits in x86 because this was defined by the first x86 processor, the 4004 back in the 1970's. <sup>1</sup>

| Suffix | Meaning | Length |
| :--- | :--- | :--- |
| b | Byte | 8 bit |
| s | Short | 16 bit integer or 32-bit floating point |
| w | Word | 16 bit |
| l | Long | 32 bit integer or 64-bit floating point |
| q | Quad/Quadword | 64 bit |
| t | Ten bytes | 80-bit floating point |

3. We do not store `%rbp` in registers because there are a finite number of registers and we do not know if other subroutines will clobber any register. It is important that we do not lose track of this address, so we place it on the stack in a specific spot.

Moving on, `movq %rsp, %rbp` replaces the contents of `%rbp` with `%rsp`. This brings the start of the stack to the end of where it was previously. We claim a portion of the stack for ourselves by incrementing the stack pointer `%rsp`, and this command is carried out with `subq $16, %rsp`. Literal constants in GAS x86 are prefixed with `$`. 16 is just some arbitrary amount based on specifications by the operating system. 

Note the command `movl $13, -4(%rbp)`. Recall that we instantiated an integer with a value of 13. We called it `i`, but it appears that this name was lost. It is just an integer living at the memory address `-4(%rbp)`, which evaluates to: `%rbp` - 4. This also verifies the idea of scope. `i` was created within the scope of the `main` block. Later on, after `main` finishes, it should not be accessible by the previous function. This is implemented by reverting the stack to it's original state by moving the stack pointer. This is called *popping the stack* (which you should look forward to later on in the code). 

The following code calls `printf`. Note that to call `printf`, we must set up the arguments and then make the call:

```
    leaq    .LC0(%rip), %rdi
    movl    $0, %eax
    call    printf@PLT
```

`call` obviously calls the `printf` function. Arguments are passed in registers: `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9`.
Additional arguments, if needed, are passed in stack slots immmediately above the return address.<sup>2</sup> We pass a pointer to the string literal `.LC0`. The `lea` instruction loads the address, rather than the value, into a register. See reference 2 for how addresses are calculated. `%rip` literally means 'here', and `.LC0(%rip)` grabs the difference of the address of the current instruction and `.LC0`. Note that we know the relative distance between `.LC0` and the current instruction but we are unsure of where exactly the first line of this program will be placed absolutely in memory. This is why `%rip` is used.

*You should probably look at reference 2 for an explanation of the different registers, and how they are related. E.g., rax is a 64 bit register. eax is the lower 32 bits of the rax register, and so on.*

Finally, we have two more instructions:

```
    movl    $0, %eax
    leave
    ret
````

`leave` cleans up the stack for us. In other assembly languages you need to manually move the stack pointers but x86 has a convienient instruction to pop the whole stack for us. `ret` returns from the function. Let's reassemble the program. The `assemble` target in the makefile will do this for us. Function return values are stored in a single register, `%ax`. These last three instructions are `return 0;` in C.

```
$ make assemble
```

and you should get:

```
$ ./hello.out
Hello world!
```

If you want to get creative at this point you can modify `hello.s` line 4 to say something else:

```
$ make assemble
$ ./hello.out
Have you heard the tale of Darth Plagueis the wise...
```

### Part 2 - Print `i`

The goal of this part of the lab is to execute the following instruction:

```c
printf("%d%", i);
```

*but to do this via assembly instructions.* First, we must insert `"%d%"`as a string literal. Add the following instructions to the `.rodata` section:

```
.myString:
    .string "%d"
```

Now, we insert a second call to `printf` via the following instructions:

```   
    leaq    .myString(%rip), %rdi
    mov    -4(%rbp), %rsi
    movl    $0, %eax
    call    printf@PLT
```

The only differences between this second call and the first are that we refer to `.myString` that we inserted rather than `.LC0`, and that we provide a second argument in `%rsi`. Recall that the variable `i` is stored on the stack at memory address `-4(%rbp)`. I suppose we could have put `$13` there (for literal 13) but in this scenario we want to print `i` (whatever value that might be). Save your changes and if everything went well you should get:

```
$ make assemble
$ ./hello.out
Have you heard the tale of Darth Plagueis the wise...13
```

## Check off

Demonstrate that output of part 2. You must have completed this via x86, and not C.

## References

<sup>1</sup>https://en.wikibooks.org/wiki/X86_Assembly/GAS_Syntax
<sup>2</sup>https://www.lri.fr/~filliatr/ens/compil/x86-64.pdf
<sup>3</sup>https://stackoverflow.com/questions/6212665/why-is-eax-zeroed-before-a-call-to-printf
