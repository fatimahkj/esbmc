%{

/*
 * This parser is specified based on:
 *
 * c5.y, a ANSI-C grammar written by James A. Roskind.
 * "Portions Copyright (c) 1989, 1990 James A. Roskind".
 * (http://www.idiom.com/free-compilers/,
 * ftp://ftp.infoseek.com/ftp/pub/c++grammar/,
 * ftp://ftp.sra.co.jp/.a/pub/cmd/c++grammar2.0.tar.gz)
 */

#define PARSER ansi_c_parser

#include "ansi_c_parser.h"

int yyansi_clex();
extern char *yyansi_ctext;

#include "parser_static.inc"

#include "y.tab.h"

%}

%union {
  ansi_c_declarationt* decl;
  exprt *expr;
  exprt *loc;  // Might not be an exprt far in the future.
  typet *type;
  void *fake;
};

/*** token declaration **************************************************/

/*** ANSI-C keywords ***/

%token <loc> TOK_AUTO      "auto"
%token <loc> TOK_BOOL      "bool"
%token <loc> TOK_BREAK     "break"
%token <loc> TOK_CASE      "case"
%token <loc> TOK_CHAR      "char"
%token <loc> TOK_CONST     "const"
%token <loc> TOK_CONTINUE  "continue"
%token <loc> TOK_DEFAULT   "default"
%token <loc> TOK_DO        "do"
%token <loc> TOK_DOUBLE    "double"
%token <loc> TOK_ELSE      "else"
%token <loc> TOK_ENUM      "enum"
%token <loc> TOK_EXTERN    "extern"
%token <loc> TOK_FLOAT     "float"
%token <loc> TOK_FOR       "for"
%token <loc> TOK_GOTO      "goto"
%token <loc> TOK_IF        "if"
%token <loc> TOK_INLINE    "inline"
%token <loc> TOK_INT       "int"
%token <loc> TOK_LONG      "long"
%token <loc> TOK_REGISTER  "register"
%token <loc> TOK_RETURN    "return"
%token <loc> TOK_SHORT     "short"
%token <loc> TOK_SIGNED    "signed"
%token <loc> TOK_SIZEOF    "sizeof"
%token <loc> TOK_STATIC    "static"
%token <loc> TOK_STRUCT    "struct"
%token <loc> TOK_SWITCH    "switch"
%token <loc> TOK_TYPEDEF   "typedef"
%token <loc> TOK_UNION     "union"
%token <loc> TOK_UNSIGNED  "unsigned"
%token <loc> TOK_VOID      "void"
%token <loc> TOK_VOLATILE  "volatile"
%token <loc> TOK_WHILE     "while"

/*** multi-character operators ***/

%token <loc> TOK_ARROW
%token <loc> TOK_INCR
%token <loc> TOK_DECR
%token <loc> TOK_SHIFTLEFT
%token <loc> TOK_SHIFTRIGHT
%token <loc> TOK_LE
%token <loc> TOK_GE
%token <loc> TOK_EQ
%token <loc> TOK_NE
%token <loc> TOK_ANDAND
%token <loc> TOK_OROR
%token <loc> TOK_ELLIPSIS
%token <loc> TOK_GCC_ASM_STRING
%token <loc> TOK_GCC_ASM_PAREN
%token <loc> TOK_ASM_STRING

/*** modifying assignment operators ***/

%token <loc> TOK_MULTASSIGN
%token <loc> TOK_DIVASSIGN
%token <loc> TOK_MODASSIGN
%token <loc> TOK_PLUSASSIGN
%token <loc> TOK_MINUSASSIGN
%token <loc> TOK_SLASSIGN
%token <loc> TOK_SRASSIGN
%token <loc> TOK_ANDASSIGN
%token <loc> TOK_EORASSIGN
%token <loc> TOK_ORASSIGN

/*** scanner parsed tokens (these have a value!) ***/

%token <expr> TOK_IDENTIFIER
%token <type> TOK_TYPEDEFNAME
%token <expr> TOK_INTEGER
%token <expr> TOK_FLOATING
%token <expr> TOK_CHARACTER
%token <expr> TOK_STRING

/*** extensions ***/

%token <loc> TOK_INT8
%token <loc> TOK_INT16
%token <loc> TOK_INT32
%token <loc> TOK_INT64
%token <loc> TOK_PTR32
%token <loc> TOK_PTR64
%token <loc> TOK_TYPEOF
%token <loc> TOK_GCC_ASM
%token <loc> TOK_MSC_ASM
%token <loc> TOK_BUILTIN_VA_ARG
%token <loc> TOK_BUILTIN_OFFSETOF

/*** special scanner reports ***/

%token <loc> TOK_SCANNER_ERROR	/* used by scanner to report errors */
%token <loc> TOK_SCANNER_EOF	/* used by scanner to report end of import */

/*** grammar selection ***/

%token <loc> TOK_PARSE_LANGUAGE
%token <loc> TOK_PARSE_EXPRESSION
%token <loc> TOK_PARSE_TYPE

/* Other single char terminals */
%token <loc> '(' ')' '[' ']' '.' '*' ',' '!' '~' '-' '+' '&' '/' '%' '>' '<'
%token <loc> '^' '|' '?' ':' '=' ';' '{' '}'

/*** priority, associativity, etc. definitions **************************/


%start	grammar

%expect 3	/* the famous "dangling `else'" ambiguity */
		/* results in one shift/reduce conflict   */
		/* that we don't want to be reported      */
		/* PLUS +2: KnR ambiguity */

/* Types */
%type <fake> grammar translation_unit external_definition_list
%type <fake> external_definition function_definition

%type <decl> function_head enumerator_declaration

%type <expr> string_literal_list primary_expression builtin_va_arg_expression
%type <expr> builtin_offsetof offsetof_member_designator statement_expression
%type <expr> postfix_expression member_name argument_expression_list
%type <expr> unary_expression cast_expression multiplicative_expression
%type <expr> additive_expression shift_expression relational_expression
%type <expr> equality_expression and_expression exclusive_or_expression
%type <expr> inclusive_or_expression logical_and_expression
%type <expr> logical_or_expression conditional_expression assignment_expression
%type <expr> comma_expression constant_expression comma_expression_opt
%type <expr> default_declaring_list declaring_list aggregate_key
%type <expr> member_declaration_list_opt member_declaration_list
%type <expr> member_declaration member_default_declaring_list
%type <expr> member_declaring_list member_declarator
%type <expr> member_identifier_declarator bit_field_size_opt bit_field_size
%type <expr> enum_key enumerator_list
%type <expr> enumerator_value_opt parameter_type_list KnR_parameter_list
%type <expr> KnR_parameter parameter_list parameter_declaration
%type <expr> identifier_or_typedef_name initializer_opt initializer
%type <expr> initializer_list designated_initializer designated_initializer_list
%type <expr> statement declaration_statement labeled_statement
%type <expr> compound_statement compound_scope statement_list
%type <expr> expression_statement selection_statement
%type <expr> declaration_or_expression_statement iteration_statement
%type <expr> jump_statement gcc_asm_statement msc_asm_statement
%type <expr> gcc_asm_commands gcc_asm_assembler_template
%type <expr> KnR_parameter_header_opt KnR_parameter_header
%type <expr> KnR_parameter_declaration
%type <expr> declarator identifier_declarator unary_identifier_declarator
%type <expr> postfix_identifier_declarator paren_identifier_declarator
%type <expr> identifier integer floating character string constant
%type <expr> declaration

