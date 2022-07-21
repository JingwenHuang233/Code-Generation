/* cs152-miniL phase3*/

%{
#define YY_NO_UNPUT
#include <stdio.h>
#include <stdlib.h>
#include <set>
#include <map>
#include <string.h>

int tempCount = 0;
int labelCount = 0;

void yyerror(const char *msg);
int yylex();

std::string new_temp();
std::string new_label();

extern char* yytext;
extern int currLine;
extern int currPos;

std::map<std::string, std::string> varTemp;
std::map<std::string, int> arrSize;
bool mainFunc = false;
std::set<std::string> reserved {"FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY", "END_BODY", "INTEGER", "ARRAY", "ENUM",
  "OF", "IF", "THEN", "ENDIF", "ELSE", "WHILE", "DO", "BEGINLOOP", "ENDLOOP", "CONTINUE", "READ", "WRITE", "AND", "OR", "NOT", "TRUE", "FALSE", "RETURN", "SUB",
  "ADD", "MULT", "DIV", "MOD", "EQ", "NEQ", "LT", "GT", "LTE", "GTE", "SEMICOLON", "COLON", "COMMA", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "ASSIGN",
  "prog_start", "functions", "function", "ident", "declarations", "statements", "declaration", "statement", "identifiers", "func_ident",
  "vars", "bool_exp", "relation_and_exp", "relation_exp_inv", "relation_exp", "comp", "expression", "multiplicative_expression",
  "term", "expressions", "var"};
std::set<std::string> funcs;
extern FILE * yyin;
%}

%union{
  /* put your types here */
  int num_val;
  char* id_val;
  struct S {
    char* code;
  } statement;
  struct E {
    char* place;
    char* code;
    bool arr;
  } expression;
}

%error-verbose
%start prog_start

%type <expression> function functions declarations declaration vars var expressions expression func_ident identifiers ident
%type <expression> bool_exp relation_and_exp relation_exp comp multiplicative_expression term relation_exp_inv
%type <statement> statements statement

%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF 
ELSE FOR WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN SUB ADD MULT DIV MOD EQ NEQ LT GT LTE GTE
SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN END
%token <id_val> IDENT
%token <num_val> NUMBER
%right ASSIGN
%left OR
%left AND
%right NOT
%left EQ NEQ LT GT LTE GTE
%left SUB ADD
%left MULT DIV MOD
%right UMINUS
%left L_SQUARE_BRACKET R_SQUARE_BRACKET
%left L_PAREN R_PAREN

/* %start program */

%% 

/* write your rules here */
prog_start:   functions 
              {
                printf("\n");
              };

functions:    %empty
              {
                if (!mainFunc) {
                  printf("No main function declared!");
                }
              }

              | function functions
              {
                std::string temp;
                temp.append($1.code);
                temp.append($2.code);
                $$.code = strdup(temp.c_str());
              };

