%option noyywrap
%{

#include <stdio.h>

#define YY_DECL int yylex()

#include "parser.tab.h"

// don't count from 0
int num_lines = 1;
int num_chars = 1;

//tmp

// {DIGIT}+                {yylval.intval = atoi(yytext); num_chars = num_chars + strlen(yytext); return INTEGER;}
// "number "               {/*printf("INTEGER\n")*/; num_chars+=7; BEGIN(number);}
// <number>" "             {/*do nothing but keep count*/ num_chars++;}
// <number>{DIGIT}+        {/*printf("NUMBER %s\n", yytext);*/ num_chars = num_chars + strlen(yytext); BEGIN(INITIAL);} // maybe comment out this line
// <number>{ALPHA}+"["     {printf("ARRAY "); num_chars = num_chars + strlen(yytext); BEGIN(array);}
// <number>{ALPHA}+        {/*printf("IDENT %s\n", yytext);*/ num_chars = num_chars + strlen(yytext); yylval.strval = strdup(yytext); BEGIN(INITIAL); return IDENT;}
// <number>\n              {num_lines++; num_chars = 1; BEGIN(INITIAL);}
// <number>.               {printf("Error at line %d, column %d: unrecognized symbol in identifier '%s'\n", num_lines, num_chars, yytext); exit(-1);}
// <array>{DIGIT}+"]"      {printf("%.*s\n", (int)strlen(yytext)-1, yytext); num_chars = num_chars + strlen(yytext); BEGIN(INITIAL);}
// <array>{ALPHA}+"]"      {printf("IDENT %.*s\n", (int)strlen(yytext)-1, yytext); num_chars = num_chars + strlen(yytext); BEGIN(INITIAL);}
// <array>\n               {num_lines++; num_chars = 1; BEGIN(INITIAL);}
// <array>.                {printf("Error at line %d, column %d: invalid size '%s' for an array\n", num_lines, num_chars, yytext); exit(-1);}
// <function>{ALPHA}+      {num_chars = num_chars + strlen(yytext); yylval.strval = strdup(yytext); BEGIN(INITIAL); return FUNCTION;}
// <function>.             {printf("Error at line %d, column %d: unrecognized symbol in function name '%s'\n", num_lines, num_chars, yytext); exit(-1);}

//endtmp

%}
%option yylineno

DIGIT [0-9]
ALPHA [_a-zA-Z]
ALPHANUM [_a-zA-Z0-9]

%x number
%x ident
%x array
%x function
%x function_vars

%%
" "+                    {/*do nothing but keep count*/ num_chars++;}
"array "                {num_chars+=6; return ARRAY;}
"return"                {num_chars+=6; return RETURN;}
"if"                    {num_chars+=2; return IF;}
"else"                  {num_chars+=4; return ELSE;}
"elif"                  {num_chars+=4; return ELIF;}
"do"                    {num_chars+=2; return DO;}
"while"                 {num_chars+=5; return WHILE;}
"read"                  {num_chars+=4; return READ;}
"print"                 {num_chars+=5; return PRINT; }
"break"                 {num_chars+=5; return BREAK;}
"write"                 {num_chars+=5; return WRITE;}
"continue"              {num_chars+=8; return CONTINUE;}
"fun "                  {num_chars+=4; return FUNCTION;}
\n                      {num_chars = 1; num_lines++;/*lazy return DELIM;*/}
"++"                    {num_chars+=2; return INC;}
"--"                    {num_chars+=2; return DEC;}
"+"                     {num_chars++; return ADD;}
"-"                     {num_chars++; return SUBTRACT;}
"*"                     {num_chars++; return MULTIPLY;}
"/"                     {num_chars++; return DIVIDE;}
"%"                     {num_chars++; return MOD;}
"("                     {num_chars++; return O_PAREN;}
")"                     {num_chars++; return C_PAREN;}
"{"                     {num_chars++; return O_CBRK;}
"}"                     {num_chars++; return C_CBRK;}
"["                     {num_chars++; return O_BRK;}
"]"                     {num_chars++; return C_BRK;}
">="                    {num_chars+=2; return G_EQ;}
"<="                    {num_chars+=2; return L_EQ;}
"!="                    {num_chars+=2; return N_EQ;}
"=="                    {num_chars+=2; return EQ;}
"<"                     {num_chars++; return LESS;}
">"                     {num_chars++; return MORE;}
"="                     {num_chars++; return ASSIGN;}
"$"                     {num_chars++; return DELIM;}
[ \t\n]+                {num_chars = 1; num_lines++;}
","                     {num_chars++; return COMMA;}
"number "               {num_chars+=7; return INTEGER;}
{DIGIT}+                {num_chars = num_chars + strlen(yytext); yylval.intval = atoi(yytext); return VALUE;}
[[:space:]]+            {/*do nothing but keep count*/ num_chars++;}
";;".*                  {num_chars+=2; return COMMENT;}
{ALPHA}+                {/*printf("IDENT %s\n", yytext)*/; num_chars = num_chars + strlen(yytext); yylval.strval = strdup(yytext); return IDENT;}
.                       {printf("Error at line %d, column %d: unrecognized symbol '%s'\n", num_lines, num_chars, yytext); /*exit(-1); // want to print all errors*/}
%%


