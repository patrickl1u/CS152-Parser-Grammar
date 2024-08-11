%{
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include <vector>
    #include <regex>
    #include <stack>
    using namespace std;

    extern int yylex();
    extern int yyparse();
    extern FILE* yyin;
    extern int yylineno;

    void yyerror(const char* s);

   struct CodeNode{
        std::string code;
        std::string name;
    };

    // function specific variables
    // might need to make separate definition for
    // functions since this gets cleared after every function
    struct NodeNode{
        string varname;
        int type;
        // could use enum but whatever
        // 0: number
        //      list.at(0): number line
        //      list.at(1): number value // dont need but w/e already here

        // 1: array
        //      list.at(0): number line
        //      list.at(1): array size // probably dont need but see above
        // 2: function
        //      list of params
        vector<string> list;
    };

    // set true if any error found
    // do not print any mil code
    // will need to set manually if not using yyerror()
    bool errorsfound = false;

    // store per function vars
    vector<NodeNode*> table;

    // second table cuz y not
    // need to check these for def 
    // either in body or param
    vector<NodeNode*> checktable;

    // don't clear functable
    vector<NodeNode*> functable;
    int funcnum = 0;

    // check table for uncaught break statements
    // stack<NodeNode*> breaktable;
    // just use vector as a stack
    vector<NodeNode*> breaktable;

    // same thing as above but for continue statements
    vector<NodeNode*> continuetable;

    // lazy
    // never reuses a tmp var
    // reset along with funcnum if this changes
    int tmpvarnum = 0;
    int tmplabnum = 0;

    // solazy
    // table of function calls to check
    // check after depth first stuff, function def in table doesnt exist
    vector<NodeNode*> callfunctable;
    int checkfunctioncalllater(string funcname, int lineno){
        NodeNode *nnode = new NodeNode;
        nnode->varname = funcname;
        vector<string> tmptable;
        tmptable.push_back(to_string(lineno));
        nnode->list = tmptable;
        callfunctable.push_back(nnode);
        return 0;
    }
    // lol
    void printfuncs();
    int findfunc(string fname);

    // yyerror handles abortion of mil code generation
    // jk yyerror will print wrong line no
    int timetocheckfunctioncalls(){
        // printf("checking funcs\n");
        // following line needs void printfuncs();
        // printfuncs();
        for(int i = 0; i < callfunctable.size(); i++){
            NodeNode *nnode = callfunctable.at(i);
            // printf("func %s check at %s\n", nnode->varname.c_str(), nnode->list.at(0).c_str());
            string curname = nnode->varname;
            if(!findfunc(curname)){
                string err = string("function ") + curname + string(" not found!\n");
                // yyerror(err.c_str());     
                printf("Error at line %s: %s", nnode->list.at(0).c_str(), err.c_str());
                // manually raise error flag
                errorsfound = true;
            }       
        }
        // return 0 always
        // error check is handled by errorsfound bool flag
        return 0;
    }

    // keywords
    // probably wont use...
    vector<string> keywordlist{"array", "return", "if", "else", "elif", "do", "while", "read", "print", "break", "write", "fun"};

    int addtochecklist(string vname, int vtype, int lineno){
        NodeNode *bnode = new NodeNode;
        bnode->varname = vname;
        bnode->type = vtype;
        vector<string> tmplist;
        string errlinenum = to_string(lineno);
        tmplist.push_back(errlinenum);
        bnode->list = tmplist;
        checktable.push_back(bnode);
        return 0;
    }

    // moved saving of functions to addfunc()
    int addvar(string vname, int vtype, vector<string> paramlist){
        // printf("adding var!\n");
        NodeNode* bnode = new NodeNode;
        bnode->varname = vname;
        bnode->type = vtype;
        bnode->list = paramlist;
        table.push_back(bnode);
        return 0;
    }

    int addfunc(string fname, vector<string> paramslist){
        NodeNode * fnode = new NodeNode;
        fnode->varname = fname;
        fnode->type = 2;
        fnode->list = paramslist;
        functable.push_back(fnode);
        return 0;
    }

    // return 1 if variable name exists in function context
    // return 0 if not found
    int findvar(string vname){
        for(int i = 0; i < table.size(); i++){
            NodeNode* bnode = table.at(i);
            if(vname.compare(bnode->varname) == 0){
                return 1;
            }
        }
        return 0;
    }

    // only use this for main search
    // does not work for recursive calls 
    // return 1 if function name exists
    // return 0 if not found
    int findfunc(string fname){
        for(int i = 0; i < functable.size(); i++){
            NodeNode *fnode = functable.at(i);
            if(fname.compare(fnode->varname) == 0){
                return 1;
            }
        }
        return 0;
    }

    // debug
    void printvars(){
        printf("func %i vars (size %i):\n", funcnum, (int)table.size());
        for(int i = 0; i < table.size(); i++){
            NodeNode *bnode = table.at(i);
            printf("%s\n", bnode->varname.c_str());
        }
    }

    // debug
    void printfuncs(){;
        printf("saved funcs:\n");
        for(int i = 0; i < functable.size(); i++){
            NodeNode *fnode = functable.at(i);
            printf("function %s\n", fnode->varname.c_str());
            for(int j = 0; j < fnode->list.size(); j++){
                printf("\tparam %s\n", fnode->list.at(j).c_str());
            }
        }
    }

    void clearvars(){
        while(table.size() > 0){
            table.pop_back();
        }
    }

    void clearchecklist(){
        while(checktable.size() > 0){
            checktable.pop_back();
        }
    }

    // tmp vars do not get pushed back to table at same time as other vars
    // wont appear in table to be able to check
    string gettmpvar(){
        // return tmp+tmpvarnum
        // printf("gettmpvar\n");
        string ret = string("_temp") + to_string(tmpvarnum);
        tmpvarnum++;
        vector<string> emptyparams;
        // push back yylineno for consistency
        emptyparams.push_back(to_string(yylineno));
        addvar(ret, 0, emptyparams);
        // NodeNode *bnode = new NodeNode;
        // bnode->varname = ret;
        // bnode->type = 0;
        // table.push_back(bnode);
        return ret;
    }

    string getlabel(){
        string ret = string("_label") + to_string(tmplabnum);
        tmplabnum++;
        return ret;
    }

    // returns a 1 if a name for whatever matches a reserved keyword
    // returns 0 if otherwise
    int checkreserved(string thingname){
        for(int i = 0; i < keywordlist.size(); i++){
            if(thingname.compare(keywordlist.at(i)) == 0){
                return 1;
            }
        }
        return 0;
    }
%}