%type <type> declaration_specifier type_specifier declaration_qualifier_list
%type <type> type_qualifier_list declaration_qualifier type_qualifier
%type <type> basic_declaration_specifier basic_type_specifier
%type <type> sue_declaration_specifier sue_type_specifier
%type <type> typedef_declaration_specifier typedef_type_specifier
%type <type> typeof_type_specifier ptr_type_specifier storage_class
%type <type> basic_type_name elaborated_type_name type_name
%type <type> typedef_declarator parameter_typedef_declarator
%type <type> clean_typedef_declarator clean_postfix_typedef_declarator
%type <type> paren_typedef_declarator paren_postfix_typedef_declarator
%type <type> simple_paren_typedef_declarator abstract_declarator
%type <type> parameter_abstract_declarator postfixing_abstract_declarator
%type <type> parameter_postfixing_abstract_declarator array_abstract_declarator
%type <type> unary_abstract_declarator parameter_unary_abstract_declarator
%type <type> postfix_abstract_declarator parameter_postfix_abstract_declarator
%type <type> typedef_name aggregate_name enum_name

%type <loc> volatile_opt gcc_asm_outputs
%type <loc> gcc_asm_inputs
%type <loc> gcc_asm_clobbered_registers gcc_asm_clobbered_registers_list
%type <expr> gcc_asm_input gcc_asm_input_list gcc_asm_output gcc_asm_output_list

%{
/************************************************************************/
/*** rules **************************************************************/
/************************************************************************/
%}
%%

/*** Grammar selection **************************************************/

grammar: TOK_PARSE_LANGUAGE translation_unit {}
	| TOK_PARSE_EXPRESSION comma_expression
	{
	  PARSER.parse_tree.declarations.push_back(ansi_c_declarationt());
	  PARSER.parse_tree.declarations.back().swap(*$2);
	}
	| TOK_PARSE_TYPE type_name {}
	;

/*** Token with values **************************************************/


identifier:
	TOK_IDENTIFIER
	;

typedef_name:
	TOK_TYPEDEFNAME
	;

integer:
	TOK_INTEGER
	;

floating:
	TOK_FLOATING
	;

character:
	TOK_CHARACTER
	;

string:
	TOK_STRING
	;

/*** Constants **********************************************************/

/* note: the following has been changed from the ANSI-C grammar:	*/
/*	- constant includes string_literal_list (cleaner)		*/

constant:
	integer
	| floating
	| character
	| string_literal_list
	;

string_literal_list:
	string
	| string_literal_list string
	{ $$ = $1;
	  // do concatenation
	  $$->value($$->value().as_string()+$2->value().as_string());
	}
	;

/*** Expressions ********************************************************/

primary_expression:
	identifier
	| constant
	| '(' comma_expression ')'
	{ $$ = $2; }
	| statement_expression
	| builtin_va_arg_expression
	| builtin_offsetof
	;

builtin_va_arg_expression:
	TOK_BUILTIN_VA_ARG '(' assignment_expression ',' type_name ')'
	{
	  $$=$1;
	  $$->id("builtin_va_arg");
	  mto($$, $3);
	  $$->type().swap(*$5);
	}
	;

builtin_offsetof:
	TOK_BUILTIN_OFFSETOF '(' type_name ',' offsetof_member_designator ')'
	{
	  $$=$1;
	  $$->id("builtin_offsetof");
	  $$->offsetof_type(*$3);
	  $$->member_irep(*$5);
	}
	;

offsetof_member_designator:
          member_name
        | offsetof_member_designator '.' member_name
        | offsetof_member_designator '[' comma_expression ']'
        ;                  

statement_expression: '(' compound_statement ')'
	{ init(&$$, "sideeffect");
	  $$->statement("statement_expression");
          mto($$, $2);
	}
	;

postfix_expression:
	primary_expression
	| postfix_expression '[' comma_expression ']'
	{ binary($$, $1, $2, "index", $3); }
	| postfix_expression '(' ')'
	{ $$=$2;
	  set(*$$, "sideeffect");
	  $$->operands().resize(2);
	  $$->op0().swap(*$1);
	  $$->op1().clear();
	  $$->op1().id("arguments");
	  $$->statement("function_call");
	}
	| postfix_expression '(' argument_expression_list ')'
	{ $$=$2;
	  init(&$$, "sideeffect");
	  $$->statement("function_call");
	  $$->operands().resize(2);
	  $$->op0().swap(*$1);
	  $$->op1().swap(*$3);
	  $$->op1().id("arguments");
	}
	| postfix_expression '.' member_name
	{ $$=$2;
	  set(*$$, "member");
	  mto($$, $1);
	  $$->component_name($3->cmt_base_name());
	}
	| postfix_expression TOK_ARROW member_name
	{ $$=$2;
	  set(*$$, "ptrmember");
	  mto($$, $1);
	  $$->component_name($3->cmt_base_name());
	}
	| postfix_expression TOK_INCR
	{ $$=$2;
	  init(&$$, "sideeffect");
	  mto($$, $1);
	  $$->statement("postincrement");
	}
	| postfix_expression TOK_DECR
	{ $$=$2;
	  init(&$$, "sideeffect");
	  mto($$, $1);
	  $$->statement("postdecrement");
	}
	;

member_name:
	identifier
	| typedef_name
	{ $$ = (exprt *)$1; /* XXX typing */}
	;

argument_expression_list:
	assignment_expression
	{
	  init(&$$, "expression_list");
	  mto($$, $1);
	}
	| argument_expression_list ',' assignment_expression
	{
	  $$=$1;
	  mto($$, $3);
	}
	;

unary_expression:
	postfix_expression
	| TOK_INCR unary_expression
	{ $$=$1;
	  set(*$$, "sideeffect");
	  $$->statement("preincrement");
	  mto($$, $2);
	}
	| TOK_DECR unary_expression
	{ $$=$1;
	  set(*$$, "sideeffect");
	  $$->statement("predecrement");
	  mto($$, $2);
	}
	| '&' cast_expression
	{ $$=$1;
	  set(*$$, "address_of");
	  mto($$, $2);
	}
	| '*' cast_expression
	{ $$=$1;
	  set(*$$, "dereference");
	  mto($$, $2);
	}
	| '+' cast_expression
	{ $$=$1;
	  set(*$$, "unary+");
	  mto($$, $2);
	}
	| '-' cast_expression
	{ $$=$1;
	  set(*$$, "unary-");
	  mto($$, $2);
	}
	| '~' cast_expression
	{ $$=$1;
	  set(*$$, "bitnot");
	  mto($$, $2);
	}
	| '!' cast_expression
	{ $$=$1;
	  set(*$$, "not");
	  mto($$, $2);
	}
	| TOK_SIZEOF unary_expression
	{ $$=$1;
	  set(*$$, "sizeof");
	  mto($$, $2);
	}
	| TOK_SIZEOF '(' type_name ')'
	{ $$=$1;
	  set(*$$, "sizeof");
	  $$->sizeof_type(*$3);
	}
	;

