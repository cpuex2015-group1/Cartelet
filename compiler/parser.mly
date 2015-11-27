%{
(* parserが利用する変数、関数、型などの定義 *)
open Syntax
let addtyp (x, _) = (x, Type.gentyp ())
%}

/* (* 字句を表すデータ型の定義 (caml2html: parser_token) *) */
%token <bool * Lexing.position> BOOL
%token <int * Lexing.position> INT
%token <float * Lexing.position> FLOAT
%token <Lexing.position> NOT
%token <Lexing.position> MINUS
%token <Lexing.position> PLUS
%token <Lexing.position> AST
%token <Lexing.position> SLASH
%token <Lexing.position> MINUS_DOT
%token <Lexing.position> PLUS_DOT
%token <Lexing.position> AST_DOT
%token <Lexing.position> SLASH_DOT
%token <Lexing.position> EQUAL
%token <Lexing.position> LESS_GREATER
%token <Lexing.position> LESS_EQUAL
%token <Lexing.position> GREATER_EQUAL
%token <Lexing.position> LESS
%token <Lexing.position> GREATER
%token <Lexing.position> IF
%token <Lexing.position> THEN
%token <Lexing.position> ELSE
%token <Id.t * Lexing.position> IDENT
%token <Lexing.position> LET
%token <Lexing.position> IN
%token <Lexing.position> REC
%token <Lexing.position> COMMA
%token <Lexing.position> ARRAY_CREATE
%token <Lexing.position> DOT
%token <Lexing.position> LESS_MINUS
%token <Lexing.position> SEMICOLON
%token <Lexing.position> LPAREN
%token <Lexing.position> RPAREN
%token <Lexing.position> EOF

/* (* 優先順位とassociativityの定義（低い方から高い方へ） (caml2html: parser_prior) *) */
%right prec_let
%right SEMICOLON
%right prec_if
%right LESS_MINUS
%left COMMA
%left EQUAL LESS_GREATER LESS GREATER LESS_EQUAL GREATER_EQUAL
%left PLUS MINUS PLUS_DOT MINUS_DOT
%left AST SLASH AST_DOT SLASH_DOT
%right prec_unary_minus
%left prec_app
%left DOT

/* (* 開始記号の定義 *) */
%type <Syntax.t> exp
%start exp

%%

simple_exp: /* (* 括弧をつけなくても関数の引数になれる式 (caml2html: parser_simple) *) */
| LPAREN exp RPAREN
    { $2 }
| LPAREN RPAREN
    { Unit($1) }
| BOOL
    { match $1 with
      | (b, p) -> Bool(b, p) }
| INT
    { match $1 with
      | (i, p) -> Int(i, p) }
| FLOAT
    { match $1 with
      | (f, p) -> Float(f, p) }
| IDENT
    { match $1 with
      | (id, p) -> Var(id, p) }
| simple_exp DOT LPAREN exp RPAREN
    { Get($1, $4, $2) }

exp: /* (* 一般の式 (caml2html: parser_exp) *) */
| simple_exp
    { $1 }
| NOT exp
    %prec prec_app
    { Not($2, $1) }
| MINUS exp
    %prec prec_unary_minus
    { (match $2 with
       | Float(f, _) -> Float(-.f, $1) (* -1.23などは型エラーではないので別扱い *)
       | e -> Neg(e, $1)) }
| exp PLUS exp /* (* 足し算を構文解析するルール (caml2html: parser_add) *) */
    { Add($1, $3, $2) }
| exp MINUS exp
    { Sub($1, $3, $2) }
| exp AST exp
    { Mul($1, $3, $2) }
| exp SLASH exp
    { Div($1, $3, $2) }
| exp EQUAL exp
    { Eq($1, $3, $2) }
| exp LESS_GREATER exp
    { Not(Eq($1, $3, $2), $2) }
| exp LESS exp
    { Not(LE($3, $1, $2), $2) }
| exp GREATER exp
    { Not(LE($1, $3, $2), $2) }
| exp LESS_EQUAL exp
    { LE($1, $3, $2) }
| exp GREATER_EQUAL exp
    { LE($3, $1, $2) }
| IF exp THEN exp ELSE exp
    %prec prec_if
    { If($2, $4, $6, $1) }
| MINUS_DOT exp
    %prec prec_unary_minus
    { FNeg($2, $1) }
| exp PLUS_DOT exp
    { FAdd($1, $3, $2) }
| exp MINUS_DOT exp
    { FSub($1, $3, $2) }
| exp AST_DOT exp
    { FMul($1, $3, $2) }
| exp SLASH_DOT exp
    { FDiv($1, $3, $2) }
| LET IDENT EQUAL exp IN exp
    %prec prec_let
    { Let(addtyp $2, $4, $6, $1) }
| LET REC fundef IN exp
    %prec prec_let
    { LetRec($3, $5, $1) }
| exp actual_args
    %prec prec_app
    { App($1, $2, Syntax.pos_of_exp $1) }
| elems
    { Tuple($1, Syntax.pos_of_exp (List.hd $1)) }
| LET LPAREN pat RPAREN EQUAL exp IN exp
    { LetTuple($3, $6, $8, $1) }
| simple_exp DOT LPAREN exp RPAREN LESS_MINUS exp
    { Put($1, $4, $7, $2) }
| exp SEMICOLON exp
    { Let((Id.gentmp Type.Unit, Type.Unit), $1, $3, $2) }
| exp SEMICOLON
    { $1 }
| ARRAY_CREATE simple_exp simple_exp
    %prec prec_app
    { Array($2, $3, $1) }
| error
    { let p = (Parsing.symbol_start_pos ()) in
      (Printf.fprintf stderr "Error: parse error near line %d characters %d-%d\n"
		      p.Lexing.pos_lnum
		      ((Parsing.symbol_start ()) - p.Lexing.pos_bol)
		      ((Parsing.symbol_end ()) - p.Lexing.pos_bol);
       failwith "Parse error") }

fundef:
| IDENT formal_args EQUAL exp
    { { name = addtyp $1; args = $2; body = $4 } }

formal_args:
| IDENT formal_args
    { addtyp $1 :: $2 }
| IDENT
    { [addtyp $1] }

actual_args:
| actual_args simple_exp
    %prec prec_app
    { $1 @ [$2] }
| simple_exp
    %prec prec_app
    { [$1] }

elems:
| elems COMMA exp
    { $1 @ [$3] }
| exp COMMA exp
    { [$1; $3] }

pat:
| pat COMMA IDENT
    { $1 @ [addtyp $3] }
| IDENT COMMA IDENT
    { [addtyp $1; addtyp $3] }