%union {
    int intval;
    // char *strval[100];
    char *strval;
    struct CodeNode *pnode;
}
// error message
%locations
%define parse.error verbose

%start startstart
// math operations
%token ADD SUBTRACT MULTIPLY DIVIDE MOD
%token INTEGER
%token <intval> VALUE
%token <intval> ARRAY

%token INC DEC

// logic
%token IF ELSE ELIF DO WHILE RETURN BREAK CONTINUE
//%type <intval> logic_struct logic_meat //logic_meat_yes logic_meat_no

// comparison
%token MORE LESS EQ N_EQ G_EQ L_EQ 

// assignment
%token ASSIGN

// function
%token <strval> FUNCTION

// brackets
%token O_PAREN C_PAREN O_CBRK C_CBRK O_BRK C_BRK 

// related stuff but idk what to call
%token COMMENT DELIM COMMA  
%token <strval> IDENT 

// file operations
%token PRINT READ WRITE 
%token <strval> FILENAME


// precedence
%left N_EQ MORE LESS G_EQ L_EQ EQ
%left ADD SUBTRACT
%left MULTIPLY DIVIDE MOD
%left IDENT

// %right EQ

// part 3
%type <pnode> newstart function_struct function_meat variables
%type <pnode> exp logic_meat while_check function_input
%type <pnode> startstart function_call parent_function_call
%type <pnode> parent_function_meat parent_if_code

// part 4
%type <pnode> compare

%%
// todo (in no particular order): 
// - true/false?

// todo semantic errors
    // Using continue statement outside a loop. 

// beginning of input

startstart: newstart
                {
                    // only print here
                    // printfuncs();
                    // some semantic error checks
                    // check to find if "main" func exists
                    if(!findfunc("main")){
                        // don't call yyerror line num prob incorrect
                        // no line to highlight
                        printf("Error: no main function found!");
                        // exit(-1);
                        errorsfound = true;
                    }

                    // if it works it works
                    timetocheckfunctioncalls();

                    // check for extraneous break statements
                    if(breaktable.size()){
                        // printf("extra break\n");
                        for(int i = 0; i < breaktable.size(); i++){
                            NodeNode *nnode = breaktable.at(i);
                            // don't use yyerror
                            printf("Error at line %s: %s statement outside of loop\n", nnode->list.at(0).c_str(), nnode->varname.c_str());
                        }
                        errorsfound = true;
                    }

                    // check for cont statements
                    if(continuetable.size()){
                        for(int i = 0; i < continuetable.size(); i++){
                            NodeNode *nnode = continuetable.at(i);
                            // don't use yyerror
                            printf("Error at line %s: %s statement outside of loop\n", nnode->list.at(0).c_str(), nnode->varname.c_str());
                        }
                        errorsfound = true;
                    }

                    // exit if any errors found
                    if(errorsfound){
                        exit(-1);
                    }

                    CodeNode *node = new CodeNode;
                    node->name = $1->name;
                    node->code = $1->code;
                    printf("%s\n", node->code.c_str());
                    $$ = node;
                }

