# CS152 Project

Note: `gcc 4.8.5` has some issues which cause `<regex>` to not work properly. See link: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=53631.

Use of `regex()` and `regex_replace()`  when a break or continue statement exists in a loop causes code inside a while loop to disappear . 

Code tested to be working with `gcc 11.3.0` successfully.

## Phase 0: BERP-L Specification

### Student information

* Brandon Trieu
* Eddy Tat
* Patrick Liu
* Rithvik Vukka

### The BERP-L Specification

* File extension: .berp
* Compiler name: BERP-LC

| Language Feature                  | Code Example |
| :---                              |    :----   |
| Integer scalar variables          |  number x<br>number y<br>number sum | 
| One-dimensional integer arrays    |  array x 100 |
| Assignment statements             | x = y<br> xv = 6 |
| Arithmetic operators              | x + y<br> x - y<br> x * y<br> x / y<br> x % y<br> x++<br> x-- |
| Relational operators              | x > 10<br> x < y<br> x == y<br> x >= 7<br> x <= y<br> x != y |
| While or Do-While loops           | while(x > y) { write(x) }<br> do { write(x) } while(x == 99) |
| If-then-else statements           | if(x != 1) { write(x) } elif(x < y) { write(y) } else { write(z) }<br> do { write(x) } if(x == 99) |
| Read and write statements         | read(x)<br>print(x)<br> print(1) |
| Comments                          | ;;hello |
| Functions                         | fun YYYY(x, y, z) { write(x)$ write(y)$ write(z)$ }<br> fun main(){ write(0)$ return(0)$ } |

* Commented lines will begin with two semicolons (;;comment).
* Identifiers must contain only alphabetic characters, including underscores.
* BERP-L ignores whitespaces.
* Delimiters are optional. Newline ('\n') or delimiter ('$') is accepted.
* Commas are used to separate arguments.
* Variables can only be declared one line at a time.

| Symbol in Language | Token Name |
| :---               | :---      |
| number             | INTEGER |
| "0", "7", "11", "727" | VALUE XXXX |
| "hello" "x" "\_\_ENV\_\_" | IDENT |
| +                  | ADD          |
| -                  | SUBTRACT |
| *                  | MULTIPLY |        
| /                  | DIVIDE   |
| %                  | MOD      |
| (                  | O_PAREN  |
| )                  | C_PAREN  |
| =                  | ASSIGN   |
| ++                 | INC  |
| --                 | DEC  |
| <                  | LESS |
| >                  | MORE |
| fun                | FUNCTION |
| while              | WHILE |
| do                 | DO |
| if                 | IF |
| elif               | ELIF |
| read               | READ |
| print              | PRINT |
| break              | BREAK |
| return             | RETURN |
| ,                  | COMMA |
| ;                  | COMMENT |
| $                  | DELIM |
| >=                 | G_EQ |
| <=                 | L_EQ |
| !=                 | N_EQ |
| ==                 | EQ |
| {                  | O_CBRK |
| }                  | C_CBRK |
| [                  | O_BRK |
| ]                  | C_BRK |
