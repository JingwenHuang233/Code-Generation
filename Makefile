CFLAGS = -g -Wall -ansi -pedantic

phase3: miniL.lex miniL.y
	bison -v -d --file-prefix=y miniL.y
	flex miniL.lex
	g++ $(CFLAGS) -std=c++11 -o phase3 y.tab.c lex.yy.c -lfl
	rm -f lex.yy.c y.tab.* y.output *.o

test: phase3
	cat ./primes.min | ./phase3 > ./primes.mil
	cat ./fibonacci.min | ./phase3 > ./fibonacci.mil
	cat ./errors.min | ./phase3 > ./errors.mil
	cat ./for.min | ./phase3 > ./for.mil