newstart: function_struct newstart
                {   
                    // printf("program_start -> function\n");
                    CodeNode *node = new CodeNode;
                    node->name = $1->name;
                    node->code = string("func ") + node->name + string("\n");
                    // current function code
                    node->code += $1->code;
                    // next function code
                    node->code += $2->code;
                    // pass up to startstart
                    $$ = node;
                }
    | COMMENT newstart
                {   
                    // printf("program_start -> comment\n");
                    // do nothing
                    CodeNode *node = new CodeNode;
                    // add code following comment
                    node->name = $2->name;
                    node->code = $2->code;
                    $$ = node;
                }
    | 		    
                {   
                    // printf("porgram_start -> epsilon\n");
                    CodeNode *node = new CodeNode;
                    $$ = node;
                }
    | error newstart
                {
                    // absorb errors
                    $$ = $2;
                }

// function definition
function_struct:    
               {   
                    // printf("function_struct -> epsilon\n");
                    CodeNode *node = new CodeNode;
                    $$ = node;
                }
    | FUNCTION IDENT O_PAREN function_input C_PAREN O_CBRK parent_function_meat C_CBRK /*function_struct*/
                {   
                    // printf("function_struct -> function %s\n", $2);
                    CodeNode *node = new CodeNode;
                    // printvars();
                    // insert function definition into functable
                    // - params list
                    // - insert params into paramslist
                    string rawparams = $4->code;
                    string nn = string("\n");
                    vector<string> paramslist;
                    stringstream sstream(rawparams);
                    while(getline(sstream, nn, '\n')){
                        paramslist.push_back(nn.substr(2));
                    }
                    // push to functable
                    addfunc($2, paramslist);

                    // check that vars used are actually defined
                    for(int i = 0; i < checktable.size(); i++){
                        // check for def
                        NodeNode *tmpnode = checktable.at(i);
                        string vname = tmpnode->varname;
                        bool foundinparams = false;
                        for(int j = 0; j < paramslist.size(); j++){
                            if(vname.compare(paramslist.at(j)) == 0){
                                foundinparams = true;
                                break;
                            }
                        }
                        if(!foundinparams){
                            // generate error message
                            // yyerror will give wrong line no
                            string varlinenum = tmpnode->list.at(0);
                            // string err = string("Error at line ")
                            printf("Error at line %s: use of undeclared variable %s\n", varlinenum.c_str(), vname.c_str());
                            // set flag to error
                            errorsfound = true;
                        }
                    }

                    // define function input
                    for(int i = 0; i < paramslist.size(); i++){
                        node->code += string(". ") + paramslist.at(i) + string("\n");
                        // define var within parser
                        vector<string> nodenodelist;
                        nodenodelist.push_back(to_string(yylineno));
                        addvar(paramslist.at(i), 0, nodenodelist);
                        node->code += string("= ") + paramslist.at(i) + string(", $") + to_string(i) + string("\n");
                    }

                    // do not include function name here
                    // first function will be returned by first state (newstart)
                    // rest of functions will be defined inside code
                    node->code += $7->code;
                    // pass up function name to first state (newstart)
                    node->name = $2;
                    // close function
                    node->code += string("endfunc\n");
                    funcnum++;
                    // clear table(s)
                    clearvars();
                    clearchecklist();
                    // check for existing function and code
                    // uncomment if end symbol gets uncommented in this state
                    // if($9->name.compare("") != 0){
                    //     node->code += string("func ") + $9->name + string("\n");
                    //     node->code += $9->code;     
                    // }
                    $$ = node;
                }
    // | error '\n'
    //             {
    //                 // absorb errors
    //                 $$ = $2;
    //             }

// accepted input for a function definition
// also use for function call
function_input: /*list*/ 
                {   
                    // printf("function_input -> epsilon\n");
                    CodeNode *node = new CodeNode;
                    // nothing pass up
                    // node->name = $1->name;
                    // node->code = $1->code;
                    $$ = node;
                }
    | COMMA function_input
                {   
                    // printf("function_input -> comma\n");
                    // do nothing
                    CodeNode *node = new CodeNode;
                    // add code following comma
                    // just pass up name cus why not 
                    node->name = $2->name;
                    node->code = $2->code;
                    $$ = node;
                }
    // only accept definitions here
    | INTEGER IDENT function_input
                {   
                    // printf("function_input -> ident %s\n", $1);
                    CodeNode *node = new CodeNode;
                    node->name = $2;
                    // push definition of func param
                    node->code = string(". ") + $2 + string("\n");
                    // add code following ident
                    node->code += $3->code;
                    $$ = node;
                }
    // should work ???
    // not sure if required
    | ARRAY IDENT variables function_input
                {   
                    printf("function_input -> array ident %s\n", $2);
                }
    | error function_input
                {
                    // error
                    $$ = $2;
                }

// remove recursive state call from end of all in 'function_meat'
parent_function_meat: function_meat parent_function_meat
                {
                    CodeNode *node = new CodeNode;
                    node->name = $1->name;
                    node->code = $1->code;
                    // append rest
                    node->code += $2->code;
                    $$ = node;
                }
    | 
                {
                    // epsilon
                    $$ = new CodeNode;
                }


