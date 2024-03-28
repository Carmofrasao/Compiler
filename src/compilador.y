// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"
#include "queue.h"

pilhaSimbolos* tabelaSimbolo;
pilhaTipos* tabelaTipos;
pilhaRotulo* tabelaRotulo;

int num_vars;
int nivel_lexico;
int desloc;
int RotID;              
char compara[5];

pilhaSimbolos * l_elem;

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES IGUAL DIFERENTE MENOR_QUE
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO MENOR_OU_IGUAL MAIOR_QUE
%token T_BEGIN T_END VAR IDENT ATRIBUICAO THEN WHILE MAIOR_OU_IGUAL MAIS
%token ARRAY TYPE LABEL PROCEDURE GOTO IF ELSE DO OR DIV AND NOT MENOS MULTI
%token ABRE_CHAVE FECHA_CHAVE ABRE_COLCHETE FECHA_COLCHETE NUMERO DIVISAO
%token READ WRITE TRUE FALSE

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%%

programa:
            {
              geraCodigo (NULL, "INPP");
            }
            PROGRAM IDENT
            ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
            bloco PONTO 
            {
              geraCodigo (NULL, "PARA");
            }
;

bloco: parte_declara_vars comando_composto
            {
              if (tabelaSimbolo != NULL) {
                int count = 0;
                pilhaSimbolos *fim = tabelaSimbolo->prev;
                while(tabelaSimbolo && fim->nivel_lexico == nivel_lexico) {
                  fim = fim->prev;
                  pilhaSimbolos * no = queue_pop((queue_t**) &tabelaSimbolo);
                  free(no);
                  count++;
                }
                  
                fprintf(fp, "     DMEM %d\n", count); fflush(fp);
              }
            }
;

parte_declara_vars: var
;

var: VAR declara_vars
            |
;

declara_vars: declara_vars declara_var
            | declara_var
;

declara_var: 
            { 
              num_vars = 0; 
            }
            lista_id_var DOIS_PONTOS
            tipo
            { 
              fprintf(fp, "     AMEM %d\n", num_vars); fflush(fp);
            }
            PONTO_E_VIRGULA
;

tipo: IDENT 
            {
              tipo_variavel tipo;
              if (strcmp(token, "integer") == 0) {
                tipo = tipo_int;
              } else if (strcmp(token, "boolean") == 0) {
                tipo = tipo_bool;
              } else {
                imprimeErro("tipo nao encontrado");
              }
              pilhaSimbolos *fim = tabelaSimbolo->prev;
              for (int i = 0; i < num_vars; i++) {
                fim->tipov = tipo;
                fim = fim->prev;
              }
            }
;

lista_id_var: lista_id_var VIRGULA IDENT
            { 
                pilhaSimbolos* no = calloc(1, sizeof(pilhaSimbolos));
                no->identificador = calloc(1, TAM_TOKEN);
                strncpy(no->identificador, token, TAM_TOKEN);
                no->categoria = variavel_simples;
                no->nivel_lexico = nivel_lexico;
                no->deslocamento = desloc;
                desloc++;
                num_vars++;
                queue_append((queue_t**) &tabelaSimbolo, (queue_t*) no);
            }
            | IDENT 
            { 
              
                pilhaSimbolos* no = calloc(1, sizeof(pilhaSimbolos));
                no->identificador = calloc(1, TAM_TOKEN);
                strncpy(no->identificador, token, TAM_TOKEN);
                no->categoria = variavel_simples;
                no->nivel_lexico = nivel_lexico;
                no->deslocamento = desloc;
                desloc++;
                num_vars++;
                queue_append((queue_t**) &tabelaSimbolo, (queue_t*) no);
            }
;

lista_idents: lista_idents VIRGULA IDENT
            | IDENT
;

comando_composto: T_BEGIN comandos T_END
;

comandos: comando PONTO_E_VIRGULA comandos
            | comando
            |
;

comando: rotulo comando_sem_rotulo 
            | comando_sem_rotulo
;

rotulo: numero DOIS_PONTOS
;

numero: NUMERO
//            {
// Caso o goto seja implementado, havera codigo aqui
//            }
;

comando_sem_rotulo: comando_repetitivo
            | atribuicao 
            // | chamada_de_procedimento 
            | comando_composto
            | comando_condicional
            // | desvio
            | leitura
            | escrita
;

