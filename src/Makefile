EXE: lex.yy.c lexer.l parser.tab.c
	g++ -o berp-l lex.yy.c parser.tab.c -lfl -std=c++11


lex.yy.c: lexer.l
	flex lexer.l

parser.tab.c: parser.y lex.yy.c
	bison -t -v -d parser.y 
#-Wcounterexamples
# test: test_num 
# test_ops test_brackets

# would be good to have but not priority
# test_num: EXE
# 	cat ../tests/part1/input/test_num.txt | ./berp-l > ../tests/part1/output/test_num.txt
# 	diff ../tests/part1/expected/test_num.txt ../tests/part1/output/test_num.txt

# test_ops: EXE
#  	cat ../tests/part1/input/test_ops.txt | ./berp-l > ../tests/part1/output/test_ops.txt
#	diff ../tests/part1/expected/test_ops.txt ../tests/part1/output/test_ops.txt

# test_brackets: EXE
# 	cat ../tests/part1/input/test_brackets.txt | ./berp-l > ../tests/part1/output/test_brackets.txt
# 	diff ../tests/part1/expected/test_brackets.txt ../tests/part1/output/test_brackets.txt
clean: 
	rm -f berp-l lex.yy.c parser.tab.c parser.tab.h parser.output
	# rm ../tests/part1/output/*.txt
