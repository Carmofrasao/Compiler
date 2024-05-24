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
pilhaSimbolos* tabelaChamada;
passagem tipo_passagem;
pilhaSubtipo * tabelaSubtipo;

int num_vars;
int num_vars_aux;
int nivel_lexico;
int desloc;
int RotID;              
char compara[5];

pilhaSimbolos * l_elem;
pilhaSimbolos * procAtual;

// imprime na tela um elemento da fila (chamada pela função queue_print)
void print_elem (void *ptr) {
   pilhaSubtipo *elem = ptr ;

   if (!elem)
      return ;

   printf ("Subtipo: %s, tipo: %d\n", elem->subtipo, elem->tipo);
}

// imprime na tela um elemento da fila (chamada pela função queue_print)
void print_elem_s (void *ptr) {
  pilhaSimbolos *elem = ptr ;

  if (!elem)
    return ;
  
  if(elem->tem_s == 0)
    printf ("ident: %s, tipo: %d, tem sub: %d\n", elem->identificador, elem->tipov, elem->tem_s);
  else
    printf ("ident: %s, tipo: %d, tem sub: %d, sub: %s\n", elem->identificador, elem->tipov, elem->tem_s, elem->sub);
}

// imprime na tela um elemento da fila (chamada pela função queue_print)
void print_elem_t (void *ptr) {
  pilhaTipos *elem = ptr ;

  if (!elem)
    return ;
  
  if(elem->tem_sub == 0)
    printf ("tipo: %d\n", elem->tipo);
  else
    printf ("tipo: %d, tem sub: %d, sub: %s\n", elem->tipo, elem->tem_sub, elem->subtipo->subtipo);
}

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES IGUAL DIFERENTE MENOR_QUE
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO MENOR_OU_IGUAL MAIOR_QUE
%token T_BEGIN T_END VAR IDENT ATRIBUICAO THEN WHILE MAIOR_OU_IGUAL MAIS
%token ARRAY TYPE LABEL PROCEDURE GOTO IF ELSE DO OR DIV AND NOT MENOS MULTI
%token ABRE_CHAVE FECHA_CHAVE ABRE_COLCHETE FECHA_COLCHETE NUMERO DIVISAO
%token READ WRITE TRUE FALSE FUNCTION

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

bloco: type bloco | parte_declara_var bloco_aux
;

bloco_aux:
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
                  if (no->categoria == variavel_simples)
                    count++;
                  free(no);
                }
                fprintf(fp, "     DMEM %d\n", count); fflush(fp);
              }
              if (tabelaSimbolo != NULL) {
                pilhaSimbolos * proc = queue_pop((queue_t**) &tabelaSimbolo);
                fprintf(fp, "     RTPR %d, %d\n", nivel_lexico, proc->num_param); fflush(fp);
                queue_append((queue_t**) &tabelaSimbolo, (queue_t*) proc);
              }
            }
;

parte_declara_var: var |
;

type: TYPE declara_types
    {
      // queue_print("Tabela subtipo: ", (queue_t*) tabelaSubtipo, print_elem); 
    }
;

declara_types: declara_types declara_type
        | declara_type
;

declara_type:
        id_type IGUAL
        tipo_sub
        PONTO_E_VIRGULA
;

id_type: IDENT
        {
          pilhaSubtipo * sub = calloc(1, sizeof(pilhaSubtipo));
          sub->subtipo = calloc(16, sizeof(char));
          
          strncpy(sub->subtipo, token, TAM_TOKEN);
          queue_append((queue_t**) &tabelaSubtipo, (queue_t*) sub);
        }
;

tipo_sub: IDENT
        {
          pilhaSubtipo * sub = queue_pop((queue_t**) &tabelaSubtipo);
          tipo_variavel tipo;
          if(strcmp(token, "integer") == 0){
            tipo = tipo_int;
          }
          else if(strcmp(token, "boolean") == 0){
            tipo = tipo_bool;
          } else {
            imprimeErro("Tipo não encontrado");
          }
          sub->tipo = tipo;
          queue_append((queue_t**) &tabelaSubtipo, (queue_t*) sub);
        }
;

parte_declara:
            | sub_rotina
;

sub_rotina: declara_proc sub_rotina | declara_proc
;

declara_proc: declara_procedimento PONTO_E_VIRGULA
            | declara_funcao PONTO_E_VIRGULA 
;