atribuicao: variavel
            {
              pilhaSimbolos *no = tabelaSimbolo->prev;
              while(strcmp(no->identificador, token) && no != tabelaSimbolo)
                no = no->prev;

              if(strcmp(no->identificador, token) != 0)
                imprimeErro("Variavel nao encontrada.");
              
              if(no->categoria != variavel_simples &&
                 no->categoria != parametro_formal &&
                 no->categoria != funcao)
                imprimeErro("Erro de atribuição");
              
              if(l_elem == NULL)
                l_elem = no;
              else
                imprimeErro("l_elemet nao e NULL");
            } ATRIBUICAO expressao 
            {
              // compara tipo do l_elem
              // com o tipo do topo da pilha
              pilhaTipos *tipo_expressao = queue_pop((queue_t**) &tabelaTipos);
              if(l_elem->tipov == tipo_expressao->tipo){
                fprintf(fp, "     ARMZ %d,%d\n", l_elem->nivel_lexico, l_elem->deslocamento); fflush(fp);
              }
              else
                imprimeErro("Erro de tipo");
              l_elem = NULL;
            }
;

variavel: IDENT
;

expressao: expressao_simples relacao expressao
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              // desempilha dois
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              // verifica se os dois são bool
              if(tipo1->tipo == tipo2->tipo){
                // se for empilha bool
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
                geraCodigo(NULL, compara);
              }
              else
                // se não for, é erro
                imprimeErro("Erro de tipo");
            }
            | expressao_simples
;

expressao_simples: mais_ou_menos_termo MAIS expressao_simples
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              // desempilha dois
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              // verifica se os dois são int
              if(tipo1->tipo == tipo2->tipo){
                // se for empilha int
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              }
              else
                // se não for, é erro
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "SOMA");
            }
            | mais_ou_menos_termo MENOS expressao_simples
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              // desempilha dois
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              // verifica se os dois são int
              if(tipo1->tipo == tipo2->tipo){
                // se for empilha int
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              }
              else
                // se não for, é erro
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "SUBT");
            }
            | mais_ou_menos_termo OR expressao_simples
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              // desempilha dois
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              // verifica se os dois são int
              if(tipo1->tipo == tipo2->tipo){
                // se for empilha int
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              }
              else
                // se não for, é erro
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "DISJ");
            }
            | mais_ou_menos_termo
;

mais_ou_menos_termo: MAIS termo
            | MENOS termo
            | termo
;

termo: termo AND fator 
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              // desempilha dois
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              // verifica se os dois são booleanos
              if(tipo1->tipo == tipo2->tipo)
                // se for empilha boolean
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              else
                // se não for, é erro
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "CONJ");
            }
            | termo DIV fator 
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              // desempilha dois
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              // verifica se os dois são int
              if(tipo1->tipo == tipo2->tipo)
                // se for empilha int
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              else
                // se não for, é erro
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "DIVI");
            }
            | termo MULTI fator
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              // desempilha dois
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              // verifica se os dois são int
              if(tipo1->tipo == tipo2->tipo)
                // se for empilha int
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              else
                // se não for, é erro
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "MULT");
            }
            | fator
;

relacao: IGUAL
            {
               strcpy(compara, "CMIG");
            }
            | DIFERENTE 
            {
               strcpy(compara, "CMDG");
            }
            | MENOR_QUE 
            {
               strcpy(compara, "CMME");
            }
            | MENOR_OU_IGUAL 
            {
               strcpy(compara, "CMEG");
            }
            | MAIOR_OU_IGUAL 
            {
               strcpy(compara, "CMAG");
            }
            | MAIOR_QUE 
            {
               strcpy(compara, "CMMA");
            }
;

fator: variavel
            {
              // tem que empilhar a variavel!!!!
              pilhaSimbolos *no = tabelaSimbolo->prev;
              while(strcmp(no->identificador, token) && no != tabelaSimbolo)
                no = no->prev;

              if(strcmp(no->identificador, token) != 0)
                imprimeErro("Variavel nao encontrada.");
               
              pilhaTipos * tipo_var = calloc(1, sizeof(pilhaTipos));
              tipo_var->tipo = no->tipov;
              queue_append((queue_t**) &tabelaTipos, (queue_t*) tipo_var);
              fprintf(fp, "     CRVL %d,%d\n", no->nivel_lexico, no->deslocamento); fflush(fp);
            }
            | numero 
            {
              // empilhar inteiro
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              fprintf(fp, "     CRCT %s\n", token); fflush(fp);
            }
            | TRUE 
            {
              // empilhar bool
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              fprintf(fp, "     CRCT 1\n"); fflush(fp);
            }
            | FALSE 
            {
              // empilhar bool
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              fprintf(fp, "     CRCT 0\n"); fflush(fp);
            }
            // | chamada_de_funcao
            | ABRE_PARENTESES expressao FECHA_PARENTESES
            | NOT fator
