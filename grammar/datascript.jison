/* lexical grammar */

%lex
esc                                                              "\\"
slash                                                            "/"
nl                                                               "\n"
star                                                             "*"
exponent                                                         [eE][+-]?[0-9]+
letter                                                           [$A-Za-z_]

%%
\s+                                                                     /* skip whitespace */
{slash}{slash}[^\n]*                                                    /* skip comments */
{slash}{star}[^{star}]*{star}{slash}                                    /* skip comments */
[0-9]+"."[0-9]*{exponent}?[fFdD]?                                       return 'FLOAT_LITERAL';
"."[0-9]+{exponent}?[fFdD]?                                             return 'FLOAT_LITERAL';
[0-9]+{exponent}[fFdD]?                                                 return 'FLOAT_LITERAL';
[0-9]+[fFdD]                                                            return 'FLOAT_LITERAL';
[1-9][0-9]*                                                             return 'DECIMAL_LITERAL';
"0"[xX][0-9a-fA-F]+                                                     return 'HEX_LITERAL';
"0"[0-7]*                                                               return 'OCTAL_LITERAL';
"0"[bB][0-1]+                                                           return 'BINARY_LITERAL';
[01]+[bB]                                                               return 'BINARY_LITERAL';
"const"                                                                 return 'CONST';
"big"                                                                   return 'BIG';
"bit"                                                                   return 'BIT';
"little"                                                                return 'LITTLE';
"uint8"                                                                 return 'UINT8';
"uint16"                                                                return 'UINT16';
"leuint16"                                                              return 'LEUINT16';
"uint32"                                                                return 'UINT32';
"leuint32"                                                              return 'LEUINT32';
"uint64"                                                                return 'UINT64';
"leuint64"                                                              return 'LEUINT64';
"int8"                                                                  return 'INT8';
"int16"                                                                 return 'INT16';
"leint16"                                                               return 'LEINT16';
"int32"                                                                 return 'INT32';
"leint32"                                                               return 'LEINT32';
"int64"                                                                 return 'INT64';
"leint64"                                                               return 'LEINT64';
"enum"                                                                  return 'ENUM';
"bitmask"                                                               return 'BITMASK';
"condition"                                                             return 'CONDITION';
"label"                                                                 return 'LABEL';
"union"                                                                 return 'UNION';
"sizeof"                                                                return 'SIZEOF';
".."                                                                    return 'RANGE';
"id"                                                                    return 'ID';
"in"                                                                    return 'IN';
"is"                                                                    return 'IS';
"forall"                                                                return 'FORALL';
"string"                                                                return 'STRING';
"+"                                                                     return 'PLUS';
"-"                                                                     return 'MINUS';
"~"                                                                     return 'TILDE';
"!"                                                                     return 'BANG';
"<<"                                                                    return 'SHIFTLEFT';
">>"                                                                    return 'SHIFTRIGHT';
"<="                                                                    return 'LE';
"<"                                                                     return 'LT';
">="                                                                    return 'GE';
">"                                                                     return 'GT';
"=="                                                                    return 'EQ';
"!="                                                                    return 'NE';
"*"                                                                     return 'MULTIPLY';
"/"                                                                     return 'DIVIDE';
"%"                                                                     return 'MODULO';
"^"                                                                     return 'XOR';
"&"                                                                     return 'AND';
"|"                                                                     return 'OR';
"||"                                                                    return 'LOGICALOR';
"&&"                                                                    return 'LOGICALAND';
"?"                                                                     return 'QUESTIONMARK';
"'"(?:[^'\\\n\r]|{esc}[ntbrf{esc}'"]|[0-7][0-7]?|[0-3][0-7][0-7])"'"    return 'CHAR_LITERAL';
\"(?:{esc}["bfnrt/{esc}]|{esc}"u"[a-fA-F0-9]{4}|[^"\\])*\"              yytext = yytext.substr(1,yyleng-2); return 'STRING_LITERAL';
{letter}(?:{letter}|[0-9])*                                             return 'IDENTIFIER';
"="                                                                     return '=';
"*="                                                                    return '*=';
"/="                                                                    return '/=';
"%="                                                                    return '%=';
"+="                                                                    return '+=';
"-="                                                                    return '-=';
"<<="                                                                   return '<<=';
">>="                                                                   return '>>=';
"&="                                                                    return '&=';
"^="                                                                    return '^=';
"|="                                                                    return '|=';
\[                                                                      return '[';
\]                                                                      return ']';
"."                                                                     return '.';
","                                                                     return ',';
"("                                                                     return '(';
")"                                                                     return ')';
"{"                                                                     return '{';
"}"                                                                     return '}';
"::"                                                                    return '::';
":"                                                                     return ':';
";"                                                                     return ';';
<<EOF>>                                                                 return 'EOF';

/lex

%start script

%%
script
    : decls EOF
          {return { decls: $decls };}
    ;

decls
    : decls decl
         {$$ = $decls; $$.push($decl);}
    |
         {$$ = [];}
    ;

decl
    : fielddefn ";"
         {$$ = $fielddefn;}
    | conditiondefn
    | constdecl ";"
         {$$ = $constdecl;}
    ;

label
    : LABEL expr "::" expr ":"
         {$$ = { nodeType: 'label',
                 global: $expr1,
                 local: $expr2 };}
    | LABEL expr ":"
         {$$ = { nodeType: 'label',
                 global: undefined,
                 local: $expr };}
    ;

fielddefn
    : label typedeclinfielddefn fielddefnfromargs
         {$$ = $fielddefnfromargs($label, $typedeclinfielddefn);}
    // Workaround for Jison bug 183.
    | typedeclinfielddefn
         {$$ = { nodeType: 'field',
                 label: undefined,
                 name: undefined,
                 type: $typedeclinfielddefn,
                 range: null,
                 init: undefined,
                 cond: undefined };}
    | typedeclinfielddefn fielddefnfromargs
         {console.log("fielddefn case 2");
          $$ = $fielddefnfromargs(undefined, $typedeclinfielddefn);}
    | label fielddefncall fielddefnfromname
         {console.log("fielddefn case 3");
          $$ = $fielddefnfromname($label, $fielddefncall.decl, $fielddefncall.args);}
    | fielddefncall fielddefnfromname
         {console.log("fielddefn case 4");
          $$ = $fielddefnfromname(undefined, $fielddefncall.decl, $fielddefncall.args);}
    ;

fielddefncall
    /* FIXME: add parameter list cases */
    : IDENTIFIER "(" /* typedeclsorparams */ ")"
         {$$ = { decl: $IDENTIFIER,
                 args: [] };}
    ;

funargs
    : funargs "," funarg
        {$$ = $funargs; $$.push($funarg);}
    | funarg
        {$$ = [$funarg];}
    ;

funarg
    : quantifiedexpr
    ;

/*
FIXME:

paramdefnnoid
funargnoid
*/

ambiguouscall
    // ParameterDefinitions
    : paramdefnnoid ")" optionaltypeargs
    | paramdefnnoid "," paramdefns ")" optionaltypeargs

    // FunctionArguments
    | funargnoid ")"
    | funargnoid "," funargs ")"
    | ")"

    // unrollings of ParameterDefinition
    //            -> TypeDeclaration IDENTIFIER
    //            -> DefinedType IDENTIFIER
    //            -> TypeSymbol IDENTIFIER
    | path IDENTIFIER ")" optionaltypeargs
    | path IDENTIFIER "," paramdefns ")" optionaltypeargs

    // unrollings of FunctionArgument
    //            -> QuantifiedExpr
    //            -> ...
    //            -> PrimaryExpr Postfixes
    //            -> IDENTIFIER Postfixes
    | path postfixnodot ")"
    | path postfixnodot "," funargs ")"
    | path postfixnodot postfixes ")"
    | path postfixnodot postfixes "," funargs ")"
    ;

optionaltypeargs
    : typeargs
    |
    ;

typeargs
    : "(" funargs ")"
        {$$ = $funargs;}
    | "(" ")"
        {$$ = [];}
    ;

call
    : "(" funargs ")"
        {$$ = { type: 'call',
                args: $funargs };}
    | "(" ")"
        {$$ = { type: 'call',
                args: [] };}
    ;

// typedeclsorparams
//     : typedeclnoid
//     | typedeclnoid "," typedecls
//     | paramdefnnoid
//     | paramdefnnoid "," paramdefns
//     // unrollings of ParameterDefinition
//     //            -> TypeDeclaration IDENTIFIER
//     //            -> DefinedType IDENTIFIER
//     //            -> TypeSymbol IDENTIFIER
//     | path IDENTIFIER
//     | path IDENTIFIER "," paramdefns
//     // unrollings of FunctionArgument
//     //            -> AssignmentExpr
//     //            -> ...
//     //            -> PrimaryExpr PostfixExpr
//     //            -> Path PostfixExpr
//     | path postfixnodot postfixes
//     | path postfixnodot postfixes "," 
//     | 
//     ;

postfixnodot
    : "[" expr "]"
        {$$ = { nodeType: 'index',
                offset: $expr };}
    | call
    | IS IDENTIFIER
        {$$ = { nodeType: 'test',
                condition: $IDENTIFIER };}
    ;

//     : primaryexpr "[" expr "]"
//         {$$ = { nodeType: 'indexexpr',
//                 array: $primaryexpr,
//                 offset: $expr };}
//     | primaryexpr "(" /* funargs */ ")"
//         {$$ = { nodeType: 'callexpr',
//                 callee: $primaryexpr,
//                 args: [] };}
//     | primaryexpr "." IDENTIFIER
//         {$$ = { nodeType: 'fieldexpr',
//                 container: $primaryexpr,
//                 field: $IDENTIFIER };}
//     | primaryexpr IS IDENTIFIER
//         {$$ = { nodeType: 'testexpr',
//                 value: $primaryexpr,
//                 condition: $IDENTIFIER };}

postfix
    : postfixnodot
    | "." IDENTIFIER
        {$$ = { nodeType: 'field',
                name: $IDENTIFIER };}
    ;

postfixes
    : postfix
        {$$ = [$postfix];}
    | postfixes postfix
        {$$ = $postfixes; $$.push($postfix);}
    ;


fielddefnfromargs
    : typeargs fielddefnfromname
         {$$ = function(label, decl) {
              return $fielddefnfromname(label, decl, $typeargs);
          };}
    | fielddefnfromname
         {$$ = function(label, decl) {
              return $fielddefnfromname(label, decl);
          };}
    ;

fielddefnfromname
    : IDENTIFIER arrayranges fielddefnfrominit
         {$$ = function(label, decl, args) {
              return $fielddefnfrominit(label, decl, args, $IDENTIFIER, $arrayranges);
          };}
/*
    | arrayranges fielddefnfrominit
         {$$ = function(label, decl, args) {
              return $fielddefnfrominit(label, decl, args, undefined, $arrayranges);
          };}
*/
    ;

fielddefnfrominit
    : fieldinit fieldcond
        {$$ = function(label, decl, args, name, ranges) {
              return { nodeType: 'field',
                       label: label,
                       name: name,
                       type: decl,
                       ranges: ranges,
                       init: $fieldinit,
                       cond: $fieldcond };
         };}
    | fieldinit
        {$$ = function(label, decl, args, name, ranges) {
              return { nodeType: 'field',
                       label: label,
                       name: name,
                       type: decl,
                       ranges: ranges,
                       init: $fieldinit,
                       cond: undefined };
         };}
    | fieldcond
        {$$ = function(label, decl, args, name, ranges) {
              return { nodeType: 'field',
                       label: label,
                       name: name,
                       type: decl,
                       ranges: ranges,
                       init: undefined,
                       cond: $fieldcond };
         };}
    // This rule is getting ignored by Jison bug 183.
    |
        {$$ = function(label, decl, args, name, ranges) {
              return { nodeType: 'field',
                       label: label,
                       name: name,
                       type: decl,
                       ranges: ranges,
                       init: undefined,
                       cond: undefined };
         };}
    ;

fieldinit
    : "=" typeval
        {$$ = $typeval;}
    ;

fieldcond
    : ":" expr
        {$$ = $expr;}
    ;

typeval
    : "{" typevals "}"
        {$$ = $typevals;}
    | constexpr
    ;

typevals
    : typevals "," typeval
        {$$ = $typevals; $$.push($typeval);}
    | typeval
        {$$ = [$typeval];}
    ;

constexpr
    : condexpr
    ;

expr
    : expr "," quantifiedexpr
        {$$ = { nodeType: 'comma',
                first: $expr,
                last: $quantifiedexpr };}
    | quantifiedexpr
    ;

quantifiedexpr
    : quantifier condexpr
        {$$ = { nodeType: 'quantified',
                quantifier: $quantifier,
                expr: $condexpr };}
    | condexpr
    ;

quantifier
    : FORALL IDENTIFIER IN unaryexpr ":"
        {$$ = { nodeType: 'quantifier',
                set: $unaryexpr };}
    ;

condexpr
    : lorexpr QUESTIONMARK expr ":" condexpr
        {$$ = { nodeType: 'cond',
                test: $lorexpr,
                cons: $expr,
                alt: $condexpr };}
    | lorexpr
    ;

lorexpr
    : landexpr LOGICALOR lorexpr
        {$$ = { nodeType: 'lor',
                left: $landexpr,
                right: $lorexpr };}
    | landexpr
    ;

landexpr
    : borexpr LOGICALAND landexpr
        {$$ = { nodeType: 'land',
                left: $borexpr,
                right: $landexpr };}
    | borexpr
    ;

borexpr
    : xorexpr OR borexpr
        {$$ = { nodeType: 'bor',
                left: $xorexpr,
                right: $borexpr };}
    | xorexpr
    ;

xorexpr
    : bandexpr XOR xorexpr
        {$$ = { nodeType: 'xor',
                left: $bandexpr,
                right: $xorexpr };}
    | bandexpr
    ;

bandexpr
    : eqexpr AND bandexpr
        {$$ = { nodeType: 'band',
                left: $eqexpr,
                right: $bandexpr };}
    | eqexpr
    ;

eqexpr
    : relexpr eqop eqexpr
        {$$ = { nodeType: 'eqexpr',
                left: $relexpr,
                op: $eqop,
                right: $eqexpr };}
    | relexpr
    ;

eqop
    : EQ | NE
    ;

/* FIXME: make iterative */
relexpr
    : shiftexpr relop relexpr
        {$$ = { nodeType: 'relexpr',
                left: $shiftexpr,
                op: $relop,
                right: $relexpr };}
    | shiftexpr
    ;

relop
    : LT | LE | GT | GE
    ;

shiftexpr
    : addexpr shiftop shiftexpr
        {$$ = { nodeType: 'shiftexpr',
                left: $addexpr,
                op: $shiftop,
                right: $shiftexpr };}
    | addexpr
    ;

shiftop
    : SHIFTLEFT | SHIFTRIGHT ;

addexpr
    : mulexpr addop addexpr
        {$$ = { nodeType: 'addexpr',
                left: $mulexpr,
                op: $addop,
                right: $addexpr };}
    | mulexpr
    ;

addop
    : PLUS | MINUS
    ;

mulexpr
    : castexpr mulop mulexpr
        {$$ = { nodeType: 'mulexpr',
                left: $castexpr,
                op: $mulop,
                right: $mulexpr };}
    | castexpr
    ;

mulop
    : MULTIPLY | DIVIDE | MODULO
    ;

castexpr
    /* : "(" definedtype ")" castexpr */
    : unaryexpr
    ;

unaryexpr
    : postfixexpr
    | unaryop castexpr
        {$$ = { nodeType: 'unexpr',
                op: $unaryop,
                arg: $castexpr };}
    | SIZEOF unaryexpr
        {$$ = { nodeType: 'unexpr',
                op: $SIZEOF,
                arg: $unaryexpr };}
    ;

unaryop
    : PLUS | MINUS | TILDE | BANG
    ;

postfixexpr
    : primaryexpr postfixes
        {$$ = { nodeType: 'postfixexpr',
                base: $primaryexpr,
                postfix: $postfixes };}
    | primaryexpr
    ;

//     : primaryexpr "[" expr "]"
//         {$$ = { nodeType: 'indexexpr',
//                 array: $primaryexpr,
//                 offset: $expr };}
//     | primaryexpr "(" /* funargs */ ")"
//         {$$ = { nodeType: 'callexpr',
//                 callee: $primaryexpr,
//                 args: [] };}
//     | primaryexpr "." IDENTIFIER
//         {$$ = { nodeType: 'fieldexpr',
//                 container: $primaryexpr,
//                 field: $IDENTIFIER };}
//     | primaryexpr IS IDENTIFIER
//         {$$ = { nodeType: 'testexpr',
//                 value: $primaryexpr,
//                 condition: $IDENTIFIER };}
//     | primaryexpr
//     ;

primaryexpr
    : IDENTIFIER
        {$$ = { nodeType: 'refexpr',
                name: $IDENTIFIER };}
    | constant
        {$$ = { nodeType: 'constexpr',
                value: $constant };}
    | "(" expr ")"
        {$$ = $expr;}
    ;

constant
    : DECIMAL_LITERAL | HEX_LITERAL | OCTAL_LITERAL | BINARY_LITERAL
    | FLOAT_LITERAL
    | CHAR_LITERAL
    | STRING_LITERAL
    ;

arrayranges
    : 
        {$$ = [];}
    | arrayranges arrayrange
        {$$ = $arrayranges; $$.push($arrayrange);}
    ;

arrayrange
    : "[" /* rangeexpr */ "]"
    ;

conditiondefn
    : CONDITION IDENTIFIER "(" $paramdefns ")"
        {$$ = { nodeType: 'condition',
                name: $IDENTIFIER,
                parameters: $paramdefns };}
    ;

paramdefns
    : 
        {$$ = [];}
    | paramdefn
        {$$ = [$paramdefn];}
    | paramdefns "," paramdefn
        {$$ = $paramdefns; $$.push($paramdefn);}
    ;

paramdefn
    : typedecl IDENTIFIER
        {$$ = { nodeType: 'parameter',
                name: $IDENTIFIER,
                type: $typedecl };}
    ;

typedeclinfielddefn
    : structdeclnocall
    | definedtypenoid
    | enumdecl
    ;

typedecl
    : structdecl
    | definedtype
    | enumdecl
    ;

structdecl
    : structdeclnocall
    | IDENTIFIER
      ("(" paramdefns ")")
      "{" decls "}"
        { $$ = { nodeType: 'struct',
                 byteOrder: undefined,
                 name: $IDENTIFIER,
                 parameters: $paramdefns,
                 body: $decls };}
    ;

structdeclnocall
    : byteordermodifier
      UNION
      IDENTIFIER
      ("(" paramdefns ")")
      "{" decls "}"
        { $$ = { nodeType: 'union',
                 byteOrder: $byteordermodifier,
                 name: $IDENTIFIER,
                 parameters: $paramdefns,
                 body: $decls };}
    | byteordermodifier
      UNION
      IDENTIFIER
      "{" decls "}"
        { $$ = { nodeType: 'union',
                 byteOrder: $byteordermodifier,
                 name: $IDENTIFIER,
                 parameters: [],
                 body: $decls };}
    | byteordermodifier
      IDENTIFIER
      ("(" paramdefns ")")
      "{" decls "}"
        { $$ = { nodeType: 'struct',
                 byteOrder: $byteordermodifier,
                 name: $IDENTIFIER,
                 parameters: $paramdefns,
                 body: $decls };}
    | byteordermodifier
      IDENTIFIER
      "{" decls "}"
        { $$ = { nodeType: 'struct',
                 byteOrder: $byteordermodifier,
                 name: $IDENTIFIER,
                 parameters: [],
                 body: $decls };}
    | UNION
      IDENTIFIER
      ("(" paramdefns ")")
      "{" decls "}"
        { $$ = { nodeType: 'union',
                 byteOrder: undefined,
                 name: $IDENTIFIER,
                 parameters: $paramdefns,
                 body: $decls };}
    | UNION
      IDENTIFIER
      "{" decls "}"
        { $$ = { nodeType: 'union',
                 byteOrder: undefined,
                 name: $IDENTIFIER,
                 parameters: [],
                 body: $decls };}
    | IDENTIFIER
      "{" decls "}"
        { $$ = { nodeType: 'struct',
                 byteOrder: undefined,
                 name: $IDENTIFIER,
                 parameters: [],
                 body: $decls };}
    ;

definedtype
    : typesymbol
    | builtintype
    ;

definedtypenoid
    : typesymbolnoid
    | builtintype
    ;

typesymbol
    : IDENTIFIER
        {$$ = { nodeType: 'typename',
                name: $IDENTIFIER };}
    | typesymbolnoid
    ;

typesymbolnoid
    : IDENTIFIER '.' path
        {$$ = { nodeType: 'typepath',
                path: [$IDENTIFIER].concat($dotoperands) };}
    ;


path
    : IDENTIFIER
        {$$ = [$IDENTIFIER];}
    | path "." IDENTIFIER
        {$$ = $path; $$.push($IDENTIFIER);}
    ;

enumdecl
    : (ENUM | BITMASK) builtintype IDENTIFIER? "{" enumitems "}"
    ;

builtintype
    : byteordermodifier?
      (  UINT8 | UINT16 | UINT32 | UINT64
       | INT8 | INT16 | INT32 | INT64
       | STRING
       | bitfield
      )
    ;

inttype
    : UINT8
    | UINT16
    | UINT32
    | UINT64
    | INT8
    | INT16
    | INT32
    | INT64
    ;

byteordermodifier
    : BIG
        {$$ = 'big';}
    | LITTLE
        {$$ = 'little';}
    ;

bitfield
    : BIT ":" /* INTEGER_LITERAL */
    ;

enumitems
    :
    ;

constdecl
    : CONST
    ;