// main logic of everything 
function_meat: COMMENT 
                {   
                    // printf("function_body -> comment\n");
                    // do nothing
                    CodeNode *node = new CodeNode;
                    // add code following comment
                    // node->name = $2->name;
                    // node->code = $2->code;
                    $$ = node;
                }
    | DELIM 
                {   
                    // printf("function_body -> delimiter\n");
                    // do nothing
                    CodeNode *node = new CodeNode;
                    // add code following delim
                    // node->name = $2->name;
                    // node->code = $2->code;
                    $$ = node;
                }
    // should work 
    | BREAK /*function_meat*/
                {   
                    // printf("function_body -> break\n");
                    CodeNode *node = new CodeNode;
                    node->code += "REPLACEWITHBREAKHERE\n";
                    // push this instance of break to stack
                    // pop when replaced by regex
                    NodeNode *nnode = new NodeNode;
                    nnode->varname = "break";
                    // forgot about type field lol
                    vector<string> tmpvector;
                    tmpvector.push_back(to_string(yylineno));
                    nnode->list = tmpvector;
                    breaktable.push_back(nnode);
                    $$ = node;
                }
    
    | CONTINUE
                {
                    // printf("function_body -> break\n");
                    CodeNode *node = new CodeNode;
                    node->code += "REPLACEWITHCONTHERE\n";
                    // push this instance of break to stack
                    // pop when replaced by regex
                    NodeNode *nnode = new NodeNode;
                    nnode->varname = "continue";
                    // forgot about type field lol
                    vector<string> tmpvector;
                    tmpvector.push_back(to_string(yylineno));
                    nnode->list = tmpvector;
                    continuetable.push_back(nnode);
                    $$ = node;
                }
    | parent_if_code
                {
                    // pass up code node
                    $$ = $1;
                }
    // declare variable only
    | INTEGER IDENT 
                {   
                    // printf("function_body -> number %s declare\n", $2);
                    CodeNode *node = new CodeNode;
                    node->code = "";
                    node->name = $2;
                    // check for existing ident
                    string var_name = node->name;
                    if(findvar(var_name)){  
                        string err = "redefinition of existing symbol " + var_name + "\n";
                        yyerror(err.c_str());
                    }                    // add to list of idents
                    vector<string> nodenodelist;
                    nodenodelist.push_back(to_string(yylineno));
                    addvar($2, 0, nodenodelist);
                    // assign and pass along node
                    node->code += string(". ") + node->name + string("\n");
                    // append rest of code
                    // node->code += $3->code;
                    $$ = node;
                }
    // declare and assign variable value
    | INTEGER IDENT ASSIGN variables 
                {   
                    // printf("function_body -> ident %s declare and assign variable\n", $2);
                    std::string var_name = $2;
                    // search for dup name
                    // if(findvar(var_name)){
                        // string err = "redefinition of existing symbol " + var_name + "\n";
                    //     yyerror(err.c_str());
                    // }
                    for(int i = 0; i < table.size(); i++){
                        NodeNode *tmpnode = table.at(i);
                        if(var_name.compare(tmpnode->varname) == 0){
                            // string err = "invalid usage of array " + varname + " as variable\n";
                            string err = "redefinition of existing symbol " + var_name + "\n";                            // printf("Error at line %s: %s", tmpnode->list.at(0).c_str(), err.c_str());
                            // todo: line num off by 1 all the time
                            // if no code follows state with error before newline
                            // semantic error 4: Defining a variable more than once 
                            yyerror(err.c_str());
                            
                        }
                    }
                    // check conflict for keywords
                    // effectively useless returns as symbol generates syntax err anyways
                    if(checkreserved(var_name)){
                        printf("name conflict w reserved found!\n");
                    }
                    // add to lsit of idents
                    vector<string> emptyparams;
                    emptyparams.push_back(to_string(yylineno));
                    addvar($2, 0, emptyparams);
                    CodeNode *node = new CodeNode;
                    // prepend precursor code
                    node->code = $4->code;
                    // append making of ident variable
                    node->code += std::string(". ") + var_name.c_str() + std::string("\n");
                    // append assignment of something to ident
                    node->code += std::string("= ") + var_name + std::string(", ") + $4->name + std::string("\n");

                    // append code from state function_meat
                    // node->code += $5->code;
                    $$ = node;
                }
    // assign existing variable value
    | IDENT ASSIGN variables 
                {   
                    // printf("function_body -> ident %s assign variable\n", $1);
                    string varname = $1;
                    CodeNode *node = new CodeNode;
                    node->name = varname;
                    // DONT search for dup name
                    // make sure variable exists
                    if(!findvar(varname)){
                        string err = "use of undeclared variable " + varname + "\n";
                        yyerror(err.c_str());
                    }
                    // check to see if ident is of type int (0)
                    for(int i = 0; i < table.size(); i++){
                        NodeNode *tmpnode = table.at(i);
                        if(varname.compare(tmpnode->varname) == 0){
                            if(tmpnode->type != 0){
                                string err = "invalid usage of array " + varname + " as variable\n";
                                // yyerror sucks
                                // following line sucks more: only stores original def line number
                                // printf("Error at line %s: %s", tmpnode->list.at(0).c_str(), err.c_str());
                                yyerror(err.c_str());
                            }
                        }
                    }
                    // precursor code
                    node->code = $3->code;
                    // assign op
                    node->code += string("= ") + varname + string(", ") + $3->name + string("\n");
                    // rest of code
                    // node->code += $4->code;
                    $$ = node;
                }
    // declare array only
    // mil shoud only accept array size number (10, not a)
    | ARRAY IDENT VALUE 
                {   
                    // printf("function_body -> array %s declare size variable\n", $2);
                    std::string var_name = $2;
                    CodeNode *node = new CodeNode;
                    // pass current var name up
                    node->name = var_name;
                    // check for existing name
                    // todo? mil does not care
                    // search for dup name
                    if(findvar(var_name)){
                        string err = "redefinition of symbol" + var_name + "\n";
                        yyerror(err.c_str());
                    }
                    // create array definition in symbol table
                    vector<string> arrayparams;
                    // push back array size
                    // todo?
                    // arrayparams.push_back();
                    arrayparams.push_back(to_string(yylineno));
                    addvar(var_name, 1, arrayparams);
                    // check array size
                    if($3 < 1){
                        string err = "invalid array size of " + to_string($3) + "\n";
                        yyerror(err.c_str());                       
                    }
                    // append creation of array definition
                    node->code += std::string(".[] ") + var_name + std::string(", ") + to_string($3) + std::string("\n");
                    // printf("%s\n", node->code.c_str());
                    // append rest of function_meat
                    // node->code += $4->code;
                    $$ = node;
                }
    // assign variable to array index
    // does not work when assigning size of variable
    // is this an issue that needs to be addressed?
    | IDENT O_BRK variables C_BRK ASSIGN variables 
                {   
                    // printf("function_body -> array %s at variable assign variable\n", $1);
                    // "[]= a, 0, b"
                    // array at index 0 write b
                    // var name destination array
                    string var_name = $1;
                    CodeNode *node = new CodeNode;
                    node->name = var_name;
                    // check ident exists
                    if(!findvar(var_name)){
                        string err = "use of undeclared array " + var_name + "\n";
                        yyerror(err.c_str());
                    }
                    // check ident is an array
                    for(int i = 0; i < table.size(); i++){
                        NodeNode *tmpnode = table.at(i);
                        if(var_name.compare(tmpnode->varname) == 0){
                            // should be type 1 for array
                            if(tmpnode->type != 1){
                                string err = "invalid usage of variable " + var_name + " as an array\n";
                                // printf("Error at line %s: %s", tmpnode->list.at(0).c_str(), err.c_str());
                                yyerror(err.c_str());
                            }
                            // break here 
                            // if same variable defined multiple times 
                            // then multiple elements w/ same ->varname will exist
                            // multiple errors will be printed if so
                            break;                        
                        }
                    }
                    // copy preceding code
                    // variable to assign
                    node->code = $6->code;
                    // variable index for array
                    node->code += $3->code;
                    // assign array index a value
                    node->code += string("[]= ") + var_name + string(", ") + $3->name + string(", ") + $6-> name + string("\n");
                    // append rest of function_meat
                    // node->code += $7->code;
                    $$ = node;
                }
    // read ident
    | READ O_PAREN variables C_PAREN // function_meat
                {   //printf("function_body -> read variable\n");
                    CodeNode *node = new CodeNode;
                    node->code = $3->code;
                    node->name = $3->name;
                    node->code += ".< " + $3->name + "\n";

                    string varname = $3->name;
                    // make sure variable exists
                    if(!findvar(varname)){
                        string err = "use of undeclared variable " + varname + "\n";
                        yyerror(err.c_str());
                    }
                    // check to see if ident is of type int (0)
                    for(int i = 0; i < table.size(); i++){
                        NodeNode *tmpnode = table.at(i);
                        if(varname.compare(tmpnode->varname) == 0){
                            if(tmpnode->type != 0){
                                string err = "invalid usage of array " + varname + " as variable\n";
                                // yyerror sucks
                                // following line sucks more: only stores original def line number
                                // printf("Error at line %s: %s", tmpnode->list.at(0).c_str(), err.c_str());
                                yyerror(err.c_str());
                            }
                            // break here 
                            // if same variable defined multiple times 
                            // then multiple elements w/ same ->varname will exist
                            // multiple errors will be printed if so
                            break;
                        }
                    }
                    $$ = node;
                }
    // write variable (changed from ident)
    | WRITE O_PAREN variables C_PAREN 
                {   
                    // printf("function_body -> write\n");
                    CodeNode *node = new CodeNode;
                    // create array definition in symbol table
                    // todo
                    // copy preceding code
                    node->code = $3->code;
                    // append creation of array definition
                    node->code += std::string(".> ") + $3->name + std::string("\n");
                    // append rest of function_meat
                    // node->code += $5->code;
                    $$ = node;
                }
    // while something is true
    | WHILE O_PAREN logic_meat C_PAREN O_CBRK parent_function_meat C_CBRK
                {   
                    // printf("function_body -> while\n");
                    CodeNode *node = new CodeNode;
                    string while_loopbody = getlabel();      
                    string while_iftrue = getlabel();  
                    string while_end = getlabel();    
                    node->code = ": " + while_loopbody + "\n";
                    node->code += $3->code;
                    node->code += "?:= " + while_iftrue + ", " + $3->name + "\n";
                    node->code += ":= " + while_end + "\n";
                    node->code += ": " + while_iftrue + "\n";
                    // replace break statements before appending
                    // node->code += $6->code + "\n";
                    // printf("while meat: \n%s\nendwhilemeat\n", $6->code.c_str());
                    string whilemeatcode = $6->code;
                    string breakline = ":= " + while_end + "\n";
                    // run in loop
                    // need to pop stack 
                    while(whilemeatcode.find("REPLACEWITHBREAKHERE\n") != string::npos){
                        whilemeatcode = regex_replace(whilemeatcode, regex("REPLACEWITHBREAKHERE\n"), breakline, std::regex_constants::format_first_only);
                        breaktable.pop_back();
                    }
                    // printf("while meat: \n%s\nendwhilemeat\n", whilemeatcode.c_str());
                    // replace continue before append
                    string contline = ":= " + while_loopbody + "\n";
                    while(whilemeatcode.find("REPLACEWITHCONTHERE\n") != string::npos){
                        whilemeatcode = regex_replace(whilemeatcode, regex("REPLACEWITHCONTHERE\n"), contline, std::regex_constants::format_first_only);
                        continuetable.pop_back();
                    }
                    // attach now that changes are complete
                    node->code += whilemeatcode + "\n"; 
                    node->code += ":= " + while_loopbody + "\n";
                    node->code += ": " + while_end + "\n";
                    $$ = node;
                }
    // statements like 10++ will happen but no harm probably
    | variables 
                {   
                    // printf("function_body -> variables\n"); /*$$ = $2;*/
                    CodeNode *node = $1;
                    $$ = node;
                }
    // ...
    | RETURN variables 
                {   
                    // printf("function_body -> return variables\n");
                    // line no off here for var usage
                    // printvars();
                    CodeNode *node = new CodeNode;
                    // attach existing var def
                    node->code = $2->code;
                    // return var
                    node->code += string("ret ") + $2->name + string("\n");
                    // attach rest of stuff
                    // node->code += $3->code;
                    $$ = node;
                }
    |           
                {   
                    // printf("function_body -> epsilon\n");
                    // reset var list here
                    clearvars();
                    CodeNode *node = new CodeNode;
                    $$ = node;
                }
    | error 
                {
                    // absorb errors
                    // CodeNode *node = $2;
                    CodeNode *node = new CodeNode;
                    $$ = node;
                }

