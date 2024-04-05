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
pilhaSimbolos* tabelaProc;

int num_vars;
int nivel_lexico;
int desloc;
int RotID;              
char compara[5];

pilhaSimbolos * l_elem;
pilhaSimbolos * procAtual;

// imprime na tela um elemento da fila (chamada pela função queue_print)
void print_elem (void *ptr) {
   pilhaSimbolos *elem = ptr ;

   if (!elem)
      return ;

   printf ("%s", elem->identificador) ;
}

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
              
              char* rotuloMain = geraRotulo(RotID);
              RotID++;
              
              pilhaRotulo * noMain = calloc(1, sizeof(pilhaRotulo));
              noMain->rotulo = rotuloMain;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noMain);
            }
            PROGRAM IDENT
            ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
            bloco PONTO 
            {
              geraCodigo (NULL, "PARA");
            }
;

bloco: parte_declara_var
            {
              pilhaRotulo * rotulo = queue_pop((queue_t**) &tabelaRotulo);
              fprintf(fp, "     DSVS %s\n", rotulo->rotulo); fflush(fp);
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) rotulo);
            }
            parte_declara
            {
              pilhaRotulo * rotulo = queue_pop((queue_t**) &tabelaRotulo);
              geraCodigo(rotulo->rotulo, "NADA");  
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
                  if (no->categoria == variavel_simples)
                    count++;
                }
                fprintf(fp, "     DMEM %d\n", count); fflush(fp);
              }
              pilhaSimbolos * proc = queue_pop((queue_t**) &tabelaProc);
              if (tabelaSimbolo != NULL) {
                pilhaSimbolos * proc = queue_pop((queue_t**) &tabelaSimbolo);
                fprintf(fp, "     RTPR %d,%d\n", nivel_lexico, proc->num_param); fflush(fp);
                queue_append((queue_t**) &tabelaSimbolo, (queue_t*) proc);
              }
            }
;

parte_declara_var: var |
;

parte_declara: //rotulo
            | sub_rotina
//            |
;

sub_rotina: declara_proc sub_rotina | declara_proc
;

declara_proc: declara_procedimento PONTO_E_VIRGULA
            //| declara_funcao PONTO_E_VIRGULA 
;

declara_procedimento: PROCEDURE IDENT
            {
              char* rotuloProc = geraRotulo(RotID);
              RotID++;

              pilhaSimbolos * simb = calloc(1, sizeof(pilhaSimbolos));
              simb->prev = NULL;
              simb->next = NULL;
              simb->rotulo = rotuloProc;
              simb->identificador = calloc(1, TAM_TOKEN);
              strncpy(simb->identificador, token, TAM_TOKEN);
              simb->nivel_lexico = nivel_lexico;
              simb->categoria = procedimento;
              queue_append((queue_t**) &tabelaSimbolo, (queue_t*) simb);

              nivel_lexico++;
              desloc = 0;
              
              char* rotuloPularAninhado = geraRotulo(RotID);
              RotID++;

              char * comando = calloc(10, sizeof(char));
              sprintf(comando, "ENPR %d", nivel_lexico);
              geraCodigo(rotuloProc, comando);

              pilhaRotulo * noPularAninhado = calloc(1, sizeof(pilhaRotulo));
              noPularAninhado->rotulo = rotuloPularAninhado;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noPularAninhado);

              pilhaSimbolos * proc = calloc(1, sizeof(pilhaSimbolos));
              proc->prev = NULL;
              proc->next = NULL;
              proc->rotulo = rotuloProc;
              proc->identificador = calloc(1, TAM_TOKEN);
              strncpy(proc->identificador, token, TAM_TOKEN);
              proc->nivel_lexico = nivel_lexico;
              proc->categoria = procedimento;

              queue_append((queue_t**) &tabelaProc, (queue_t*) proc);
            }
            param_formais PONTO_E_VIRGULA
            bloco
            {
              l_elem = queue_pop((queue_t**) &tabelaSimbolo);
              nivel_lexico--;
              queue_append((queue_t**) &tabelaSimbolo, (queue_t*) l_elem);
            }
;

param_formais: parametros_formais
            |
;

parametros_formais: ABRE_PARENTESES sec_par FECHA_PARENTESES
;

sec_par: PONTO_E_VIRGULA secao_de_parametros_formais sec_par
            | secao_de_parametros_formais
;

