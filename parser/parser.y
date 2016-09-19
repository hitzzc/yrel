// Copyright 2011 Bobby Powers. All rights reserved.
// Use of this source code is governed by the MIT
// license that can be found in the LICENSE file.

// based off of Appendix A from http://dinosaur.compilertools.net/yacc/

%{

package parser

import (
	"fmt"
	"github.com/MrHuxu/yrel/lexer"
	"unicode"
)

var regs = make(map[string]*lexer.NumToken)

%}

// fields inside this union end up as the fields in a structure known
// as ${PREFIX}SymType, of which a reference is passed to the lexer.
%union{
	Identifier *lexer.IdToken
	Number *lexer.NumToken
}

// any non-terminal which returns a value needs a type, which is
// really a field name in the above union struct
%type <Number> expr number

// same for terminals
%token <Number> DIGIT
%token <Identifier> LETTER

%left '|'
%left '&'
%left '+'  '-'
%left '*'  '/'  '%'
%left UMINUS      /*  supplies  precedence  for  unary  minus  */

%%

list	: /* empty */
	| list stat '\n'
	;

stat	:    expr
		{
			fmt.Println($1.GetText());
		}
	|    LETTER '=' expr
		{
			regs[$1.GetText()]  =  $3
		}
	;

expr	:    '(' expr ')'
		{ $$  =  $2 }
	|    expr '+' expr
		{ $$  =  $1.Plus($3) }
	|    expr '-' expr
		{ $$  =  $1.Sub($3) }
	|    expr '*' expr
		{ $$  =  $1.Mul($3) }
	|    expr '/' expr
		{ $$  =  $1.Div($3) }
	|    expr '%' expr
		{ $$  =  $1.Mod($3) }
	|    expr '&' expr
		{ $$  =  $1.BiteAnd($3) }
	|    expr '|' expr
		{ $$  =  $1.BiteOr($3) }
	|    '-'  expr        %prec  UMINUS
		{ $$  = $2.Neg()  }
	|    LETTER
		{ $$  = regs[$1.GetText()] }
	|    number
	;

number	:    DIGIT
		{
			$$ = $1;
		}
	;

%%      /*  start  of  programs  */

type CalcLex struct {
	S string
	Pos int
}


func (l *CalcLex) Lex(lval *yySymType) int {
	var c rune = ' '
	for c == ' ' {
		if l.Pos == len(l.S) {
			return 0
		}
		c = rune(l.S[l.Pos])
		l.Pos += 1
	}

	if unicode.IsDigit(c) {
		lval.Number = &lexer.NumToken{
			Line: &lexer.Line{l.Pos},
			Value: int(c) - '0',
		}
		return DIGIT
	} else if unicode.IsLower(c) {
		lval.Identifier = &lexer.IdToken{
			Line: &lexer.Line{l.Pos},
			Text: string(c),
		}
		return LETTER
	}
	return int(c)
}

func (l *CalcLex) Error(s string) {
	fmt.Printf("syntax error: %s\n", s)
}