cast_expression:
	unary_expression
	| '(' type_name ')' cast_expression
	{
	  $$=$1;
	  set(*$$, "typecast");
	  mto($$, $4);
	  $$->type().swap(*$2);
	}
	/* The following is a GCC extension
	   to allow a 'temporary union' */
	| '(' type_name ')' '{' designated_initializer_list '}'
	{
	  exprt tmp("designated_list");
	  tmp.operands().swap($5->operands());
	  $$=$1;
	  set(*$$, "typecast");
	  $$->move_to_operands(tmp);
	  $$->type().swap(*$2);
	}
	;

multiplicative_expression:
	cast_expression
	| multiplicative_expression '*' cast_expression
	{ binary($$, $1, $2, "*", $3); }
	| multiplicative_expression '/' cast_expression
	{ binary($$, $1, $2, "/", $3); }
	| multiplicative_expression '%' cast_expression
	{ binary($$, $1, $2, "mod", $3); }
	;

additive_expression:
	multiplicative_expression
	| additive_expression '+' multiplicative_expression
	{ binary($$, $1, $2, "+", $3); }
	| additive_expression '-' multiplicative_expression
	{ binary($$, $1, $2, "-", $3); }
	;

shift_expression:
	additive_expression
	| shift_expression TOK_SHIFTLEFT additive_expression
	{ binary($$, $1, $2, "shl", $3); }
	| shift_expression TOK_SHIFTRIGHT additive_expression
	{ binary($$, $1, $2, "shr", $3); }
	;

relational_expression:
	shift_expression
	| relational_expression '<' shift_expression
	{ binary($$, $1, $2, "<", $3); }
	| relational_expression '>' shift_expression
	{ binary($$, $1, $2, ">", $3); }
	| relational_expression TOK_LE shift_expression
	{ binary($$, $1, $2, "<=", $3); }
	| relational_expression TOK_GE shift_expression
	{ binary($$, $1, $2, ">=", $3); }
	;

equality_expression:
	relational_expression
	| equality_expression TOK_EQ relational_expression
	{ binary($$, $1, $2, "=", $3); }
	| equality_expression TOK_NE relational_expression
	{ binary($$, $1, $2, "notequal", $3); }
	;

and_expression:
	equality_expression
	| and_expression '&' equality_expression
	{ binary($$, $1, $2, "bitand", $3); }
	;

exclusive_or_expression:
	and_expression
	| exclusive_or_expression '^' and_expression
	{ binary($$, $1, $2, "bitxor", $3); }
	;

inclusive_or_expression:
	exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
	{ binary($$, $1, $2, "bitor", $3); }
	;

logical_and_expression:
	inclusive_or_expression
	| logical_and_expression TOK_ANDAND inclusive_or_expression
	{ binary($$, $1, $2, "and", $3); }
	;

logical_or_expression:
	logical_and_expression
	| logical_or_expression TOK_OROR logical_and_expression
	{ binary($$, $1, $2, "or", $3); }
	;

conditional_expression:
	logical_or_expression
	| logical_or_expression '?' comma_expression ':' conditional_expression
	{ $$=$2;
	  init(&$$, "if");
	  mto($$, $1);
	  mto($$, $3);
	  mto($$, $5);
	}
	| logical_or_expression '?' ':' conditional_expression
	{ $$=$2;
	  init(&$$, "sideeffect");
	  $$->statement("gcc_conditional_expression");
	  mto($$, $1);
	  mto($$, $4);
	}
	;

assignment_expression:
	conditional_expression
	| cast_expression '=' assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign"); }
	| cast_expression TOK_MULTASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign*"); }
	| cast_expression TOK_DIVASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign_div"); }
	| cast_expression TOK_MODASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign_mod"); }
	| cast_expression TOK_PLUSASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign+"); }
	| cast_expression TOK_MINUSASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign-"); }
	| cast_expression TOK_SLASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign_shl"); }
	| cast_expression TOK_SRASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign_shr"); }
	| cast_expression TOK_ANDASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign_bitand"); }
	| cast_expression TOK_EORASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign_bitxor"); }
	| cast_expression TOK_ORASSIGN assignment_expression
	{ binary($$, $1, $2, "sideeffect", $3); $$->statement("assign_bitor"); }
	;

comma_expression:
	assignment_expression
	| comma_expression ',' assignment_expression
	{ binary($$, $1, $2, "comma", $3); }
	;

constant_expression:
	assignment_expression
	;

comma_expression_opt:
	/* nothing */
	{ init(&$$); $$->make_nil(); }
	| comma_expression
	;

/*** Declarations *******************************************************/


declaration:
	declaration_specifier ';'
	{
	  $$ = (exprt*)$1;
	}
	| type_specifier ';'
	{
	  $$ = (exprt*)$1;
	}
	| declaring_list ';'
	{
	  $$ = $1;
	}
	| default_declaring_list ';'
	{
	  $$ = $1;
	}
	;

default_declaring_list:
	declaration_qualifier_list identifier_declarator
		{
		  init(&($<decl>$));
		  PARSER.new_declaration(*$1, *$2, *$<decl>$);
		}
	initializer_opt
		{
		  init(&($<expr>$));
		  $<expr>$->type()=*$1;
		  decl_statement(*$<expr>$, *$<decl>3, *$4);
		}
	| type_qualifier_list identifier_declarator
	{
	  init(&$<decl>$);
	  PARSER.new_declaration(*$1, *$2, *$<decl>$);
	}
	initializer_opt
	{
	  init(&$<expr>$);
	  $<expr>$->type()=*$1;
	  decl_statement(*$<expr>$, *$<decl>3, *$4);
	}
	| default_declaring_list ',' identifier_declarator
		{
		  init(&$<decl>$);
		  const irept &t=$1->type();
		  PARSER.new_declaration(t, *$3, *$<decl>$);
		}
		initializer_opt
	{
	  $<expr>$=$1;
	  decl_statement(*$<expr>$, *$<decl>4, *$5);
	}
	;

declaring_list:			/* DeclarationSpec */
	declaration_specifier declarator
		{
		  // the symbol has to be visible during initialization
		  init(&$<decl>$);
		  PARSER.new_declaration(*$1, *$2, *$<decl>$);
		}
		initializer_opt
	{
	  init(&$<expr>$);
	  $<expr>$->type()=*$1;
	  decl_statement(*$<expr>$, *$<decl>3, *$4);
	}
	| type_specifier declarator
		{
		  // the symbol has to be visible during initialization
		  init(&$<decl>$);
		  PARSER.new_declaration(*$1, *$2, *$<decl>$);
		}
		initializer_opt
	{
	  init(&$<expr>$);
	  $<expr>$->type()=*$1;
	  decl_statement(*$<expr>$, *$<decl>3, *$4);
	}
	| declaring_list ',' declarator
		{
		  init(&$<decl>$);
		  const irept &t=$1->type();
		  PARSER.new_declaration(t, *$3, *$<decl>$);
		}
		initializer_opt
	{
	  $<expr>$=$1;
	  decl_statement(*$<expr>$, *$<decl>4, *$5);
	}
	;

declaration_specifier:
	basic_declaration_specifier
	| sue_declaration_specifier
	| typedef_declaration_specifier
	;

type_specifier:
	basic_type_specifier
	| sue_type_specifier
	| typedef_type_specifier
	| typeof_type_specifier
	;