;

// chamada_de_procedimento:
// ;

// chamada_de_funcao:
// ;

// desvio:
// ;


comando_condicional: if_then
            {
               pilhaRotulo * rotElse = queue_pop((queue_t**) &tabelaRotulo);
               geraCodigo(rotElse->rotulo, "NADA");
            }
            cond_else
            {
               pilhaRotulo * rotFim = queue_pop((queue_t**) &tabelaRotulo);
               geraCodigo(rotFim->rotulo, "NADA");
            }
;

cond_else: ELSE
           comando_sem_rotulo
           | %prec LOWER_THAN_ELSE
;

if_then: IF expressao
            {
              char* rotuloElse = geraRotulo(RotID);
              RotID++;
              char* rotuloFim = geraRotulo(RotID);
              RotID++;

              pilhaRotulo * noElse = calloc(1, sizeof(pilhaRotulo));
              noElse->rotulo = rotuloElse;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noElse);
              
              pilhaRotulo * noFim = calloc(1, sizeof(pilhaRotulo));
              noFim->rotulo = rotuloFim;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noFim);

              fprintf(fp, "     DSVF %s\n", rotuloElse); fflush(fp);
            }
            THEN comando_sem_rotulo
            {
              pilhaRotulo * rotFim = queue_pop((queue_t**) &tabelaRotulo);
              pilhaRotulo * rotElse = queue_pop((queue_t**) &tabelaRotulo);
              fprintf(fp, "     DSVS %s\n", rotFim->rotulo); fflush(fp);
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) rotFim);
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) rotElse);
            }
;

comando_repetitivo: WHILE 
            {
              char* rotuloI = geraRotulo(RotID);
              RotID++;
              char* rotuloF = geraRotulo(RotID);
              RotID++;
              
              pilhaRotulo * noI = calloc(1, sizeof(pilhaRotulo));
              noI->rotulo = rotuloI;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noI);

              pilhaRotulo * noF = calloc(1, sizeof(pilhaRotulo));
              noF->rotulo = rotuloF;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noF);

              geraCodigo(rotuloI, "NADA");
            }
            expressao DO 
            {
              pilhaRotulo * rot = queue_pop((queue_t**) &tabelaRotulo);
              fprintf(fp, "     DSVF %s\n", rot->rotulo); fflush(fp);
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) rot);
            }
            comando_sem_rotulo
            {
              pilhaRotulo * rotF = queue_pop((queue_t**) &tabelaRotulo);
              pilhaRotulo * rotI = queue_pop((queue_t**) &tabelaRotulo);

              fprintf(fp, "     DSVS %s\n", rotI->rotulo); fflush(fp);
              
              geraCodigo(rotF->rotulo, "NADA");
            }
;

leitura: READ ABRE_PARENTESES lista_leitura FECHA_PARENTESES
;

lista_leitura: lista_leitura VIRGULA simbolo_leitura
   	        | simbolo_leitura
;

simbolo_leitura: IDENT
	          {
		          geraCodigo(NULL, "LEIT");
		
              pilhaSimbolos *no = tabelaSimbolo->prev;
              
              while(strcmp(no->identificador, token) && no != tabelaSimbolo)
                no = no->prev;

              if(strcmp(no->identificador, token) != 0)
                imprimeErro("Variavel nao encontrada.");

              fprintf(fp, "     ARMZ %d,%d\n", no->nivel_lexico, no->deslocamento); fflush(fp);
	          }
;

escrita: WRITE ABRE_PARENTESES lista_escrita FECHA_PARENTESES
;

lista_escrita: lista_escrita VIRGULA expressao 
            { 
              geraCodigo (NULL, "IMPR"); 
            }
	          | expressao 
            { 
              geraCodigo (NULL, "IMPR"); 
            }
;

%%

int main (int argc, char** argv) {
  FILE* fp;
  extern FILE* yyin;

  if (argc<2 || argc>2) {
    printf("usage compilador <arq>a %d\n", argc);
    return(-1);
  }

  fp=fopen (argv[1], "r");
  if (fp == NULL) {
     printf("usage compilador <arq>b\n");
     return(-1);
  }


/* -------------------------------------------------------------------
 *  Inicia a Tabela de S�mbolos
 * ------------------------------------------------------------------- */

  tabelaSimbolo = NULL;
  tabelaTipos = NULL;
  tabelaRotulo = NULL;
  l_elem = NULL;
  RotID = 0;

  yyin=fp;
  yyparse();

  return 0;
}