parent_if_code: 
                {
                    // epsilon
                    $$ = new CodeNode;
                }
    // if no else
    | IF O_PAREN logic_meat C_PAREN O_CBRK parent_function_meat C_CBRK // function_meat
                {   
                    // printf("function_body -> if statement\n");
                    CodeNode *node = new CodeNode;
                    string if_true = getlabel();      //label for if true
                    string if_false = getlabel();      //label for if false/after inside of if statement
                    node->code = $3->code;              //pass in code for boolean statement
                    node->code += "?:= " + if_true + ", " + $3->name + "\n";      //min language for if statement
                    node->code += ":= " + if_false + "\n";                         //min language for go to label2
                    node->code += ": " + if_true + "\n";                          //min language for label1 declaration
                    node->code += $6->code + "\n";                                  //pass in code for if statement
                    node->code += ": " + if_false + "\n";                          //min language for label2 declaration
                    $$ = node;
                }
    // if with else
    | IF O_PAREN logic_meat C_PAREN O_CBRK parent_function_meat C_CBRK ELSE O_CBRK parent_function_meat C_CBRK // function_meat
                {   
                    // printf("function_body -> if else statement\n");
                    CodeNode *node = new CodeNode;
                    string if_true = getlabel();      //label for if true
                    string if_false = getlabel();      //label for if false/after inside of if statement
                    string if_end = getlabel();      //label for end of if-else statement
                    node->code = $3->code;              //pass in code for boolean statement
                    node->code += "?:= " + if_true + ", " + $3->name + "\n";      //min language for if statement
                    node->code += ":= " + if_false + "\n";                         //min language for go to label
                    node->code += ": " + if_true + "\n";                          //min language for label1 declaration
                    node->code += $6->code + "\n";                                  //pass in code for inside of if statement
                    node->code += ":= " + if_end + "\n";                         //min language for go to label3
                    node->code += ": " + if_false + "\n";                          //min language for label2 declaration
                    node->code += $10->code + "\n";                                  //pass in code for else statement
                    node->code += ": " + if_end + "\n";                          //min language for label3 declaration
                    $$ = node;
                }