declaration_qualifier_list:
	storage_class
	| type_qualifier_list storage_class
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| declaration_qualifier_list declaration_qualifier
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	;

type_qualifier_list:
	type_qualifier
	| type_qualifier_list type_qualifier
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	;

declaration_qualifier:
	storage_class
	| type_qualifier
	;

type_qualifier:
	TOK_CONST      { $$=(typet*)$1; set(*$$, "const"); }
	| TOK_VOLATILE { $$=(typet*)$1; set(*$$, "volatile"); }
	;

basic_declaration_specifier:
	declaration_qualifier_list basic_type_name
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| basic_type_specifier storage_class
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| basic_declaration_specifier declaration_qualifier
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| basic_declaration_specifier basic_type_name
	{
	  $$=$1;
	  merge_types($$, $2);
	};

basic_type_specifier:
	basic_type_name
	| type_qualifier_list basic_type_name
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| basic_type_specifier type_qualifier
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| basic_type_specifier basic_type_name
	{
	  $$=$1;
	  merge_types($$, $2);
	};

sue_declaration_specifier:
	declaration_qualifier_list elaborated_type_name
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| sue_type_specifier storage_class
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| sue_declaration_specifier declaration_qualifier
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	;

sue_type_specifier:
	elaborated_type_name
	| type_qualifier_list elaborated_type_name
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| sue_type_specifier type_qualifier
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	;

typedef_declaration_specifier:	/* DeclarationSpec */
	typedef_type_specifier storage_class
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| declaration_qualifier_list typedef_name
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| typedef_declaration_specifier declaration_qualifier
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	;

typedef_type_specifier:		/* Type */
	typedef_name
	| type_qualifier_list typedef_name
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	| typedef_type_specifier type_qualifier
	{
	  $$=$1;
	  merge_types($$, $2);
	}
	;

typeof_type_specifier:
	TOK_TYPEOF '(' comma_expression ')'
	{ $$ = (typet*)$3;
	  locationt location=$$->location();
	  typet new_type("type_of");
	  new_type.subtype() = (typet &)*$$;
	  $$->swap(new_type);
	  $$->location()=location;
	  $$->is_expression(true);
	}
	| TOK_TYPEOF '(' ptr_type_specifier  ')'
	{ $$ = $3;
	  locationt location=$$->location();
	  typet new_type("type_of");
	  new_type.subtype() = (typet &)*$$;
	  $$->swap(new_type);
	  $$->location()=location;
	  $$->is_expression(false);
	}
	;

ptr_type_specifier:
	type_specifier
	| ptr_type_specifier '*'
	{ $$ = $1;
	  locationt location=$$->location();
	  typet new_type("pointer");
	  new_type.subtype() = *$$;
	  $$->swap(new_type);
	  $$->location()=location;
	}
	;

storage_class:
	TOK_TYPEDEF    { $$=(typet*)$1; set(*$$, "typedef"); }
	| TOK_EXTERN   { $$=(typet*)$1; set(*$$, "extern"); }
	| TOK_STATIC   { $$=(typet*)$1; set(*$$, "static"); }
	| TOK_AUTO     { $$=(typet*)$1; set(*$$, "auto"); }
	| TOK_REGISTER { $$=(typet*)$1; set(*$$, "register"); }
	| TOK_INLINE   { $$=(typet*)$1; set(*$$, "inline"); }
	;

basic_type_name:
	TOK_INT        { $$=(typet*)$1; set(*$$, "int"); }
	| TOK_INT8     { $$=(typet*)$1; set(*$$, "int8"); }
	| TOK_INT16    { $$=(typet*)$1; set(*$$, "int16"); }
	| TOK_INT32    { $$=(typet*)$1; set(*$$, "int32"); }
	| TOK_INT64    { $$=(typet*)$1; set(*$$, "int64"); }
	| TOK_PTR32    { $$=(typet*)$1; set(*$$, "ptr32"); }
	| TOK_PTR64    { $$=(typet*)$1; set(*$$, "ptr64"); }
	| TOK_CHAR     { $$=(typet*)$1; set(*$$, "char"); }
	| TOK_SHORT    { $$=(typet*)$1; set(*$$, "short"); }
	| TOK_LONG     { $$=(typet*)$1; set(*$$, "long"); }
	| TOK_FLOAT    { $$=(typet*)$1; set(*$$, "float"); }
	| TOK_DOUBLE   { $$=(typet*)$1; set(*$$, "double"); }
	| TOK_SIGNED   { $$=(typet*)$1; set(*$$, "signed"); }
	| TOK_UNSIGNED { $$=(typet*)$1; set(*$$, "unsigned"); }
	| TOK_VOID     { $$=(typet*)$1; set(*$$, "empty"); }
	| TOK_BOOL     { $$=(typet*)$1; set(*$$, "bool"); }
	;

elaborated_type_name:
	aggregate_name
	| enum_name
	;

aggregate_name:
	aggregate_key
		{
		  // an anon struct
		  exprt symbol("symbol");

		  symbol.cmt_base_name(PARSER.get_anon_name());

		  init(&$<expr>$);
		  PARSER.new_declaration(*$1, symbol, *$<expr>$, true);
		}
		'{' member_declaration_list_opt '}'
	{
	  typet &type=$<expr>2->type();
	  irept comp = type.components();
	  comp.get_sub() = (std::vector<irept> &)$4->operands();
	  type.components(comp);
          $4->operands().clear();

	  // grab symbol
	  init(&$$, "symbol");
	  $$->identifier($<expr>2->name());
	  $$->location()=$<expr>2->location();

	  PARSER.move_declaration(*$<expr>2);
	}
	| aggregate_key identifier_or_typedef_name
		{
		  init(&$<expr>$);
		  PARSER.new_declaration(*$1, *$2, *$<expr>$, true);

		  exprt tmp(*$<expr>$);
		  tmp.type().id("incomplete_"+tmp.type().id_string());
		  PARSER.move_declaration(tmp);
		}
		'{' member_declaration_list_opt '}'
	{
	  typet &type=$<expr>3->type();
	  irept comp = type.components();
	  comp.get_sub() = (std::vector<irept> &)$5->operands();
	  type.components(comp);
          $5->operands().clear();

	  // grab symbol
	  init(&$$, "symbol");
	  $$->identifier($<expr>3->name());
	  $$->location()=$<expr>3->location();

	  PARSER.move_declaration(*$<expr>3);
	}
	| aggregate_key identifier_or_typedef_name
	{
	  do_tag((typet&)*$1, (typet&)*$2);
	  $$=(typet*)$2;
	}
	;

aggregate_key:
	TOK_STRUCT
	{ $$=$1; set(*$$, "struct"); }
	| TOK_UNION
	{ $$=$1; set(*$$, "union"); }
	;

member_declaration_list_opt:
		  /* Nothing */
	{
	  init(&$$, "declaration_list");
	}
	| member_declaration_list
	;

member_declaration_list:
	  member_declaration
	| member_declaration_list member_declaration
	{
	  assert($1->id()=="declaration_list");
	  assert($2->id()=="declaration_list");
	  $$=$1;
	  Forall_operands(it, *$2)
	    $$->move_to_operands(*it);
	  $2->clear();
	}
	;

member_declaration:
	member_declaring_list ';'
	| member_default_declaring_list ';'
	| ';' /* empty declaration */
	{
	  init(&$$, "declaration_list");
	}
	;

