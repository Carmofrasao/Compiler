 # -------------------------------------------------------------------
 #            Arquivo: Makefile
 # -------------------------------------------------------------------
 #              Autor: Bruno Müller Junior
 #               Data: 08/2007
 #      Atualizado em: [09/08/2020, 19h:01m]
 #
 # -------------------------------------------------------------------

$DEPURA=1

compilador: lex.yy.c compilador.tab.c compilador.o queue.o compilador.h
	gcc lex.yy.c compilador.tab.c queue.o compilador.o -o compilador -lfl -lc -ly

lex.yy.c: compilador.l compilador.h
	flex compilador.l

compilador.tab.c: compilador.y compilador.h
	bison compilador.y -d -v ${EXTRA}

compilador.o : compilador.h compiladorF.c
	gcc -c compiladorF.c -o compilador.o

queue.o: queue.c
	gcc -c queue.c -o queue.o

clean :
	rm -f compilador.tab.* lex.yy.c *.o compilador compilador.output