declara_funcao: FUNCTION IDENT
            {
              char* rotuloFunc = geraRotulo(RotID);
              RotID++;

              pilhaSimbolos * simb = calloc(1, sizeof(pilhaSimbolos));
              simb->prev = NULL;
              simb->next = NULL;
              simb->rotulo = rotuloFunc;
              simb->identificador = calloc(1, TAM_TOKEN);
              strncpy(simb->identificador, token, TAM_TOKEN);
              simb->nivel_lexico = nivel_lexico;
              simb->categoria = funcao;
              simb->num_param = 0;
              queue_append((queue_t**) &tabelaSimbolo, (queue_t*) simb);

              nivel_lexico++;
              desloc = 0;
              
              char* rotuloPularAninhado = geraRotulo(RotID);
              RotID++;

              char * comando = calloc(10, sizeof(char));
              sprintf(comando, "ENPR %d", nivel_lexico);
              geraCodigo(rotuloFunc, comando);

              pilhaRotulo * noPularAninhado = calloc(1, sizeof(pilhaRotulo));
              noPularAninhado->rotulo = rotuloPularAninhado;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noPularAninhado);

              procAtual = simb;
            }
            param_formais DOIS_PONTOS IDENT
            {
              pilhaSimbolos *no = NULL;
              if (tabelaSimbolo != NULL) {
                no = tabelaSimbolo->prev;
                while (strcmp(no->identificador, procAtual->identificador) != 0 && no != tabelaSimbolo)
                  no = no->prev;
              }

              if(no == NULL || strcmp(no->identificador, procAtual->identificador) != 0)
                imprimeErro("Função não encontrada.");
              
              tipo_variavel tipo;
              if (strcmp(token, "integer") == 0) {
                tipo = tipo_int;
              } else if (strcmp(token, "boolean") == 0) {
                tipo = tipo_bool;
              } else {
                imprimeErro("Tipo nao encontrado.");
              }
              no->tipov = tipo;
              no->deslocamento = no->next->deslocamento - 1;
            }
            PONTO_E_VIRGULA
            bloco
            {
              nivel_lexico--;
            }
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
              simb->num_param = 0;
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

              procAtual = simb;
            }
            param_formais PONTO_E_VIRGULA
            bloco
            {
              nivel_lexico--;
            }
;

param_formais: parametros_formais
            |
;

parametros_formais:
            ABRE_PARENTESES
            sec_par
            {
              pilhaSimbolos *p = tabelaSimbolo->prev;
              for(int aux = 0; aux < procAtual->num_param; aux++) {
                p->deslocamento = -4 - aux;
                p = p->prev;
              }
            }
            FECHA_PARENTESES
;

sec_par: sec_par PONTO_E_VIRGULA secao_de_parametros_formais
            | secao_de_parametros_formais
;

secao_de_parametros_formais: VAR { tipo_passagem = referencia; } lista_de_identificadores { tipo_passagem = valor; }
            | { tipo_passagem = valor; } lista_de_identificadores { tipo_passagem = valor;}
;

var: VAR declara_vars 
            {
              num_vars_aux = 0;
            }
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
              pilhaSubtipo * no = NULL;
              int tem = 0;
              if (strcmp(token, "integer") == 0) {
                tipo = tipo_int;
              } else if (strcmp(token, "boolean") == 0) {
                tipo = tipo_bool;
              } else {
                
                if (tabelaSubtipo != NULL) {
                  no = tabelaSubtipo->prev;
                  while (strcmp(no->subtipo, token) != 0 && no != tabelaSubtipo)
                    no = no->prev;
                }
                tem = 1;
                
                if(strcmp(no->subtipo, token) != 0)
                  imprimeErro("tipo nao encontrado");
              }
              pilhaSimbolos *fim = tabelaSimbolo->prev;
              if(tem == 0){
                for (int i = 0; i < num_vars; i++) {
                  fim->tem_s = 0;
                  fim->tipov = tipo;
                  fim = fim->prev;
                }
              }
              else{
                for (int i = 0; i < num_vars; i++) {
                  fim->tem_s = 1;
                  fim->tipov = no->tipo;
                  fim->sub = calloc(16, sizeof(char));
                  strncpy(fim->sub, no->subtipo, TAM_TOKEN);
                  fim = fim->prev;
                }
              }
              // queue_print("Tabela simbolos: ", (queue_t*) tabelaSimbolo, print_elem_s);
            }
;