member_default_declaring_list:
	type_qualifier_list member_identifier_declarator
	{
	  init(&$$, "declaration_list");

	  exprt declaration;

	  PARSER.new_declaration(*$1, *$2, declaration, false, false);

	  $$->move_to_operands(declaration);
	}
	| member_default_declaring_list ',' member_identifier_declarator
	{
	  exprt declaration;

	  typet type;
	  PARSER.new_declaration(*$1, *$3, declaration, false, false);

	  $$=$1;
	  $$->move_to_operands(declaration);
	}
	;

member_declaring_list:
	type_specifier member_declarator
	{
	  init(&$$, "declaration_list");

	  // save the type_specifier
	  $$->declaration_type(*$1);

	  exprt declaration;
	  PARSER.new_declaration(*$1, *$2, declaration, false, false);

	  $$->move_to_operands(declaration);
	}
	| member_declaring_list ',' member_declarator
	{
	  exprt declaration;

	  irept declaration_type($1->declaration_type());
	  PARSER.new_declaration(declaration_type, *$3, declaration, false, false);

	  $$=$1;
	  $$->move_to_operands(declaration);
	}
	;

member_declarator:
	declarator bit_field_size_opt
	{
	  if(!$2->is_nil())
	  {
	    $$=$2;
	    // Shift name of member upwards
	    $$->decl_ident($1->decl_ident());
	    $1->remove("decl_ident");
	    ((typet*)$$)->subtype() = ((typet*)$1)->subtype();
	  }
	  else
	    $$=$1;
	}
	| /* empty */
	{
	  init(&$$);
	  $$->make_nil();
	}
	| bit_field_size
	{
	  $$=$1;
	  ((typet*)$$)->subtype().make_nil();
	}
	;

member_identifier_declarator:
	identifier_declarator
		{ /* note: this mid-rule action (suggested by the grammar) */
		  /*       is not used because we don't have direct access */
		  /*       to the declaration specifier; therefore the     */
		  /*       symbol table is not updated ASAP (which is only */
		  /*       a minor problem; bit_field_size_opt expression  */
		  /*       cannot use the identifier_declarator)           */
		 }
		bit_field_size_opt
	{
	  $$=$1;
	  if(!$3->is_nil())
	    merge_types((typet&)*$$, (typet&)*$3);
	}
	| bit_field_size
	{
	  // TODO
	  assert(0);
	}
	;

bit_field_size_opt:
	/* nothing */
	{
	  init(&$$);
	  $$->make_nil();
	}
	| bit_field_size
	;

bit_field_size:			/* Expression */
	':' constant_expression
	{
	  $$=$1; set(*$$, "c_bitfield");
	  $$->size(*$2);
	}
	;

/* note: although the grammar didn't suggest mid-rule actions here	*/
/*       we handle enum exactly like struct/union			*/
enum_name:			/* Type */
	enum_key
		{
		  // an anon enum
		  exprt symbol("symbol");
		  symbol.cmt_base_name(PARSER.get_anon_name());

		  init(&$<expr>$);
		  PARSER.new_declaration(*$1, symbol, *$<expr>$, true);

		  exprt tmp(*$<expr>$);
		  PARSER.move_declaration(tmp);
		}
		'{' enumerator_list '}'
	{
	  // grab symbol
	  init(&$$, "symbol");
	  $$->identifier($<expr>2->name());
	  $$->location()=$<expr>2->location();

	  do_enum_members(*$$, *$4);

	  PARSER.move_declaration(*$<expr>2);
	}
	| enum_key identifier_or_typedef_name
		{ /* !!! mid-rule action !!! */
		  init(&$<expr>$);
		  PARSER.new_declaration(*$1, *$2, *$<expr>$, true);

		  exprt tmp(*$<expr>$);
		  PARSER.move_declaration(tmp);
		}
		'{' enumerator_list '}'
	{
	  // grab symbol
	  init(&$$, "symbol");
	  $$->identifier($<expr>3->name());
	  $$->location()=$<expr>3->location();

	  do_enum_members(*$$, *$5);

	  PARSER.move_declaration(*$<expr>3);
	}
	| enum_key identifier_or_typedef_name
	{
	  do_tag((typet&)*$1, (typet&)*$2);
	  $$=(typet*)$2;
	}
	;

enum_key: TOK_ENUM
	{
	  $$=$1;
	  set(*$$, "c_enum");
	}
	;

enumerator_list:		/* MemberList */
	enumerator_declaration
	{
	  init(&$$);
	  mto($$, $1);
	}
	| enumerator_list ',' enumerator_declaration
	{
	  $$=$1;
	  mto($$, $3);
	}
	| enumerator_list ','
	{
	  $$=$1;
	}
	;

enumerator_declaration:
	  identifier_or_typedef_name enumerator_value_opt
	{
	  init(&$$);
	  irept type("enum");
	  PARSER.new_declaration(type, *$1, *$$);
	  $$->is_macro(true);
	  $$->decl_value() = *$2;
	}
	;

enumerator_value_opt:		/* Expression */
	/* nothing */
	{
	  init(&$$);
	  $$->make_nil();
	}
	| '=' constant_expression
	{
	  $$=$2;
	}
	;

parameter_type_list:		/* ParameterList */
	parameter_list
	| parameter_list ',' TOK_ELLIPSIS
	{
	  typet tmp("ansi_c_ellipsis");
	  $$=$1;
	  ((typet &)*$$).move_to_subtypes(tmp);
	}
	| KnR_parameter_list
	;

KnR_parameter_list:
	KnR_parameter
	{
          init(&$$, "arguments");
          mts((typet*)$$, (typet*)$1);
	}
	| KnR_parameter_list ',' KnR_parameter
	{
          $$=$1;
          mts((typet*)$$, (typet*)$3);
	}
	;

KnR_parameter: identifier
	{
          init(&$$);
	  irept type("KnR");
	  PARSER.new_declaration(type, *$1, *$$);
	}
	;

parameter_list:
	parameter_declaration
	{
	  init(&$$, "arguments");
	  mts((typet*)$$, (typet*)$1);
	}
	| parameter_list ',' parameter_declaration
	{
	  $$=$1;
	  mts((typet*)$$, (typet*)$3);
	}
	;