function:     FUNCTION func_ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
              {
                std::string temp = "func ";
                temp.append($2.place);
                temp.append("\n");
                std::string s = $2.place;
                if (s == "main") {
                  mainFunc = true;
                }
                temp.append($5.code);
                std::string decs = $5.code;
                int decNum = 0;
                
                while (decs.find(".") != std::string::npos) {
                  int pos = decs.find(".");
                  decs.replace(pos, 1, "=");
                  std::string part = ", $" + std::to_string(decNum) + "\n";
                  decNum++;
                  decs.replace(decs.find("\n", pos), 1, part);
                }
                temp.append(decs);

                temp.append($8.code);

                std::string statements = $11.code;
                if (statements.find("continue") != std::string::npos) {
                  printf("Error: Continue outside loop in function %s\n ", $2.place);
                }
                temp.append(statements);
                temp.append("endfunc\n\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup(s.c_str());
              };

func_ident:   ident
              {
                if (funcs.find($1.place) != funcs.end()){
                  printf("function name %s already declared.\n", $1.place);
                }
                else{
                  funcs.insert($1.place);
                }
                $$.code = strdup("");
                $$.place = strdup($1.place);
              };

ident:        IDENT                           
              {
                $$.place = strdup($1);
                $$.code = strdup("");
              };

declarations: %empty                       
              {
                $$.code = strdup("");
                $$.place = strdup("");
              }
              | declaration SEMICOLON declarations  
              {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              };

statements:   statement SEMICOLON                       
              {
                $$.code = strdup($1.code);
              }
              |statement SEMICOLON statements 
              {
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
              };

declaration:  identifiers COLON INTEGER       
              {
                std::string temp;
                std::string ids($1.place);
                if (ids.find("|", 0) == std::string::npos){ //only 1 id
                  std::string id = $1.place;
                  if(reserved.find(id) != reserved.end()){
                    printf("Error: Identifier %s is a reserved word.\n", id.c_str());
                  }
                  else if(funcs.find(id) != funcs.end() || varTemp.find(id) != varTemp.end()){
                    printf("Error: Identifier %s is previously declared.\n", id.c_str());
                  }
                  else{
                    varTemp[id] = id;
                    arrSize[id] = 1;
                  }
                  temp.append(". ");
                  temp.append(id);
                  temp.append("\n");
                }
                else{ //if multiple id's
                  size_t left = 0;
                  size_t right = 0;
                  bool end = false;
                  while (!end){
                    right = ids.find("|", left);
                    if (right != std::string::npos){
                      std::string id = ids.substr(left, right-left);
                      if(reserved.find(id) != reserved.end()){
                        printf("Error: Identifier %s is a reserved word.\n", id.c_str());
                      }   
                      else if(funcs.find(id) != funcs.end() || varTemp.find(id) != varTemp.end()){
                        printf("Error: Identifier %s is previously declared.\n", id.c_str());
                      }
                      else{
                        varTemp[id] = id;
                        arrSize[id] = 1;
                      }
                      temp.append(". ");
                      temp.append(id);
                      temp.append("\n");
                      left = right + 1;
                    }
                    else{ //last id
                      std::string id = ids.substr(left, right);
                      if(reserved.find(id) != reserved.end()){
                        printf("Error: Identifier %s is a reserved word.\n", id.c_str());
                      }
                      else if(funcs.find(id) != funcs.end() || varTemp.find(id) != varTemp.end()){
                        printf("Error: Identifier %s is previously declared.\n", id.c_str());
                      }
                      else{
                        varTemp[id] = id;
                        arrSize[id] = 1;
                      }
                      temp.append(". ");
                      temp.append(id);
                      temp.append("\n");
                      end = true;
                    }
                  }
                }
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER   
              {
                std::string temp;
                std::string ids($1.place);
                if (ids.find("|", 0) == std::string::npos){ //only 1 id
                  std::string id = $1.place;
                  if(reserved.find(id) != reserved.end()){
                    printf("Error: Identifier %s is a reserved word.\n", id.c_str());
                  }
                  else if(funcs.find(id) != funcs.end() || varTemp.find(id) != varTemp.end()){
                    printf("Error: Identifier %s is previously declared.\n", id.c_str());
                  }
                  else if($5 <= 0){
                    printf("Error: the size of array %s can't be <= 0.\n", id.c_str());
                  }
                  else{
                    varTemp[id] = id;
                    arrSize[id] = $5;
                  }
                  temp.append(".[] ");
                  temp.append(id);
                  temp.append(", ");
                  temp.append(std::to_string($5));
                  temp.append("\n");
                }
                else{ //if multiple id's
                  size_t left = 0;
                  size_t right = 0;
                  bool end = false;
                  while (!end){
                    right = ids.find("|", left);
                    if (right != std::string::npos){
                      std::string id = ids.substr(left, right-left);
                      if(reserved.find(id) != reserved.end()){
                        printf("Error: Identifier %s is a reserved word.\n", id.c_str());
                      }   
                      else if(funcs.find(id) != funcs.end() || varTemp.find(id) != varTemp.end()){
                        printf("Error: Identifier %s is previously declared.\n", id.c_str());
                      }
                      else if($5 <= 0){
                        printf("Error: the size of array %s can't be <= 0.\n", id.c_str());
                      }
                      else{
                        varTemp[id] = id;
                        arrSize[id] = $5;
                      }
                      temp.append(".[] ");
                      temp.append(id);
                      temp.append(", ");
                      temp.append(std::to_string($5));
                      temp.append("\n");
                      left = right + 1;
                    }
                    else{ //last id
                      std::string id = ids.substr(left, right);
                      if(reserved.find(id) != reserved.end()){
                        printf("Error: Identifier %s is a reserved word.\n", id.c_str());
                      }
                      else if(funcs.find(id) != funcs.end() || varTemp.find(id) != varTemp.end()){
                        printf("Error: Identifier %s is previously declared.\n", id.c_str());
                      }
                      else if($5 <= 0){
                        printf("Error: the size of array %s can't be <= 0.\n", id.c_str());
                      }
                      else{
                        varTemp[id] = id;
                        arrSize[id] = $5;
                      }
                      temp.append(".[] ");
                      temp.append(id);
                      temp.append(", ");
                      temp.append(std::to_string($5));
                      temp.append("\n");
                      end = true;
                    }
                  }
                }
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              };              

identifiers:  ident                           
              {
                $$.code = strdup("");
                $$.place = strdup($1.place);
              }
              | ident COMMA identifiers       
              {
                std::string temp;
                temp.append($1.place);
                temp.append("|");
                temp.append($3.place);
                $$.code = strdup("");
                $$.place = strdup(temp.c_str());
              };

statement:    var ASSIGN expression           
              {
                std::string id = $1.place;
                if ($1.arr){
                  if (varTemp.find(id.substr(0, id.find(","))) == varTemp.end()){
                    printf("Error: Variable %s is not declared.\n", $1.place);
                  }
                }
                else{
                  if (varTemp.find(id) == varTemp.end()){
                    printf("Error: Variable %s is not declared.\n", $1.place);
                  }
                }

                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                if ($1.arr){
                  std::string dst = id.substr(0, id.find(","));
                  std::string index = id.substr(id.find(",")+1);
                  std::string src = $3.place;
                  temp += "[]= " + dst + ", " + index + ", " + src + "\n";
                }
                else if ($3.arr){
                  std::string parse = $3.place;
                  std::string dst = id;
                  std::string src = parse.substr(0, parse.find(","));
                  std::string index = parse.substr(parse.find(",")+1);
                  temp += "=[] " + dst + ", " + src + ", " + index + "\n";
                }
                else{
                  temp += "= ";
                  temp.append($1.place);
                  temp.append(", ");
                  temp.append($3.place);
                  temp.append("\n");
                }
                $$.code = strdup(temp.c_str());
              }
              | IF bool_exp THEN statements ENDIF   
              {
                std::string if_statement = new_label();
                std::string then_statement = new_label();
                std::string temp;
                temp.append($2.code);
                temp.append("?:= ");
                temp.append(if_statement);
                temp.append(", ");
                temp.append($2.place);
                temp.append("\n");
                temp.append(":= ");
                temp.append(then_statement);
                temp.append("\n");
                temp.append(": ");
                temp.append(if_statement);
                temp.append("\n");
                temp.append($4.code);
                temp.append(": ");
                temp.append(then_statement);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
              }
              | IF bool_exp THEN statements ELSE statements ENDIF   
              {
                std::string if_statement = new_label();
                std::string label2 = new_label();
                std::string temp;
                temp.append($2.code);
                temp.append("?:= ");
                temp.append(if_statement);
                temp.append(", ");
                temp.append($2.place);
                temp.append("\n");
                temp.append($6.code);
                temp.append(":= ");
                temp.append(label2);
                temp.append("\n");
                temp.append(": ");
                temp.append(if_statement);
                temp.append("\n");
                temp.append($4.code);
                temp.append(": ");
                temp.append(label2);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
              }
              | WHILE bool_exp BEGINLOOP statements ENDLOOP   
              {
                std::string while_label = new_label();
                std::string true_label = new_label();
                std::string label_declared = new_label();
                std::string codebody = $4.code;
                std::string temp;
                temp += ": " + while_label + "\n";
                temp.append($2.code);
                temp += "?:= " + true_label + ", ";
                temp.append($2.place);
                temp.append("\n");
                temp += ":= " + label_declared + "\n";
                temp += ": " + true_label + "\n";
                while(codebody.find("continue") != std::string::npos){
                  codebody.replace(codebody.find("continue"), 8, ":= " + while_label);
                }
                temp.append(codebody);
                temp += ":= " + while_label + "\n";
                temp += ": " + label_declared + "\n";
                $$.code = strdup(temp.c_str());
              }
              | DO BEGINLOOP statements ENDLOOP WHILE bool_exp    
              {
                std::string temp;
                std::string loop_begin = new_label();
                std::string dowhile_begin = new_label();
                std::string codebody = $3.code;
                while(codebody.find("continue") != std::string::npos){
                  codebody.replace(codebody.find("continue"), 8, ":= " + dowhile_begin);
                }

                temp += ": " + loop_begin + "\n";
                temp.append($3.code);
                temp += ": " + dowhile_begin + "\n";
                temp.append($6.code);
                temp += "?:= " + loop_begin + ", ";
                temp.append($6.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
              }
              | READ vars                     
              {
                std::string temp;
                temp.append($2.code);
                size_t pos = temp.find("|", 0);
                while (pos != std::string::npos){
                  temp.replace(pos, 1, "<");
                  pos = temp.find("|", pos);
                }
                $$.code = strdup(temp.c_str());
              }
              | WRITE vars                    
              {
                std::string temp;
                temp.append($2.code);
                size_t pos = temp.find("|", 0);
                while (pos != std::string::npos){
                  temp.replace(pos, 1, ">");
                  pos = temp.find("|", pos);
                }
                $$.code = strdup(temp.c_str());
              }
              | CONTINUE                      
              {
                $$.code = strdup("continue\n");
              }
              | RETURN expression             
              {
                std::string temp;
                temp.append($2.code);
                temp.append("ret");
                temp.append($2.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
              };

vars:         var                             
              {
                std::string temp;
                temp.append($1.code);
                if ($1.arr){
                  temp.append(".[]| ");
                }
                else{
                  temp.append(".| ");
                }
                temp.append($1.place);
                temp.append("\n");
                
                $$.place = strdup("");
                $$.code = strdup(temp.c_str());
              }
              |var COMMA vars                 
              {
                std::string temp;
                temp.append($1.code);
                if ($1.arr){
                  temp.append(".[]| ");
                }
                else{
                  temp.append(".| ");
                }
                temp.append($1.place);
                temp.append("\n");
                temp.append($3.code);
                $$.place = strdup("");
                $$.code = strdup(temp.c_str());
              };

bool_exp:     relation_and_exp                
              {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
              }
              |relation_and_exp OR bool_exp   
              {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);
                temp += ". " + dst + "\n";
                temp += "|| " + dst + ", ";
                temp.append($1.place);
                temp.append(", ");
                temp.append($3.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              };

relation_and_exp: relation_exp_inv                
                  {
                    $$.code = strdup($1.code);
                    $$.place = strdup($1.place);
                  }
                  | relation_exp_inv AND relation_and_exp   
                  {
                    std::string dst = new_temp();
                    std::string temp;
                    temp.append($1.code);
                    temp.append($3.code);
                    temp += ". " + dst + "\n";
                    temp += "&& " + dst + ", ";
                    temp.append($1.place);
                    temp.append(", ");
                    temp.append($3.place);
                    temp.append("\n");
                    $$.code = strdup(temp.c_str());
                    $$.place = strdup(dst.c_str());
                  };

relation_exp_inv: NOT relation_exp_inv
                  {
                    std::string dst = new_temp();
                    std::string temp;
                    temp.append($2.code);
                    temp += ". " + dst + "\n";
                    temp += "! " + dst + ", ";
                    temp.append($2.place);
                    temp.append("\n");
                    $$.code = strdup(temp.c_str());
                    $$.place = strdup(dst.c_str());
                  }
                  | relation_exp
                  {
                    $$.code = strdup($1.code);
                    $$.place = strdup($1.place);
                  };

relation_exp: expression comp expression    
              {
                std::string dst = new_temp();
                std::string temp;
                temp.append($1.code);
                temp.append($3.code);
                temp = temp + ". " + dst + "\n" + $2.place + dst + ", " + $1.place + ", " + $3.place + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              }
              | TRUE                          
              {
                std::string temp;
                temp.append("1");
                $$.code = strdup("");
                $$.place = strdup(temp.c_str());
              }
              | FALSE                         
              {
                std::string temp;
                temp.append("0");
                $$.code = strdup("");
                $$.place = strdup(temp.c_str());
              }
              | L_PAREN bool_exp R_PAREN      
              {
                $$.code = strdup($2.code);
                $$.place = strdup($2.place);
              };

comp:         EQ                              
              {
                $$.code = strdup("");
                $$.place = strdup("== ");
              }
              | NEQ                           
              {
                $$.code = strdup("");
                $$.place = strdup("!= ");
              }
              | LT                            
              {
                $$.code = strdup("");
                $$.place = strdup("< ");
              }
              | GT                            
              {
                $$.code = strdup("");
                $$.place = strdup("> ");
              }
              | LTE                           
              {
                $$.code = strdup("");
                $$.place = strdup("<= ");
              }
              | GTE                           
              {
                $$.code = strdup("");
                $$.place = strdup(">= ");
              };

expression:   multiplicative_expression       
              {
                $$.code = strdup($1.code);
                $$.place = strdup($1.place);
              }
              | multiplicative_expression ADD expression  
              {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);
                temp += ". " + dst + "\n";
                temp += "+ " + dst + ", ";
                temp.append($1.place);
                temp += ", ";
                temp.append($3.place);
                temp += "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              }
              | multiplicative_expression SUB expression  
              {
                std::string temp;
                std::string dst = new_temp();
                temp.append($1.code);
                temp.append($3.code);
                temp += ". " + dst + "\n";
                temp += "- " + dst + ", ";
                temp.append($1.place);
                temp += ", ";
                temp.append($3.place);
                temp += "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              };

multiplicative_expression:  term              
                            {
                              $$.code = strdup($1.code);
                              $$.place = strdup($1.place);
                            }
                            | term MULT multiplicative_expression 
                            {
                              std::string temp;
                              std::string dst = new_temp();
                              temp.append($1.code);
                              temp.append($3.code);
                              temp.append(". ");
                              temp.append(dst);
                              temp.append("\n");
                              temp += "* " + dst + ", ";
                              temp.append($1.place);
                              temp += ", ";
                              temp.append($3.place);
                              temp += "\n";
                              $$.code = strdup(temp.c_str());
                              $$.place = strdup(dst.c_str());
                            }
                            | term DIV multiplicative_expression  
                            {
                              std::string temp;
                              std::string dst = new_temp();
                              temp.append($1.code);
                              temp.append($3.code);
                              temp.append(". ");
                              temp.append(dst);
                              temp.append("\n");
                              temp += "/ " + dst + ", ";
                              temp.append($1.place);
                              temp += ", ";
                              temp.append($3.place);
                              temp += "\n";
                              $$.code = strdup(temp.c_str());
                              $$.place = strdup(dst.c_str());
                            }
                            | term MOD multiplicative_expression  
                            {
                              std::string temp;
                              std::string dst = new_temp();
                              temp.append($1.code);
                              temp.append($3.code);
                              temp.append(". ");
                              temp.append(dst);
                              temp.append("\n");
                              temp += "% " + dst + ", ";
                              temp.append($1.place);
                              temp += ", ";
                              temp.append($3.place);
                              temp += "\n";
                              $$.code = strdup(temp.c_str());
                              $$.place = strdup(dst.c_str());
                            };

term:         SUB var         
              {
                std::string dst = new_temp();
                std::string temp;
                if ($2.arr){
                  temp.append($2.code);
                  temp.append(". ");
                  temp.append(dst);
                  temp.append("\n");
                  temp += "=[] " + dst + ", ";
                  temp.append($2.place);
                  temp.append("\n");
                }
                else{
                  temp.append(". ");
                  temp.append(dst);
                  temp.append("\n");
                  temp += "= " + dst + ", ";
                  temp.append($2.place);
                  temp.append("\n");
                  temp.append($2.code);
                }
                if(varTemp.find($2.place) != varTemp.end()){
                  varTemp[$2.place] = dst;
                }
                temp += "* " + dst + ", " + dst + ", -1\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              }
              | SUB NUMBER 
              {
                std::string dst = new_temp();
                std::string temp;
                temp.append(". ");
                temp.append(dst);
                temp.append("\n");
                temp = temp + "= " + dst + ", -" + std::to_string($2) + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              }
              | SUB L_PAREN expression R_PAREN 
              {
                std::string temp;
                temp.append($3.code);
                temp.append("* ");
                temp.append($3.place);
                temp.append(", ");
                temp.append($3.place);
                temp.append(", -1\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup($3.place);
              }
              | var                           
              {
                std::string dst = new_temp(); 
                std::string temp;
                if ($1.arr){
                  temp.append($1.code);
                  temp.append(". ");
                  temp.append(dst);
                  temp.append("\n");
                  temp += "=[] " + dst + ", ";
                  temp.append($1.place);
                  temp.append("\n");
                }
                else{
                  temp.append(". ");
                  temp.append(dst);
                  temp.append("\n");
                  temp += "= " + dst + ", ";
                  temp.append($1.place);
                  temp.append("\n");
                  temp.append($1.code);
                }
                if(varTemp.find($1.place)!=varTemp.end()){
                  varTemp[$1.place] = dst;
                }
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              }
              | NUMBER                        
              {
                std::string dst = new_temp(); 
                std::string temp;
                temp.append(". ");
                temp.append(dst);
                temp.append("\n");
                temp += "= " + dst + ", " + std::to_string($1) + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              }
              | L_PAREN expression R_PAREN    
              {
                $$.code = strdup($2.code);
                $$.place = strdup($2.place);
              }  
              | ident L_PAREN expressions R_PAREN   
              {
                std::string temp;
                std::string func= $1.place;
                if(funcs.find(func) == funcs.end()){
                  printf("Calling undeclared function %s.\n", func.c_str());
                }
                std::string dst = new_temp();
                temp.append($3.code);
                temp += ". " + dst + "\ncall ";
                temp.append($1.place);
                temp += ", " + dst + "\n";
                $$.code = strdup(temp.c_str());
                $$.place = strdup(dst.c_str());
              };

expressions:  expression                      
              {
                std::string temp;
                temp.append($1.code);
                temp.append("param ");
                temp.append($1.place);
                temp.append("\n");
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              }
              |expression COMMA expressions   
              {
                std::string temp;
                temp.append($1.code);
                temp.append("param ");
                temp.append($1.place);
                temp.append("\n");
                temp.append($3.code);
                $$.code = strdup(temp.c_str());
                $$.place = strdup("");
              };

var:          ident                           
              {
                std::string temp;
                std::string id = $1.place;
                if (funcs.find(id) == funcs.end() && varTemp.find(id) == varTemp.end()){
                  printf("Identifier %s is not declared.\n", id.c_str());
                }
                else if (arrSize[id] > 1) {
                  printf("Did not provide index for array Identifier %s.\n", id.c_str());
                }

                $$.place = strdup(id.c_str());
                $$.code = strdup("");
                $$.arr = false;
              }
              | ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET  
              {
                std::string temp;
                std::string id = $1.place;
                if (funcs.find(id) == funcs.end() && varTemp.find(id) == varTemp.end()){
                  printf("Identifier %s is not declared.\n", id.c_str());
                }
                else if (arrSize[id] == 1) {
                  printf("Provided index for non-array Identifier %s.\n", id.c_str());
                }
                temp.append($1.place);
                temp.append(", ");
                temp.append($3.place);
                $$.place = strdup(temp.c_str());
                $$.code = strdup($3.code);
                $$.arr = true;
              };


%% 

std::string new_temp() {
  std::string t = "t" + std::to_string(tempCount);
  tempCount++;
  return t;
}

std::string new_label() {
  std::string t = "L" + std::to_string(labelCount);
  labelCount++;
  return t;
}

void yyerror(const char *msg) {
/* implement your error handling */
  printf("Error at line %d, position %d: %s\n", currLine, currPos, msg);
  exit(1);
}