# This is a comment.

# This is how you declare variables
COMPILER=gcc
FLAGS=-O0

# Calling 'make' will execute the first target in the 'makefile'. This is the
# first target. By convention it's ussually 'all', which compiles the main part
# of your project. It follows this syntax:
# <name of target>: <dependent file 1> <dependent file 2> ...
#        <command executed by target if dependencies changed>
# Note that the command *must* be preceded by a tab. This is somewhat white space
# sensitive in this respect. If you execute a target, the command will be ex-
# ecuted, but only if the dependencies of the target have changed. 
all: hello 

# The above 'all' target just has dependencies but no commands. So, on calling 
# 'make' or 'make all' we will check if 'hello' has changed. 'hello' has not
# ever been executed so it will attempt to run the 'hello' target below. Further
# calls to 'make' or 'make all' will do nothing assuming 'hello' was a success.

# The first "real" target. This guy compiles hello.c. Note that it uses variables
# which must be enclosed in parenthesis, and prefixed with a dollar sign. You can
# also use {} as well as () for referencing variables. All this target does is 
# call:
# gcc -Wall -O0 -o hello.out hello.c
# basically it compiles the hello world file.
hello: hello.c
	$(COMPILER) $(FLAGS) -o hello.out hello.c

# This guy is not included in all and will have to be executed manually with 
# 'make hello.asm'. It generates assembly code.
hello.s: hello.c
	$(COMPILER) $(FLAGS) -o hello.s -S hello.c

# This guy reassembles code generated from the above target
assemble: hello.o
	$(COMPILER) hello.o -o hello.out

hello.o: hello.s
	$(COMPILER) $(FLAGS) -c hello.s -o hello.o

clean: 
	rm -f *.o *.s *.out