lista_id_var: lista_id_var VIRGULA IDENT
            { 
              pilhaSimbolos* no = calloc(1, sizeof(pilhaSimbolos));
              no->identificador = calloc(1, TAM_TOKEN);
              strncpy(no->identificador, token, TAM_TOKEN);
              no->categoria = variavel_simples;
              no->nivel_lexico = nivel_lexico;
              no->deslocamento = num_vars_aux;
              num_vars++;
              num_vars_aux++;
              queue_append((queue_t**) &tabelaSimbolo, (queue_t*) no);
            }
            | IDENT 
            { 
              pilhaSimbolos* no = calloc(1, sizeof(pilhaSimbolos));
              no->identificador = calloc(1, TAM_TOKEN);
              strncpy(no->identificador, token, TAM_TOKEN);
              no->categoria = variavel_simples;
              no->nivel_lexico = nivel_lexico;
              no->deslocamento = num_vars_aux;
              num_vars++;
              num_vars_aux++;
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
            lista_id_pf DOIS_PONTOS IDENT
            { 
              tipo_variavel tipo;
              if (strcmp(token, "integer") == 0) {
                tipo = tipo_int;
              } else if (strcmp(token, "boolean") == 0) {
                tipo = tipo_bool;
              } else {
                imprimeErro("tipo nao encontrado");
              }

              procAtual->num_param += num_vars;
              pilhaSimbolos *p = tabelaSimbolo->prev;
              for(int aux = 0; aux < num_vars; aux++) {
                vetParam * param = calloc(1, sizeof(vetParam));
                param->prev = NULL;
                param->next = NULL;
                param->tipo = tipo;
                param->passa = tipo_passagem;
                queue_append((queue_t**) &procAtual->parametros, (queue_t*) param);
                p->passa = tipo_passagem;
                p = p->prev;
              }
            }
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
            | leitura
            | escrita
;

atribuicao_ou_chamada_de_procedimento:
            IDENT
            atribuicao_ou_chamada_de_procedimento_depois_ident
;


atribuicao_ou_chamada_de_procedimento_depois_ident:
            atribuicao
            | chamada_procedimento_sem_argumentos
            | chamada_procedimento_com_argumentos
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
              // queue_print("Tabela Tipo: ", (queue_t*) tabelaTipos, print_elem_t); 
              pilhaTipos *tipo_expressao = queue_pop((queue_t**) &tabelaTipos);
              if(l_elem->tem_s == 1 && tipo_expressao->tem_sub == 1){
                if(strcmp(l_elem->sub, tipo_expressao->subtipo->subtipo) != 0)
                  imprimeErro("Erro de atribuição");
              } else if(l_elem->tem_s == 1){
                if(l_elem->tipov != tipo_expressao->tipo)
                  imprimeErro("Erro de atribuição");
              } else if(tipo_expressao->tem_sub == 1){
                if(l_elem->tipov != tipo_expressao->subtipo->tipo)
                  imprimeErro("Erro de atribuição");
              }

              if(l_elem->tipov == tipo_expressao->tipo){
                int nivel = l_elem->nivel_lexico;
                if(l_elem->categoria == funcao)
                  nivel++;
                if(l_elem->passa == valor){
                  fprintf(fp, "     ARMZ %d, %d\n", nivel, l_elem->deslocamento); fflush(fp);
                } 
                else if(l_elem->passa == referencia){
                  fprintf(fp, "     ARMI %d, %d\n", nivel, l_elem->deslocamento); fflush(fp);
                }
              }
              else
                imprimeErro("Erro de atribuicao");
              l_elem = NULL;
            }
;

chamada_procedimento_sem_argumentos:
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
              
              fprintf(fp, "     CHPR %s, %d\n", no->rotulo, nivel_lexico); fflush(fp);
            }
;

chamada_procedimento_com_argumentos:
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
              
              if(no->categoria != procedimento && no->categoria != funcao)
                imprimeErro("Esperava procedimento ou funcao");

              pilhaSimbolos * proc = calloc(1, sizeof(pilhaSimbolos));
              proc->prev = NULL;
              proc->next = NULL;
              proc->rotulo = calloc(4, sizeof(char));
              strcpy(proc->rotulo, no->rotulo);
              proc->identificador = calloc(1, TAM_TOKEN);
              strcpy(proc->identificador, no->identificador);
              proc->nivel_lexico = nivel_lexico;
              proc->categoria = no->categoria;
              proc->num_param = no->num_param;
              proc->deslocamento = 0;
              proc->parametros = no->parametros;

              if (proc->categoria == funcao) {
                fprintf(fp, "     AMEM 1\n");
              }

              queue_append((queue_t**) &tabelaChamada, (queue_t*) proc);
            }
            ABRE_PARENTESES
            lista_de_expressoes
            FECHA_PARENTESES
            {
              // chamar
              pilhaSimbolos *proc = queue_pop((queue_t**) &tabelaChamada);
              fprintf(fp, "     CHPR %s, %d\n", proc->rotulo, nivel_lexico); fflush(fp);
              if (proc->categoria == funcao) {
                pilhaTipos * no = calloc(1, sizeof(pilhaTipos));
                no->tipo = proc->tipov;
                queue_append((queue_t**) &tabelaTipos, (queue_t*) no);
              }
            }
;

lista_de_expressoes: expressao_chamada_procedimento VIRGULA lista_de_expressoes
            | expressao_chamada_procedimento
;