secao_de_parametros_formais: VAR lista_de_identificadores
            { 
              int aux = 0;
              pilhaSimbolos *proc = tabelaSimbolo->prev;
              pilhaSimbolos *p = tabelaSimbolo->prev;
              while(aux < num_vars) {
                proc = proc->prev;
                p = p->prev;
                aux++;
              }
              proc->num_param = num_vars;
              aux = 0;
              p = p->next;
              while(aux < num_vars){
                vetParam * param = calloc(1, sizeof(vetParam));
                param->prev = NULL;
                param->next = NULL;
                param->tipo = p->tipov;
                param->passa = referencia;
                queue_append((queue_t**) &proc->parametros, (queue_t*) param);
                p->deslocamento = -4 - num_vars + 1 + aux;
                p = p->next;
                aux++;
              }
            }
            | lista_de_identificadores
            { 
              int aux = 0;
              pilhaSimbolos *proc = tabelaSimbolo->prev;
              pilhaSimbolos *p = tabelaSimbolo->prev;
              while(aux < num_vars) {
                proc = proc->prev;
                p = p->prev;
                aux++;
              }
              proc->num_param = num_vars;
              aux = 0;
              p = p->next;
              while(aux < num_vars){
                vetParam * param = calloc(1, sizeof(vetParam));
                param->prev = NULL;
                param->next = NULL;
                param->tipo = p->tipov;
                param->passa = valor;
                queue_append((queue_t**) &proc->parametros, (queue_t*) param);
                p->deslocamento = -4 - num_vars + 1 + aux;
                p = p->next;
                aux++;
              }
            }
;

var: VAR declara_vars
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
              no->deslocamento = num_vars;
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
              no->deslocamento = num_vars;
              num_vars++;
              queue_append((queue_t**) &tabelaSimbolo, (queue_t*) no);
            }
;

lista_idents: lista_idents VIRGULA IDENT
            | IDENT
;

lista_id_pf: lista_id_pf VIRGULA IDENT
            { 
              pilhaSimbolos* no = calloc(1, sizeof(pilhaSimbolos));
              no->identificador = calloc(1, TAM_TOKEN);
              strncpy(no->identificador, token, TAM_TOKEN);
              no->categoria = parametro_formal;
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
              no->categoria = parametro_formal;
              no->nivel_lexico = nivel_lexico;
              no->deslocamento = desloc;
              desloc++;
              num_vars++;
              queue_append((queue_t**) &tabelaSimbolo, (queue_t*) no);
            }
;

lista_de_identificadores:
            { 
              num_vars = 0; 
            }
            lista_id_pf DOIS_PONTOS tipo
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
;

comando_sem_rotulo: atribuicao_ou_chamada_de_procedimento
            | comando_repetitivo
            | comando_composto
            | comando_condicional
            // | desvio
            | leitura
            | escrita
;

atribuicao_ou_chamada_de_procedimento:
            IDENT
            atribuicao_ou_chamada_de_procedimento_depois_ident
;


atribuicao_ou_chamada_de_procedimento_depois_ident:
            atribuicao
            | chamada_procedimento_funcao_sem_argumentos
            | chamada_procedimento_funcao_com_argumentos
;

atribuicao: {
              pilhaSimbolos *no = NULL;
              if (tabelaSimbolo != NULL) {
                no = tabelaSimbolo->prev;
                while (strcmp(no->identificador, token) != 0 && no != tabelaSimbolo)
                  no = no->prev;
              }

              if(no == NULL || strcmp(no->identificador, token) != 0)
                imprimeErro("Variavel nao encontrada.");

              if(no->categoria != variavel_simples &&
                 no->categoria != parametro_formal &&
                 no->categoria != funcao)
                imprimeErro("Erro de atribuição");
              
              if(l_elem == NULL)
                l_elem = no;
              else
                imprimeErro("l_elemet nao e NULL");
            }
            ATRIBUICAO
            expressao
            {
              pilhaTipos *tipo_expressao = queue_pop((queue_t**) &tabelaTipos);
              if(l_elem->tipov == tipo_expressao->tipo){
                fprintf(fp, "     ARMZ %d,%d\n", l_elem->nivel_lexico, l_elem->deslocamento); fflush(fp);
              }
              else
                imprimeErro("Erro de tipo");
              l_elem = NULL;
            }
;

