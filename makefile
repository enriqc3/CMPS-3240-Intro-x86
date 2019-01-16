COMPILER=gcc
FLAGS=-O0

# all target only does 'hello'
all: hello 

# This target compiles a binary directly without producing the intermediate .o file
hello: hello.c
	$(COMPILER) $(FLAGS) -o $@.out $<

hello.s: hello.c
	$(COMPILER) $(FLAGS) -S -o $@ $<

# Note that the .o file is produced from the .s file, not the .c code
hello.o: hello.s
	$(COMPILER) $(FLAGS) -c $< -o $@
	
assemble: hello.o
	$(COMPILER) $(FLAGS) $< -o hello.out

clean: 
	rm -f *.o *.s *.out