expressao_chamada_procedimento:
            {
              pilhaSimbolos *proc = queue_pop((queue_t**) &tabelaChamada);
              vetParam* no = proc->parametros;
              for (int aux = 0; aux < proc->deslocamento; aux++) { no = no->next; }
              tipo_passagem = no->passa;
              queue_append((queue_t**) &tabelaChamada, (queue_t*) proc);
            }
            expressao
            {
              tipo_passagem = valor;
              pilhaTipos *tipo = queue_pop((queue_t**) &tabelaTipos);
              pilhaSimbolos *proc = queue_pop((queue_t**) &tabelaChamada);
              vetParam* no = proc->parametros;
              for (int aux = 0; aux < proc->deslocamento; aux++) { no = no->next; }
              if (tipo->tipo != no->tipo) {
                imprimeErro("Erro de tipo");
              }
              proc->deslocamento++;
              queue_append((queue_t**) &tabelaChamada, (queue_t*) proc);
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

expressao_simples: expressao_simples MAIS termo
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
            | expressao_simples MENOS termo
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
            | expressao_simples OR termo
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
            | MENOS termo { geraCodigo(NULL, "INVR"); }
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
              if(no->tem_s == 0)
                tipo_var->tipo = no->tipov;
              else if (no->tem_s == 1){
                tipo_var->subtipo = calloc(1, sizeof(pilhaSubtipo));
                tipo_var->tem_sub = 1;
                tipo_var->tipo = no->tipov;
                tipo_var->subtipo->tipo = no->tipov;
                tipo_var->subtipo->subtipo = calloc(16, sizeof(char));
                strcpy(tipo_var->subtipo->subtipo, no->sub);
              }
              int nivel = no->nivel_lexico;
              queue_append((queue_t**) &tabelaTipos, (queue_t*) tipo_var);
              // linha VS coluna PF vlr
              if(no->categoria == variavel_simples && tipo_passagem == valor){
                fprintf(fp, "     CRVL %d, %d\n", nivel, no->deslocamento); fflush(fp);
              }
              // linha PR vlr coluna PF vlr
              else if(no->categoria == parametro_formal && no->passa == valor && tipo_passagem == valor){
                fprintf(fp, "     CRVL %d, %d\n", nivel, no->deslocamento); fflush(fp);
              }
              // linha VS coluna PF ref
              else if(no->categoria == variavel_simples && tipo_passagem == referencia){
                fprintf(fp, "     CREN %d, %d\n", nivel, no->deslocamento); fflush(fp);
              }
              // linha PR vlr coluna PF ref
              else if(no->categoria == parametro_formal && no->passa == valor && tipo_passagem == referencia){
                fprintf(fp, "     CREN %d, %d\n", nivel, no->deslocamento); fflush(fp);
              }
              // linha PR ref coluna PF vlr
              else if(no->categoria == parametro_formal && no->passa == referencia && tipo_passagem == valor){
                fprintf(fp, "     CRVI %d, %d\n", nivel, no->deslocamento); fflush(fp);
              }
              // linha PR ref coluna PF ref
              else if(no->categoria == parametro_formal && no->passa == referencia && tipo_passagem == referencia){
                fprintf(fp, "     CRVL %d, %d\n", nivel, no->deslocamento); fflush(fp);
              }
              else if (no->categoria == funcao) {
                fprintf(fp, "     AMEM 1\n"); fflush(fp);
                fprintf(fp, "     CHPR %s, %d\n", no->rotulo, nivel+1); fflush(fp);
              }
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
            | IDENT chamada_procedimento_com_argumentos
            | ABRE_PARENTESES expressao FECHA_PARENTESES
            | NOT fator { geraCodigo(NULL, "NEGA"); }
;

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
              noElse->rotulo = rotuloFim;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noElse);
              
              pilhaRotulo * noFim = calloc(1, sizeof(pilhaRotulo));
              noFim->rotulo = rotuloElse;
              queue_append((queue_t**) &tabelaRotulo, (queue_t*) noFim);

              pilhaTipos * tipo = queue_pop((queue_t**) &tabelaTipos);

              if(tipo->tipo != tipo_bool){
                imprimeErro("Erro de atribuição");
              }

              fprintf(fp, "     DSVF %s\n", rotuloFim); fflush(fp);
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

              int nivel = no->nivel_lexico;
              if(no->categoria == funcao)
                nivel++;
              fprintf(fp, "     ARMZ %d, %d\n", nivel, no->deslocamento); fflush(fp);
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
  tabelaChamada = NULL;
  tipo_passagem = valor;
  tabelaSubtipo = NULL;

  l_elem = NULL;
  procAtual = NULL;
  RotID = 0;
  num_vars = 0;
  num_vars_aux = 0;
  nivel_lexico = 0;

  yyin=fp;
  yyparse();

  return 0;
}