parameter_declaration:
	declaration_specifier
	{
	  init(&$$);
	  exprt nil;
	  nil.make_nil();
	  PARSER.new_declaration(*$1, nil, *$$);
	}
	| declaration_specifier parameter_abstract_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| declaration_specifier identifier_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| declaration_specifier parameter_typedef_declarator
	{
          // the second tree is really the argument -- not part
          // of the type!
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| declaration_qualifier_list
	{
	  init(&$$);
	  exprt nil;
	  nil.make_nil();
	  PARSER.new_declaration(*$1, nil, *$$);
	}
	| declaration_qualifier_list parameter_abstract_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| declaration_qualifier_list identifier_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| type_specifier
	{
	  init(&$$);
	  exprt nil;
	  nil.make_nil();
	  PARSER.new_declaration(*$1, nil, *$$);
	}
	| type_specifier parameter_abstract_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| type_specifier identifier_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| type_specifier parameter_typedef_declarator
	{
          // the second tree is really the argument -- not part
          // of the type!
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| type_qualifier_list
	{
	  init(&$$);
	  exprt nil;
	  nil.make_nil();
	  PARSER.new_declaration(*$1, nil, *$$);
	}
	| type_qualifier_list parameter_abstract_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	| type_qualifier_list identifier_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	}
	;

identifier_or_typedef_name:
	identifier
	| typedef_name
	{ $$ = (exprt*)$1; /* XXX typing */}
	;

type_name:
	type_specifier
	| type_specifier abstract_declarator
	{
	  $$=$1;
	  make_subtype(*$$, *$2);
	}
	| type_qualifier_list
	| type_qualifier_list abstract_declarator
	{
	  $$=$1;
	  make_subtype(*$$, *$2);
	}
	;

initializer_opt:
	/* nothing */
	{
	  init(&$$);
	  $$->make_nil();
	}
	| '=' initializer
	{ $$ = $2; }
	;

/* note: the following has been changed from the ANSI-C grammar:	*/
/*	- an initializer is not an assignment_expression,		*/
/*	  but a constant_expression					*/
/*	  (which probably is the case anyway for 99.9% of C programs)	*/

initializer:
	'{' initializer_list '}'
	{
	  $$=$1;
	  set(*$$, "constant");
	  $$->type().id("incomplete_array");
	  $$->operands().swap($2->operands());
	}
	| '{' initializer_list ',' '}'
	{
	  $$=$1;
	  set(*$$, "constant");
	  $$->type().id("incomplete_array");
	  $$->operands().swap($2->operands());
	}
	| constant_expression	/* was: assignment_expression */
	| '{' designated_initializer_list '}'
	{
	  $$=$1;
	  set(*$$, "designated_list");
	  $$->operands().swap($2->operands());
	}
	;

initializer_list:
	initializer
	{
	  $$=$1;
	  exprt tmp;
	  tmp.swap(*$$);
	  $$->clear();
	  $$->move_to_operands(tmp);
	}
	| initializer_list ',' initializer
	{
	  $$=$1;
	  mto($$, $3);
	}
	;

/* GCC extension: designated initializer */
designated_initializer:
          /* empty */
        {
	  init(&$$);
	  $$->make_nil();
        }
        | '.' identifier '=' initializer
        {
          $$=$1;
          $$->id("designated_initializer");
          $$->component_name($2->cmt_base_name());
          $$->move_to_operands(*$4);
        }
        ;

designated_initializer_list:
	designated_initializer
	{
	  $$=$1;
	  exprt tmp;
	  tmp.swap(*$$);
	  $$->clear();

	  if(tmp.is_not_nil())
            $$->move_to_operands(tmp);
	}
	| designated_initializer_list ',' designated_initializer
	{
	  $$=$1;
	  if($3->is_not_nil())
	    mto($$, $3);
	}
	;

/*** Statements *********************************************************/

statement:
	  labeled_statement
	| compound_statement
	| declaration_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	| gcc_asm_statement
	| msc_asm_statement
	;

declaration_statement:
	declaration
	{
	  init(&$$);
	  statement(*$$, "decl-block");
	  $$->operands().swap($1->operands());
	}
	;

labeled_statement:
	identifier_or_typedef_name ':' statement
	{
	  $$=$2;
	  statement(*$$, "label");
	  $$->label($1->cmt_base_name());
	  mto($$, $3);
	}
	| TOK_CASE constant_expression ':' statement
	{
	  $$=$1;
	  statement(*$$, "label");
	  mto($$, $4);
	  exprt tmp("");
	  tmp.move_to_operands(*$2);
	  $$->case_irep(tmp);
	}
	| TOK_DEFAULT ':' statement
	{
	  $$=$1;
	  statement(*$$, "label");
	  mto($$, $3);
	  $$->dfault(true);
	}
	;

/* note: the following has been changed from the ANSI-C grammar:	*/
/*	- rule compound_scope is used to prepare an inner scope for	*/
/*	  each compound_statement (and to obtain the line infos)	*/

compound_statement:
	compound_scope '{' '}'
	{
	  $$=$2;
	  statement(*$$, "block");
	  $$->end_location($3->location());
	  PARSER.pop_scope();
	}
	| compound_scope '{' statement_list '}'
	{
	  $$=$3;
	  $$->location()=$2->location();
	  $$->end_location($4->location());
	  PARSER.pop_scope();
	}
	;

compound_scope:
	/* nothing */
	{
	  unsigned prefix=++PARSER.current_scope().compound_counter;
	  PARSER.new_scope(i2string(prefix)+"::");
	}
	;

statement_list:
	statement
	{
	  $$=$1;
	  to_code(*$$).make_block();
	}
	| statement_list statement
	{
	  mto($$, $2);
	}
	;

expression_statement:
	comma_expression_opt ';'
	{
	  $$=$2;

	  if($1->is_nil())
	    statement(*$$, "skip");
	  else
	  {
	    statement(*$$, "expression");
	    mto($$, $1);
	  }
	}
	;

selection_statement:
	  TOK_IF '(' comma_expression ')' statement
	{
	  $$=$1;
	  statement(*$$, "ifthenelse");
	  mto($$, $3);
	  mto($$, $5);
	}
	| TOK_IF '(' comma_expression ')' statement TOK_ELSE statement
	{
	  $$=$1;
	  statement(*$$, "ifthenelse");
	  mto($$, $3);
	  mto($$, $5);
	  mto($$, $7);
	}
	| TOK_SWITCH '(' comma_expression ')' statement
	{
	  $$=$1;
	  statement(*$$, "switch");
	  mto($$, $3);
	  mto($$, $5);
	}
	;

declaration_or_expression_statement:
	  declaration_statement
	| expression_statement
	;

iteration_statement:
	TOK_WHILE '(' comma_expression_opt ')' statement
	{
	  $$=$1;
	  statement(*$$, "while");
	  mto($$, $3);
	  mto($$, $5);
	}
	| TOK_DO statement TOK_WHILE '(' comma_expression ')' ';'
	{
	  $$=$1;
	  statement(*$$, "dowhile");
	  mto($$, $5);
	  mto($$, $2);
	}
	| TOK_FOR '(' declaration_or_expression_statement
		comma_expression_opt ';' comma_expression_opt ')' statement
	{
	  $$=$1;
	  statement(*$$, "for");
	  mto($$, $3);
	  mto($$, $4);
	  mto($$, $6);
	  mto($$, $8);
	}
	;

jump_statement:
	TOK_GOTO identifier_or_typedef_name ';'
	{
	  $$=$1;
	  statement(*$$, "goto");
	  $$->destination($2->cmt_base_name());
	}
	| TOK_CONTINUE ';'
	{ $$=$1; statement(*$$, "continue"); }
	| TOK_BREAK ';'
	{ $$=$1; statement(*$$, "break"); }
	| TOK_RETURN ';'
	{ $$=$1; statement(*$$, "return"); }
	| TOK_RETURN comma_expression ';'
	{ $$=$1; statement(*$$, "return"); mto($$, $2); }
	;

gcc_asm_statement:
	TOK_GCC_ASM_PAREN volatile_opt '(' gcc_asm_commands ')' ';'
	{ $$=$1;

	  statement(*$$, "asm");
	  $$->flavor("gcc");
	  $$->operands().swap($4->operands());
	}
	| TOK_GCC_ASM_PAREN '{' TOK_ASM_STRING '}'
	{
	  $$=$1;
	  statement(*$$, "asm");
	  $$->flavor("gcc");
	  statement(*$$, "asm");
	  $$->flavor("gcc");
	  mto($$, $3);
	}
	;


msc_asm_statement:
	TOK_MSC_ASM '{' TOK_STRING '}'
	{ $$=$1;
	  statement(*$$, "asm");
	  $$->flavor("msc"); }
	| TOK_MSC_ASM TOK_STRING
	{ $$=$1;
	  statement(*$$, "asm");
	  $$->flavor("msc"); }
	;

volatile_opt:
	{ $$ = NULL; }
          /* nothing */
        | TOK_VOLATILE
        ;

/* asm ( assembler template
           : output operands                  // optional
           : input operands                   // optional
           : list of clobbered registers      // optional
           );
*/

gcc_asm_commands:
	gcc_asm_assembler_template
	  {
	    init(&$$);
	    mto($$, $1);
	  }
	| gcc_asm_assembler_template gcc_asm_outputs
	  {
	    init(&$$);
	    mto($$, $1);
	  }
	| gcc_asm_assembler_template gcc_asm_outputs gcc_asm_inputs
	  {
	    init(&$$);
	    mto($$, $1);
	  }
	| gcc_asm_assembler_template gcc_asm_outputs gcc_asm_inputs gcc_asm_clobbered_registers
	  {
	    init(&$$);
	    mto($$, $1);
	  }
	;

gcc_asm_assembler_template: string_literal_list
	  ;

gcc_asm_outputs:
	  ':' gcc_asm_output_list
	| ':'
	;

gcc_asm_output:
	  string_literal_list '(' comma_expression ')'
	| '[' identifier_or_typedef_name ']'
	  string_literal_list '(' comma_expression ')'
        { $$ = $2; /* XXXjmorse dummy */ }
	;

gcc_asm_output_list:
	  gcc_asm_output
	| gcc_asm_output_list ',' gcc_asm_output
	;

gcc_asm_inputs:
	  ':' gcc_asm_input_list
	| ':'
	;

gcc_asm_input:
	  string_literal_list '(' comma_expression ')'
	| '[' identifier_or_typedef_name ']'
	  string_literal_list '(' comma_expression ')'
        { $$ = $2; /* XXXjmorse dummy */}
	;

gcc_asm_input_list:
	  gcc_asm_input
	| gcc_asm_input_list ',' gcc_asm_input

gcc_asm_clobbered_registers:
	  ':' gcc_asm_clobbered_registers_list
	| ':'
	;

gcc_asm_clobbered_register:
	  string_literal_list
	;

gcc_asm_clobbered_registers_list:
	  gcc_asm_clobbered_register
	| gcc_asm_clobbered_registers_list ',' gcc_asm_clobbered_register
	;

/*** External Definitions ***********************************************/


/* note: the following has been changed from the ANSI-C grammar:	*/
/*	- translation unit is allowed to be empty!			*/

translation_unit: { }
	/* nothing */
	| external_definition_list
	;

external_definition_list:
	external_definition
	| external_definition_list external_definition
	;

external_definition:
	function_definition
	| declaration
	{ }
	| ';' {} // empty declaration
	;

function_definition:
	function_head KnR_parameter_header_opt compound_statement
	{ 
          $1->decl_value() = *$3;
          PARSER.pop_scope();
          PARSER.move_declaration(*$1);
          PARSER.function="";
	}
	/* This is a GCC extension */
	| function_head KnR_parameter_header_opt gcc_asm_statement
	{ 
          // we ignore the value for now
          //$1->decl_value() = *$3;
          PARSER.pop_scope();
          PARSER.move_declaration(*$1);
          PARSER.function="";
	}
	;

KnR_parameter_header_opt:
          /* empty */
	{ $$ = NULL; }
	| KnR_parameter_header
	;

KnR_parameter_header:
	  KnR_parameter_declaration
	| KnR_parameter_header KnR_parameter_declaration
	;

KnR_parameter_declaration: declaring_list ';'
	;

function_head:
	identifier_declarator /* void */
	{
	  init(&$$);
	  irept type("int");
	  PARSER.new_declaration(type, *$1, *$$);
	  create_function_scope(*$$);
	}
	| declaration_specifier declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	  create_function_scope(*$$);
	}
	| type_specifier declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	  create_function_scope(*$$);
	}
	| declaration_qualifier_list identifier_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	  create_function_scope(*$$);
	}
	| type_qualifier_list identifier_declarator
	{
	  init(&$$);
	  PARSER.new_declaration(*$1, *$2, *$$);
	  create_function_scope(*$$);
	}
	;

