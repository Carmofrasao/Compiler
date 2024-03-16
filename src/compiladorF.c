
/* -------------------------------------------------------------------
 *            Aquivo: compilador.c
 * -------------------------------------------------------------------
 *              Autor: Bruno Muller Junior
 *               Data: 08/2007
 *      Atualizado em: [09/08/2020, 19h:01m]
 *
 * -------------------------------------------------------------------
 *
 * Funções auxiliares ao compilador
 *
 * ------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"

typedef struct pilha_t {
  struct pilha_t *prev;
  struct pilha_t *next;
  int valor;
} pilha_t;

/* -------------------------------------------------------------------
 *  variáveis globais
 * ------------------------------------------------------------------- */

simbolos simbolo, relacao;
char token[TAM_TOKEN];
pilha_t *M;

FILE* fp=NULL;
void inicioCompilador () {

  fp = fopen ("MEPA", "w");

  fprintf(fp, "INPP\n");
  fflush(fp);

}

void fimCompilador (){
  
  fprintf(fp, "PARA\n");
  fflush(fp);

}

int imprimeErro ( char* erro ) {
  fprintf (stderr, "Erro na linha %d - %s\n", nl, erro);
  exit(-1);
}
