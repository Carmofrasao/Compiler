
/* -------------------------------------------------------------------
 *            Arquivo: compilador.l
 * -------------------------------------------------------------------
 *              Autor: Bruno Muller Junior
 *               Data: 08/2007
 *      Atualizado em: [09/08/2020, 19h:01m]
 *
 * -------------------------------------------------------------------
 *
 * Tipos, protótipos e variáveis globais do compilador (via extern)
 *
 * ------------------------------------------------------------------- */

%{


#include<stdio.h>
#include<string.h>

#include "compilador.h"
#include "compilador.tab.h"

//#define IMPRIME(STR) {};
#define IMPRIME(STR) printf("%s# %s \n", STR, token);

int nl = 1;

%}

pulo_linha [\n]

descarte [\t ]+

ident [a-zA-Z][a-zA-Z0-9]*

numero [0-9]+

comentario "(*".*"*)"

%%

{pulo_linha} {nl++;}

{descarte}

{comentario}

program { simbolo  = simb_program;
          IMPRIME("program    ");
          return PROGRAM;
 }

var  { simbolo = simb_var;
          IMPRIME("var        ");
          return VAR;
 }

begin { simbolo = simb_begin;
          IMPRIME("begin      ");
          return T_BEGIN;
 }

end { simbolo = simb_end;
          IMPRIME("end        ");
          return T_END;
 }

:= { simbolo = simb_atribuicao;
          IMPRIME("atribuicao ");
          return ATRIBUICAO;
 }

\; { simbolo = simb_ponto_e_virgula;
          IMPRIME("pt_virgula ");
          return PONTO_E_VIRGULA;
 }

\: { simbolo = simb_dois_pontos;
          IMPRIME("dois_ponto ");
          return DOIS_PONTOS;
 }

\, { simbolo = simb_virgula;
          IMPRIME("virgula    ");
          return VIRGULA;
 }


\. { simbolo = simb_ponto;
          IMPRIME("ponto      ");
          return PONTO;
    }

\(  { simbolo = simb_abre_parenteses;
          IMPRIME("abre_pare  ");
          return ABRE_PARENTESES;
    }

\)  { simbolo = simb_fecha_parenteses;
          IMPRIME("fecha_pare ");
          return FECHA_PARENTESES;
 }

\{  { simbolo = simb_abre_chave;
          IMPRIME("abre_chave ");
          return ABRE_CHAVE;
 }

\}  { simbolo = simb_fecha_chave;
          IMPRIME("fecha_chav ");
          return FECHA_CHAVE;
 }

\[ { simbolo = simb_abre_colchete; 
          IMPRIME("abre_colch ");
          return ABRE_COLCHETE;
 }

\] { simbolo = simb_fecha_colchete;
          IMPRIME("fech_colch ");
          return FECHA_COLCHETE;
 }

\=  { simbolo = simb_igual;
          IMPRIME("igual      ");
          return IGUAL;
 }

\<>  { simbolo = simb_diferente;
          IMPRIME("diferente  ");
          return DIFERENTE;
 }

\<  { simbolo = simb_menor_que;
          IMPRIME("menor_que  ");
          return MENOR_QUE;
 }

\<=  { simbolo = simb_menor_ou_igual;
          IMPRIME("men_ou_igu ");
          return MENOR_OU_IGUAL;
 }

\>=  { simbolo = simb_maior_ou_igual;
          IMPRIME("mai_ou_igu ");
          return MAIOR_OU_IGUAL;
 }

\>  { simbolo = simb_maior_que;
          IMPRIME("maior_que  ");
          return MAIOR_QUE;
 }

\+  { simbolo = simb_mais;
          IMPRIME("mais       ");
          return MAIS;
 }

\-  { simbolo = simb_menos;
          IMPRIME("menos      ");
          return MENOS;
 }

\*  { simbolo = simb_multi;
          IMPRIME("multiplica ");
          return MULTI;
 }

label  { simbolo = simb_label;
          IMPRIME("label      ");
          return LABEL;
 }

type  { simbolo = simb_type;
          IMPRIME("type       ");
          return TYPE;
 }

array  { simbolo = simb_array;
          IMPRIME("array      ");
          return ARRAY;
 }

procedure  { simbolo = simb_procedure;
          IMPRIME("procedure  ");
          return PROCEDURE;
 }

function  { simbolo = simb_function;
          IMPRIME("function   ");
          return FUNCTION;
 }

goto  { simbolo = simb_goto;
          IMPRIME("goto       ");
          return GOTO;
 }

if  { simbolo = simb_if;
          IMPRIME("if         ");
          return IF;
 }

else  { simbolo = simb_else;
          IMPRIME("else       ");
          return ELSE;
 }

then  { simbolo = simb_then;
          IMPRIME("then       ");
          return THEN;
 }

while  { simbolo = simb_while;
          IMPRIME("while      ");
          return WHILE;
 }

do  { simbolo = simb_do;
          IMPRIME("do         ");
          return DO;
 }

or  { simbolo = simb_or;
          IMPRIME("or         ");
          return OR;
 }

div  { simbolo = simb_div;
          IMPRIME("div        ");
          return DIV;
 }

and  { simbolo = simb_and;
          IMPRIME("and        ");
          return AND;
 }

not  { simbolo = simb_not;
          IMPRIME("not        ");
          return NOT;
 }

read  { simbolo = simb_read;
          IMPRIME("read       ");
          return READ;
 }

write  { simbolo = simb_write;
          IMPRIME("write      ");
          return WRITE;
 }

true  { simbolo = simb_true;
          IMPRIME("true       ");
          return TRUE;
 }

false  { simbolo = simb_false;
          IMPRIME("false      ");
          return FALSE;
 }

{numero}  { simbolo = simb_numero;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("numero     ");
          return NUMERO;
 }

{ident} { simbolo = simb_identificador;
          strncpy (token, yytext, TAM_TOKEN);
          IMPRIME("ident      ");
          return IDENT;
        }


%%
