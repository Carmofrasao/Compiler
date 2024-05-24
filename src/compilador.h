#ifndef __COMPILADOR__
#define __COMPILADOR__

#include "queue.h"

/* -------------------------------------------------------------------
 *            Arquivo: compilador.h
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

#define TAM_TOKEN 16

typedef enum passagem {
  valor,
  referencia
} passagem;

typedef enum tipo_variavel {
  tipo_int,
  tipo_bool
} tipo_variavel;

typedef enum categoria {
  variavel_simples,
  procedimento,
  parametro_formal,
  funcao
} categoria;

typedef enum simbolos {
  simb_program, simb_var, simb_begin, simb_end, simb_igual, simb_diferente,
  simb_identificador, simb_numero, simb_label, simb_type, simb_menor_que,
  simb_ponto, simb_virgula, simb_ponto_e_virgula, simb_dois_pontos,
  simb_atribuicao, simb_abre_parenteses, simb_fecha_parenteses, simb_false,
  simb_array, simb_procedure, simb_goto, simb_if, simb_else, simb_function,
  simb_then, simb_while, simb_do, simb_or, simb_div, simb_and, simb_true,
  simb_not, simb_menor_ou_igual, simb_maior_ou_igual, simb_maior_que,
  simb_mais, simb_menos, simb_multi, simb_abre_chave, simb_fecha_chave,
  simb_abre_colchete, simb_fecha_colchete, simb_write, simb_read,
} simbolos;

typedef struct vetParam {
  struct vetParam *prev; 
  struct vetParam *next;
  tipo_variavel tipo;
  passagem passa;
} vetParam;

typedef struct pilhaSubtipo {
  struct pilhaSubtipo *prev; 
  struct pilhaSubtipo *next;
  char *subtipo;
  tipo_variavel tipo;
} pilhaSubtipo;

//tabela de símbolos
typedef struct pilhaSimbolos {
  struct pilhaSimbolos *prev; 
  struct pilhaSimbolos *next;
  char *identificador;
  char *rotulo;
  tipo_variavel tipov;
  categoria categoria;
  int nivel_lexico;
  int deslocamento;
  int num_param;
  vetParam *parametros;
  passagem passa;
  int tem_s;
  char * sub;
} pilhaSimbolos;

typedef struct pilhaTipos {
  struct pilhaTipos *prev;
  struct pilhaTipos *next;
  tipo_variavel tipo;
  pilhaSubtipo *subtipo;
  int tem_sub;
} pilhaTipos;

typedef struct pilhaRotulo {
  struct pilhaRotulo *prev;
  struct pilhaRotulo *next;
  char *rotulo; 
} pilhaRotulo;

void geraCodigo (char* rot, char* comando);
int imprimeErro ( char* erro );
char* geraRotulo(int rotId);

/* -------------------------------------------------------------------
 * variáveis globais
 * ------------------------------------------------------------------- */

extern simbolos simbolo, relacao;
extern char token[TAM_TOKEN];
extern int nivel_lexico;
extern int desloc;
extern int nl;
extern FILE* fp;


/* -------------------------------------------------------------------
 * prototipos globais
 * ------------------------------------------------------------------- */

int yylex();
void yyerror(const char *s);

#endif