declarator:
	identifier_declarator
	| typedef_declarator
	{ $$ = (exprt*)$1; /* XXX typing */ }
	;

typedef_declarator:
	paren_typedef_declarator
	| parameter_typedef_declarator
	;

parameter_typedef_declarator:
	typedef_name
	| typedef_name postfixing_abstract_declarator
	{
	  $$=$1;
	  make_subtype(*$$, *$2);
	}
	| clean_typedef_declarator
	;

clean_typedef_declarator:	/* Declarator */
	clean_postfix_typedef_declarator
	| '*' parameter_typedef_declarator
	{
	  $$=$2;
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	| '*' type_qualifier_list parameter_typedef_declarator
	{
	  merge_types(*$2, *$3);
	  $$=$2;
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	;

clean_postfix_typedef_declarator:	/* Declarator */
	'(' clean_typedef_declarator ')'
	{ $$ = $2; }
	| '(' clean_typedef_declarator ')' postfixing_abstract_declarator
	{
	  /* note: this is a pointer ($2) to a function ($4) */
	  /* or an array ($4)! */
	  $$=$2;
	  make_subtype(*$$, *$4);
	}
	;

paren_typedef_declarator:	/* Declarator */
	paren_postfix_typedef_declarator
	| '*' '(' simple_paren_typedef_declarator ')'
	{
	  $$=$3;
	  do_pointer((typet&)*$1, (typet&)*$3);
	}
	| '*' type_qualifier_list '(' simple_paren_typedef_declarator ')'
	{
	  // not sure where the type qualifiers belong
	  merge_types(*$2, *$4);
	  $$=$2;
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	| '*' paren_typedef_declarator
	{
	  $$=$2;
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	| '*' type_qualifier_list paren_typedef_declarator
	{
	  merge_types(*$2, *$3);
	  $$=$2;
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	;

paren_postfix_typedef_declarator:	/* Declarator */
	'(' paren_typedef_declarator ')'
	{ $$ = $2; }
	| '(' simple_paren_typedef_declarator postfixing_abstract_declarator ')'
	{	/* note: this is a function ($3) with a typedef name ($2) */
	  $$=$2;
	  make_subtype(*$$, *$3);
	}
	| '(' paren_typedef_declarator ')' postfixing_abstract_declarator
	{
	  /* note: this is a pointer ($2) to a function ($4) */
	  /* or an array ($4)! */
	  $$=$2;
	  make_subtype(*$$, *$4);
	}
	;

simple_paren_typedef_declarator:
	typedef_name
	{
	  assert(0);
	}
	| '(' simple_paren_typedef_declarator ')'
	{ $$ = $2; }
	;

identifier_declarator:
	unary_identifier_declarator
	| paren_identifier_declarator
	;

unary_identifier_declarator:
	postfix_identifier_declarator
	| '*' identifier_declarator
	{
	  $$ = $2;
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	| '*' type_qualifier_list identifier_declarator
	{
	  if ($3->id() == "declarator") {
	    typet d = (typet&)*$3;
	    *$3 = (exprt&)d.subtype();
	    merge_types(*$2, (typet&)*$3);
	    d.subtype() = *$2;
	    *$2 = d;
	  } else  {
	    merge_types(*$2, (typet&)*$3);
            // This declaration may be a set of merged types -- if that's the
            // case, we need to move the declaration data (i.e., the ident name)
            // up from the bottommost type to the top.
            // However it might also be a 'code' type, in which case we're
            // storing all the types in the 'subtype' field, so leave the decl
            // information where it is.
	    if ($2->id() == "merged_type")
              move_decl_info_upwards((typet&)*$2, ((typet&)*$2).subtypes().back());
	  }
	  $$ = (exprt*)$2;
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	;

postfix_identifier_declarator:
	paren_identifier_declarator postfixing_abstract_declarator
	{
		// postfix will be {code,array,incomplete-array}, which we
		// wish to preserve. So discard the existing "declarator" name
		// and move its contents into $2.
		$$ = (exprt*)$2;
		$$->decl_ident($1->decl_ident());

		if ($1->id() == "declarator") {
			$1->remove("decl_ident");
			make_subtype((typet&)*$$, (typet&)((typet*)$1)->subtype());
		} else {
			$1->remove("decl_ident");
			make_subtype((typet&)*$$, (typet&)*$1);
		}
	}
	| '(' unary_identifier_declarator ')'
	{
		$$ = $2;
	}
	| '(' unary_identifier_declarator ')' postfixing_abstract_declarator
	{
		// Given the bracketing, we preserve the existing irep id and
		// just make $4 a subtype.

		$$ = $2;
		make_subtype((typet&)*$$, (typet&)*$4);
	}

paren_identifier_declarator:
	identifier
	{
	  // All identifier_declarators are based from this.
	  init(&$$);
	  $$->id("declarator");
	  $$->decl_ident(*$1);
	  ((typet*)$$)->subtype().make_nil();
	}
	| '(' paren_identifier_declarator ')'
	{
	  $$ = $2;
	}
	;

abstract_declarator:
	unary_abstract_declarator
	| postfix_abstract_declarator
	| postfixing_abstract_declarator
	;

parameter_abstract_declarator:
	parameter_unary_abstract_declarator
	| parameter_postfix_abstract_declarator
	;

postfixing_abstract_declarator:	/* AbstrDeclarator */
	array_abstract_declarator
	| '(' ')'
	{
	  $$=(typet*)$1;
	  set(*$$, "code");
	  $$->arguments(irept());
	  $$->subtype().make_nil();
	}
	| '('
	  {
		unsigned prefix=++PARSER.current_scope().compound_counter;
		PARSER.new_scope(i2string(prefix)+"::");
	  }
	  parameter_type_list ')'
	{
	  $$=(typet*)$1;
	  set(*$$, "code");
	  $$->subtype().make_nil();
	  exprt args("arguments");
	  args.get_sub() = (std::vector<irept>&)(((typet*)$3)->subtypes());
	  $$->arguments(args);
	  PARSER.pop_scope();
	}
	;

parameter_postfixing_abstract_declarator:
	array_abstract_declarator
	| '(' ')'
	{
	  $$=(typet*)$1;
	  set(*$$, "code");
	  $$->arguments(irept());
	  $$->subtype().make_nil();
	}
	| '('
	  {
		unsigned prefix=++PARSER.current_scope().compound_counter;
		PARSER.new_scope(i2string(prefix)+"::");
	  }
	  parameter_type_list ')'
	{
	  $$=(typet*)$1;
	  set(*$$, "code");
	  $$->subtype().make_nil();
	  exprt args("arguments");
	  args.get_sub() = (std::vector<irept> &)(((typet*)$3)->subtypes());
	  $$->arguments(args);
	  PARSER.pop_scope();
	}
	;

array_abstract_declarator:
	'[' ']'
	{
	  $$=(typet*)$1;
	  set(*$$, "incomplete_array");
	  $$->subtype().make_nil();
	}
	| '[' constant_expression ']'
	{
	  $$=(typet*)$1;
	  set(*$$, "array");
	  $$->size(*$2);
	  $$->subtype().make_nil();
	}
	| array_abstract_declarator '[' constant_expression ']'
	{
	  // we need to push this down
	  $$=$1;
	  set(*$2, "array");
	  $2->size(*$3);
	  ((typet*)$2)->subtype().make_nil();
	  make_subtype((typet&)*$1, (typet&)*$2);
	}
	;

unary_abstract_declarator:
	'*'
	{
	  $$=(typet*)$1;
	  set(*$$, "pointer");
	  $$->subtype().make_nil();
	}
	| '*' type_qualifier_list
	{
	  $$=$2;
	  typet nil_declarator(static_cast<const typet &>(get_nil_irep()));
	  merge_types(*$2, nil_declarator);
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	| '*' abstract_declarator
	{
	  $$=$2;
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	| '*' type_qualifier_list abstract_declarator
	{
	  $$=$2;
	  merge_types(*$2, *$3);
	  do_pointer((typet&)*$1, (typet&)*$2);
	}
	;

parameter_unary_abstract_declarator:
	'*'
	{
          $$=(typet*)$1;
          set(*$$, "pointer");
          $$->subtype().make_nil();
	}
	| '*' type_qualifier_list
	{
          $$=$2;
          typet nil_declarator(static_cast<const typet &>(get_nil_irep()));
          merge_types(*$2, nil_declarator);
          do_pointer((typet&)*$1, (typet&)*$2);
	}
	| '*' parameter_abstract_declarator
	{
          $$=$2;
          do_pointer((typet&)*$1, (typet&)*$2);
	}
	| '*' type_qualifier_list parameter_abstract_declarator
	{
          $$=$2;
          merge_types(*$2, *$3);
          do_pointer((typet&)*$1, (typet&)*$2);
	}
	;

postfix_abstract_declarator:
	'(' unary_abstract_declarator ')'
	{ $$ = $2; }
	| '(' postfix_abstract_declarator ')'
	{ $$ = $2; }
	| '(' postfixing_abstract_declarator ')'
	{ $$ = $2; }
	| '(' unary_abstract_declarator ')' postfixing_abstract_declarator
	{
	  /* note: this is a pointer ($2) to a function ($4) */
	  /* or an array ($4) of pointers with name ($2)! */
	  $$=$2;
	  make_subtype(*$$, *$4);
	}
	;

parameter_postfix_abstract_declarator:
	'(' parameter_unary_abstract_declarator ')'
	{ $$ = $2; }
	| '(' parameter_postfix_abstract_declarator ')'
	{ $$ = $2; }
	| parameter_postfixing_abstract_declarator
	| '(' parameter_unary_abstract_declarator ')' parameter_postfixing_abstract_declarator
	{
	  /* note: this is a pointer ($2) to a function ($4) */
	  /* or an array ($4) of pointers with name ($2)! */
	  $$=$2;
	  make_subtype(*$$, *$4);
	}
	;

%%