while_check: compare while_check
                {   printf("while check -> while body\n");}
    |           {   
                    // printf("while check -> epsilon\n");
                    CodeNode *node = new CodeNode;
                    $$ = node;
                }

// comparison
// may need to return true or false or something liek that
logic_meat: compare 
	            { 
                    // does this do anything?
                    $$ = $1;
                }

// comparison
compare: variables LESS variables
                {   //printf("compare -> variables LESS variables\n")
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    node->code = ". " + tmpname + "\n";
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    // compare operation
                    node->code += "< " + tmpname + ", " + $1->name + ", " + $3->name + "\n";
                    $$ = node;
                }
    | variables MORE variables
                {   //printf("compare -> variables MORE variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    node->code = ". " + tmpname + "\n";
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    // compare operation
                    node->code += "> " + tmpname + ", " + $1->name + ", " + $3->name + "\n";
                    $$ = node;
                }
    | variables L_EQ variables
                {   
                    // printf("compare -> variables L_EQ variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    node->code = ". " + tmpname + "\n";
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    //compare operation
                    node->code += "<= " + tmpname + ", " + $1->name + ", " + $3->name + "\n";
                    $$ = node;
                }
    | variables G_EQ variables
                {   
                    // printf("compare -> variables G_EQ variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    node->code = ". " + tmpname + "\n";
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    //compare operation
                    node->code += ">= " + tmpname + ", " + $1->name + ", " + $3->name + "\n";
                    $$ = node;
                }
    | variables N_EQ variables
                {   
                    // printf("compare -> variables N_EQ variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    node->code = ". " + tmpname + "\n";
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    //compare operation
                    node->code += "!= " + tmpname + ", " + $1->name + ", " + $3->name + "\n";
                    $$ = node;
                }
    | variables EQ variables
                {   
                    printf("compare -> variables EQ variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    node->code = ". " + tmpname + "\n";
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    //compare operation
                    node->code += "== " + tmpname + ", " + $1->name + ", " + $3->name + "\n";
                    $$ = node;
                }

// do math
// order of operations probably works but not sure
variables: variables ADD variables
                //{   printf("add %i\n", $1+$3); $$ = $1 + $3;}
                {   
                    // printf("variables -> variables ADD variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    // create temp var
                    node->code = string(". ") + tmpname + string("\n");
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    // add addition operation
                    node->code += string("+ ") + tmpname + string(", ") + $1->name + string(", ") + $3->name + string("\n");
                    $$ = node;
                }
    | variables SUBTRACT variables
                {   
                    // printf("variables -> variables MINUS variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    // create temp var
                    node->code = string(". ") + tmpname + string("\n");
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    // add addition operation
                    node->code += string("- ") + tmpname + string(", ") + $1->name + string(", ") + $3->name + string("\n");
                    $$ = node;
                }
    | variables MULTIPLY variables
                {   
                    // printf("variables -> variables MULTIPLY variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    // create temp var
                    node->code = string(". ") + tmpname + string("\n");
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    // add addition operation
                    node->code += string("* ") + tmpname + string(", ") + $1->name + string(", ") + $3->name + string("\n");
                    $$ = node;
                }
    | variables DIVIDE variables
                {   
                    // printf("variables -> variables DIVIDE variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    // create temp var
                    node->code = string(". ") + tmpname + string("\n");
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    // add addition operation
                    node->code += string("/ ") + tmpname + string(", ") + $1->name + string(", ") + $3->name + string("\n");
                    $$ = node;
                }
    | variables MOD variables
                {   
                    // printf("variables -> variables MOD variables\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    // create temp var
                    node->code = string(". ") + tmpname + string("\n");
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    node->code += $3->code;
                    // add addition operation
                    node->code += string("% ") + tmpname + string(", ") + $1->name + string(", ") + $3->name + string("\n");
                    $$ = node;
                }
    | O_PAREN variables C_PAREN 
                {   
                    // printf("variables -> O_PAREN variables C_PAREN\n");
                    CodeNode *node = $2;
                    $$ = node;
                }
    // one sided ops
    // probably works
    | variables INC
                {   //printf("variables -> increment\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    // create temp var
                    node->code = string(". ") + tmpname + string("\n");
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    // add addition operation
                    node->code += string("+ ") + tmpname + string(", ") + $1->name + string(", ") + string("1") + string("\n");
                    // write back to var
                    node->code += string("= ") + $1->name + string(", ") + tmpname + string("\n");
                    $$ = node;
                }
    | variables DEC
                {   //printf("variables -> decrement\n");
                    CodeNode *node = new CodeNode;
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    // create temp var
                    node->code = string(". ") + tmpname + string("\n");
                    // precursor code for variables on left/right
                    node->code += $1->code;
                    // add subtraction operation
                    node->code += string("- ") + tmpname + string(", ") + $1->name + string(", ") + string("1") + string("\n");
                    // write back to var
                    node->code += string("= ") + $1->name + string(", ") + tmpname + string("\n");
                    $$ = node;
                }
    | exp 
                {   
                    // printf("variables -> exp\n");
                    CodeNode *node = $1;
                    // pass along CodeNode
                    $$ = node;
                }

// access value, ident, array or function
// need to save and check function definition?
exp: VALUE    
                {   
                    CodeNode *node = new CodeNode;
                    // no preceding code
                    node->code = "";
                    // convert int to string
                    node->name = std::to_string($1);
                    // some error checks needed?
                    // maybe todo
                    $$ = node;
                }
    | IDENT 
                {   
                    // line no is correct here for variable
                    // printf("exp -> ident %s\n", $1);
                    CodeNode *node = new CodeNode;
                    // no preceding code
                    node->code = "";
                    // name is variable name
                    node->name = $1;
                    // string testerr = string("test error from exp->ident ") + $1 + string("\n");
                    // yyerror(testerr.c_str());

                    // check if ident exists
                    // checking here breaks things...
                    // see comments in 'todo: semantic errors'
                    string varname = node->name;

                    if(!findvar(varname)){
                        // string err = "use of undeclared variable " + varname + "\n";
                        // yyerror(err.c_str());
                        // may be a param
                        // pass up to check later
                        addtochecklist(varname, 0, yylineno);
                    //     // printfuncs();
                    //     // printvars();
                    //     // printf("done\n");
                    }
                    $$ = node;
                }
    | IDENT O_BRK variables C_BRK
                {   
                    // printf("exp -> array %s at variable fetch\n", $1);
                    CodeNode *node = new CodeNode;
                    // temp variable generator
                    string tmpname = gettmpvar();
                    node->name = tmpname;
                    // inherit variables
                    node->code = $3->code;
                    // add tmp definition
                    node->code += string(". ") + tmpname + string("\n");
                    // check if array exists
                    // todo
                    // access array element and assign to temp
                    node->code += string("=[] ") + tmpname + string(", ")+ $1 + string(", ") + $3->name + string("\n");

                    $$ = node;
                }
    // function call and pass variable up
    | /*IDENT O_PAREN function_call C_PAREN */ parent_function_call
                {   
                    // printf("exp -> function call %s\n", $1);
                    CodeNode *node = new CodeNode;
                    node->name = $1->name;
                    node->code = $1->code;
                    $$ = node;
                }
    |           
                {   
                    // printf("exp -> epsilon\n");
                    CodeNode *node = new CodeNode;
                    $$ = node;
                }
    
parent_function_call: IDENT O_PAREN function_call C_PAREN 
                {   
                    // printf("exp -> function call %s\n", $1);
                    CodeNode *node = new CodeNode;
                    // check params
                    // todo
                    // define params
                    node->code = $3->code;
                    // define output tmp var
                    string tmpvar = gettmpvar();
                    node->code += string(". ") + tmpvar + string("\n");

                    // check ident function exists
                    // printfuncs();
                    // check needs to occur but does not exist in table at
                    // this point in time...
                    string funcname = $1;
                    checkfunctioncalllater(funcname, yylineno);
                    // if(!findfunc(funcname)){
                    //     // printf("not found!!!\n");
                    //     string err = string("function ") + $1 + string(" not found!\n");
                    //     yyerror(err.c_str());
                    //     // exit(-1);
                    // }
                    
                    // call function
                    node->code += string("call ") + $1 + string(", ") + tmpvar + string("\n");
                    // pass tmp var up
                    node->name = tmpvar;
                    $$ = node;
                }


function_call: 
                {
                    // epsilon
                    CodeNode *node = new CodeNode;
                    $$ = node;
                }
    | variables
                {
                    // printf("debug: vars in function_call param %s\n", $1->name.c_str());
                    CodeNode *node = new CodeNode;
                    node = $1;
                    node->code += string("param ") + $1->name + string("\n");
                    $$ = node;
                }
    | IDENT function_call
                {
                    // add "param " to var name
                    printf("function call ident\n");
                    CodeNode *node = new CodeNode;
                    node->name = $1;
                    node->code = string("param ") + $1 + string("\n");
                    node->code += $2->code;
                    $$ = node;
                }
    | COMMA function_call
                {
                    // do nothing
                    CodeNode *node = new CodeNode;
                    // add code following comma
                    // just pass up name cus why not 
                    node->name = $2->name;
                    node->code = $2->code;
                    $$ = node;                    
                }

%%

int main(){
    yyin = stdin;
    while(!feof(yyin)){
        yyparse();
    }
    return 0;
}

void yyerror(const char* s){
    // most useless error message
    // almost always 'Syntax error'
    // https://www.ibm.com/docs/en/zos/2.2.0?topic=handling-yyerror-function
    // expand errors with YYERROR_VERBOSE
    // http://web.mit.edu/gnu/doc/html/bison_toc.html#SEC66
    printf("Error at line %d: %s\n", yylineno, s);
    // printf("%i", num_lines);
    // leave exit() commented to test even on error
    // exit(-1);
    errorsfound = true;
}