chamada_procedimento_funcao_sem_argumentos:
            {
              // chamar
              pilhaSimbolos *no = NULL;
              if (tabelaSimbolo != NULL) {
                no = tabelaSimbolo->prev;
                while (strcmp(no->identificador, token) != 0 && no != tabelaSimbolo) {
                  no = no->prev;
                  }
              }

              if(no == NULL || strcmp(no->identificador, token) != 0)
                imprimeErro("Procedimento nao encontrado.");
              
              if(no->categoria != procedimento)
                imprimeErro("Erro de atribuição");
              
              fprintf(fp, "     CHPR %s,%d\n", no->rotulo, nivel_lexico); fflush(fp);
            }
;

chamada_procedimento_funcao_com_argumentos:
            {
              // memorizar a chamada
              pilhaSimbolos* no = NULL;
              if (tabelaSimbolo != NULL) {
                no = tabelaSimbolo->prev;
                while (strcmp(no->identificador, token) != 0 && no != tabelaSimbolo) {
                  no = no->prev;
                }
              }

              if(no == NULL || strcmp(no->identificador, token) != 0)
                imprimeErro("Procedimento nao encontrado.");
              
              if(no->categoria != procedimento)
                imprimeErro("Erro de atribuição");

              pilhaSimbolos * proc = calloc(1, sizeof(pilhaSimbolos));
              proc->prev = NULL;
              proc->next = NULL;
              proc->rotulo = calloc(4, sizeof(char));
              strcpy(proc->rotulo, no->rotulo);
              proc->identificador = calloc(1, TAM_TOKEN);
              strcpy(proc->identificador, no->identificador);
              proc->nivel_lexico = nivel_lexico;
              proc->categoria = procedimento;
              proc->num_param = 0;

              queue_append((queue_t**) &tabelaProc, (queue_t*) proc);
            }
            ABRE_PARENTESES
            lista_de_expressoes
            FECHA_PARENTESES
            {
              // chamar
              pilhaSimbolos *proc = queue_pop((queue_t**) &tabelaProc);
              fprintf(fp, "     CHPR %s,%d\n", proc->rotulo, nivel_lexico); fflush(fp);
              queue_append((queue_t**) &tabelaProc, (queue_t*) proc);
            }
;

expressao: expressao_simples relacao expressao
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              if(tipo1->tipo == tipo2->tipo){
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
                geraCodigo(NULL, compara);
              }
              else
                imprimeErro("Erro de tipo");
            }
            | expressao_simples
;

expressao_simples: mais_ou_menos_termo MAIS expressao_simples
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              if(tipo1->tipo == tipo2->tipo){
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              }
              else
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "SOMA");
            }
            | mais_ou_menos_termo MENOS expressao_simples
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              if(tipo1->tipo == tipo2->tipo){
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              }
              else
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "SUBT");
            }
            | mais_ou_menos_termo OR expressao_simples
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              if(tipo1->tipo == tipo2->tipo){
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              }
              else
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
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              if(tipo1->tipo == tipo2->tipo)
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              else
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "CONJ");
            }
            | termo DIV fator 
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              if(tipo1->tipo == tipo2->tipo)
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              else
                imprimeErro("Erro de tipo");
              geraCodigo(NULL, "DIVI");
            }
            | termo MULTI fator
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              pilhaTipos *tipo1 = queue_pop((queue_t**) &tabelaTipos);
              pilhaTipos *tipo2 = queue_pop((queue_t**) &tabelaTipos); 
              if(tipo1->tipo == tipo2->tipo)
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              else
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

fator: IDENT
            {
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
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_int;
              queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              fprintf(fp, "     CRCT %s\n", token); fflush(fp);
            }
            | TRUE 
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              fprintf(fp, "     CRCT 1\n"); fflush(fp);
            }
            | FALSE 
            {
              pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
              no->tipo = tipo_bool;
              queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              fprintf(fp, "     CRCT 0\n"); fflush(fp);
            }
            // | chamada_de_funcao
            | ABRE_PARENTESES expressao FECHA_PARENTESES
            | NOT fator
;

lista_de_expressoes: expressao VIRGULA lista_de_expressoes
            | expressao
;

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
  tabelaProc = NULL;

  l_elem = NULL;
  procAtual = NULL;
  RotID = 0;
  nivel_lexico = 0;

  yyin=fp;
  yyparse();

  return 0;
}
