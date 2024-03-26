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

int num_vars;
int nivel_lexico;
int desloc;

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES IGUAL DIFERENTE MENOR_QUE
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO MENOR_OU_IGUAL MAIOR_QUE
%token T_BEGIN T_END VAR IDENT ATRIBUICAO THEN WHILE MAIOR_OU_IGUAL MAIS
%token ARRAY TYPE LABEL PROCEDURE GOTO IF ELSE DO OR DIV AND NOT MENOS MULTI
%token ABRE_CHAVE FECHA_CHAVE ABRE_COLCHETE FECHA_COLCHETE NUMERO DIVISAO
%token READ WRITE

%%

programa    :
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

bloco       :
            parte_declara_vars
            {
            }

            comando_composto
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

parte_declara_vars:  var
;

var         : VAR declara_vars
            |
;

declara_vars: declara_vars declara_var
            | declara_var
;

declara_var : 
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

tipo        : IDENT 
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

comandos: comandos PONTO_E_VIRGULA comando
            | comando
            |
;

comando: rotulo comando_sem_rotulo 
            | comando_sem_rotulo
;

rotulo: numero DOIS_PONTOS
;

numero: NUMERO
;

comando_sem_rotulo: atribuicao 
            | chamada_de_procedimento 
            | desvio
            | comando_composto
            | comando_condicional
            | comando_repetitivo
;

atribuicao: variavel ATRIBUICAO expressao
;

variavel: IDENT
            {
              pilhaSimbolos *no = tabelaSimbolo->prev;
              
              while(strcmp(no->identificador, token))
                no = no->prev;
              
              if(no->categoria != variavel_simples &&
                 no->categoria != parametro_formal &&
                 no->categoria != funcao)
                imprimeErro("Erro de atribuição");

             // Implementar a pilha de tipo!!!!! 
              
            } 
//            | IDENT lista_de_expressao
;

expressao: expressao_simples
            | relacao expressao_simple
;

expressao_simples: mais_ou_menos termo
;

mais_ou_menos: SOMA
            | MENOS
            |
;

termo: 

chamada_de_procedimento:
;

desvio:
;

comando_composto:
;

comando_condicional:
;

comando_repetitivo:
;

//lista_de_expressao:
//;

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

   yyin=fp;
   yyparse();

   return 0;
}
