/* ===== Main Grammar (non-terminals) ===== */

// INVARIANT: Every non-terminal is responsible for eating its own leading
//            (i.e., preceding) whitespace.

start
  = decls:TranslationUnit _ {
      return {
        nodeType: 'program',
        body: decls
      };
    }

TranslationUnit "program"
  = Declaration*

Declaration "declaration"
  = defn:FieldDefinition _ ";" { return defn; }
  / ConditionDefinition
  / decl:ConstDeclaration _ ";" { return decl; }

Label "label"
  = label:GlobalLabel? expr:Expression {
      return label === "" ? expr : {
        nodeType: 'expr:label',
        label: label,
        expr: expr
      };
    }

GlobalLabel "global label"
  = expr:Expression _ "::" {
      return { nodeType: 'label:global', expr: expr };
    }


// Conditions

ConditionDefinition "condition definition"
  = _ "condition" _ name:IDENTIFIER
    _ "(" params:ParameterDefinitionList ")"
    _ "{" conds:Condition* _ "}" {
      return {
        nodeType: 'defn:cond',
        name: name,
        params: params,
        conds: conds
      };
    }

ParameterDefinitionList
  = list:(first:ParameterDefinition
          rest:(_ "," param:ParameterDefinition { return param; })* {
            rest.unshift(first);
            return rest;
          })? { return list || []; }

ParameterDefinition "parameter"
  = type:TypeDeclaration _ name:IDENTIFIER {
      return {
        nodeType: 'param',
        name: name,
        type: type
      };
    }

Condition
  = cond:ConditionExpression _ ";" { return cond; }

ConditionExpression
  = Expression


// Enums

EnumDeclaration "enum declaration"
  = _ declType:("enum" / "bitmask") type:BuiltinType _ name:IDENTIFIER?
    _ "{" items:EnumItemList _ "}" {
      return {
        nodeType: "decl:" + declType,
        type: type,
        name: name,
        items: items
      };
    }

EnumItemList
  = list:(first:EnumItem
          rest:(_ "," item:EnumItem { return item; })* {
            rest.unshift(first);
            return rest;
          })? { return list || []; }

EnumItem
  = _ name:IDENTIFIER value:EnumItemValue? {
      return {
        nodeType: 'field:enum',
        name: name,
        value: value || undefined
      };
    }

EnumItemValue
  = _ "=" expr:ConstantExpression { return expr; }

ConstDeclaration "const declaration"
  = _ "const" type:TypeDeclaration _ name:IDENTIFIER _ "=" value:TypeValue {
      return {
        nodeType: 'decl:const',
        name: name,
        type: type,
        value: value
      };
    }

TypeValue "initializer value"
  = ConstantExpression
  / _ "{" values:TypeValueList _ "}" { return values; }

TypeValueList "initializer values"
  = first:TypeValue rest:(_ "," value:TypeValue { return value; })* {
      rest.unshift(first);
      return rest;
    }


FieldDefinition "field definition"
  = label:Label?
    type:TypeDeclaration
    args:TypeArgumentList?
    name:(_ name:IDENTIFIER? { return name; })
    range:ArrayRange*
    init:FieldInitializer?
    cond:FieldCondition? {
      return {
        nodeType: 'field:struct',
        label: label || undefined,
        type: type || undefined,
        args: args || null,
        name: name || undefined,
        range: range,
        init: init || undefined,
        cond: cond || undefined
      };
    }

TypeArgumentList "arguments"
  = _ "(" args:FunctionArgumentList? _ ")" { return args || []; }

FunctionArgumentList
  = first:FunctionArgument rest:(_ "," arg:FunctionArgument { return arg; })* {
      rest.unshift(first);
      return rest;
    }

FieldInitializer "field initializer"
  = _ "=" value:TypeValue { return value; }

FieldCondition "field condition"
  = _ ":" expr:Expression { return expr; }

TypeDeclaration "type declaration"
  = StructDeclaration
  / DefinedType
  / EnumDeclaration

StructDeclaration "struct or union declaration"
  = byteOrder:ByteOrderModifier?
    _ union:"union"?
    _ name:IDENTIFIER?
    params:(_ "(" list:ParameterDefinitionList ")" { return list; })?
    _ "{" fields:Declaration* _ "}" {
      return {
        nodeType: 'decl:' + (union || "struct"),
        byteOrder: byteOrder || undefined,
        name: name || undefined,
        params: params || undefined,
        fields: fields
      };
    }

DefinedType "defined type"
  = TypeSymbol
  / BuiltinType

TypeSymbol "type name"
  = _ base:IDENTIFIER path:DotOperand* {
      return {
        nodeType: 'type:name',
        base: base,
        path: path
      };
    }

BuiltinType "built-in type"
  = byteOrder:ByteOrderModifier? _
    type:( "uint8" / "uint16" / "uint32" / "uint64"
         / "int8"  / "int16"  / "int32"  / "int64"
         / "string"
         / BitField ) {
      return {
        nodeType: 'type:builtin',
        type: type
      };
    }

BitField "bit field"
  = "bit" _ ":" _ bits:INTEGER_LITERAL { return bits; }

ByteOrderModifier "byte-order modifier"
  = _ mod:("big" / "little") { return mod; }

ArrayRange "array range"
  = _ "[" range:RangeExpression? _ "]" { return range; }


// Expressions

Expression "Expression"
  = expr:QuantifiedExpression exprs:CommaOperand* {
      if (exprs.length > 0) {
        exprs.unshift(expr);
        return {
          nodeType: 'expr:comma',
          exprs: exprs
        };
      }
      return expr;
    }

CommaOperand
  = _ "," expr:QuantifiedExpression { return expr; }

QuantifiedExpression
  = quantifier:Quantifier? expr:ConditionalExpression {
      return quantifier
           ? { nodeType: 'expr:quantified', quantifier: quantifier, expr: expr }
           : expr;
    }

Quantifier
  = _ "forall" _ name:IDENTIFIER _ "in" quantified:UnaryExpression _ ":" {
      return {
        nodeType: 'quantifier',
        name: name,
        quantified: quantified
      };
    }

ConditionalExpression
  = expr:LogicalOrExpression operand:ConditionalExpressionOperand? {
      return operand
           ? { nodeType: 'expr:conditional',
               test: expr,
               cons: operand.cons,
               alt: operand.alt }
           : expr;
    }

ConditionalExpressionOperand
  = _ "?" cons:Expression _ ":" alt:ConditionalExpression { return { cons: cons, alt: alt }; }

ConstantExpression
  = ConditionalExpression

RangeExpression
  = expr1:Expression expr2:UpperBoundExpression? {
      return {
        nodeType: 'range',
        lower: expr2 ? expr1 : null,
        upper: expr2 || expr1
      };
    }

UpperBoundExpression
  = _ ".." expr:Expression { return expr; }

LogicalOrExpression
  = expr:LogicalAndExpression operand:LogicalOrOperand? {
      return operand
           ? { nodeType: 'expr:or', left: expr, right: operand }
           : expr;
    }

LogicalOrOperand
  = _ "||" expr:LogicalOrExpression { return expr; }

LogicalAndExpression
  = expr:InclusiveOrExpression operand:LogicalAndOperand? {
      return operand
           ? { nodeType: 'expr:binary', op: '&&', left: expr, right: operand }
           : expr;
    }

LogicalAndOperand
  = _ "&&" expr:LogicalAndExpression { return expr; }

InclusiveOrExpression
  = expr:ExclusiveOrExpression operand:InclusiveOrOperand? {
      return operand
           ? { nodeType: 'expr:binary', op: '|', left: expr, right: operand }
           : expr;
    }

InclusiveOrOperand
  = _ "|" expr:InclusiveOrExpression { return expr; }

ExclusiveOrExpression
  = expr:AndExpression operand:ExclusiveOrOperand? {
      return operand
           ? { nodeType: 'expr:binary', op: '^', left: expr, right: operand }
           : expr;
    }

ExclusiveOrOperand
  = _ "^" expr:ExclusiveOrExpression { return expr; }

AndExpression
  = expr:EqualityExpression operand:AndOperand? {
      return operand
           ? { nodeType: 'expr:binary', op: '&', left: expr, right: operand }
           : expr;
    }

AndOperand
  = _ "&" expr:AndExpression { return expr; }

EqualityExpression
  = expr:RelationalExpression operand:EqualityOperand? {
      return operand
           ? { nodeType: 'expr:binary', op: operand.op, left: expr, right: operand.expr }
           : expr;
    }

EqualityOperand
  = _ op:("==" / "!=") expr:EqualityExpression { return { op: op, expr: expr }; }

RelationalExpression
  = expr:ShiftExpression operands:RelationalOperand* {
      return operands.length > 0
           ? { nodeType: 'expr:nary', left: expr, operands: operands }
           : expr;
    }

RelationalOperand
  = _ op:("<=" / "<" / ">=" / ">") expr:ShiftExpression {
      return {
        nodeType: 'operand',
        op: op,
        expr: expr
      };
    }

ShiftExpression
  = expr:AdditiveExpression operands:ShiftOperand* {
      return operands.length > 0
           ? { nodeType: 'expr:nary', left: expr, operands: operands }
           : expr;
    }

ShiftOperand
  = _ op:("<<" / ">>") expr:AdditiveExpression {
      return {
        nodeType: 'operand',
        op: op,
        expr: expr
      };
    }

AdditiveExpression
  = expr:MultiplicativeExpression operands:Summand* {
      return operands.length > 0
           ? { nodeType: 'expr:nary', left: expr, operands: operands }
           : expr;
    }

Summand
  = _ op:("+" / "-") expr:MultiplicativeExpression {
      return {
        nodeType: 'operand',
        op: op,
        expr: expr
      };
    }

MultiplicativeExpression
  = expr:CastExpression operands:Multiplicand* {
      return operands.length > 0
           ? { nodeType: 'expr:nary', left: expr, operands: operands }
           : expr;
    }

Multiplicand
  = _ op:("*" / "/" / "%") expr:CastExpression {
      return {
        nodeType: 'operand',
        op: op,
        expr: expr
      };
    }

CastExpression
  = CastOperand
  / UnaryExpression

CastOperand
  = _ "(" type:DefinedType _ ")" expr:CastExpression {
      return {
        nodeType: 'expr:cast',
        type: type,
        expr: expr
      };
    };

UnaryExpression
  = PostfixExpression
  / UnaryOperand
  / SizeOfOperand

UnaryOperand
  = _ op:("+" / "-" / "~" / "!") expr:CastExpression {
      return {
        nodeType: 'expr:unary',
        op: op,
        expr: expr
      };
    }

SizeOfOperand
  = _ "sizeof" expr:UnaryExpression {
      return {
        nodeType: 'expr:unary',
        op: 'sizeof',
        expr: expr
      };
    }

PostfixExpression
  = expr:PrimaryExpression
    postfixes:(ArrayOperand / FunctionArgumentList / DotOperand / ChoiceOperand)* {
      return postfixes.length > 0
           ? { nodeType: 'expr:postfix', base: expr, postfixes: postfixes }
           : expr;
    }

ChoiceOperand
  = _ "is" _ name:IDENTIFIER {
      return {
        nodeType: 'postfix:choice',
        name: name
      };
    }

ArrayOperand
  = _ "[" expr:Expression _ "]" {
      return {
        nodeType: 'postfix:array',
        index: expr
      }
    }

FunctionArgumentList
  = _ "(" list:(first:FunctionArgument
                rest:(_ "," arg:FunctionArgument { return arg; })*)? _ ")" {
      return list || [];
    }

DotOperand
  = _ "." _ field:IDENTIFIER {
      return {
        nodeType: 'postfix:dot',
        field: field
      };
    }

PrimaryExpression
  = VariableName
  / Constant
  / ParenthesizedExpression

ParenthesizedExpression
  = _ "(" expr:Expression _ ")" { return expr; }

VariableName
  = _ name:IDENTIFIER {
      return {
        nodeType: 'expr:var',
        name: name
      };
    }

FunctionArgument
  = QuantifiedExpression

Constant
  = _ lit:( INTEGER_LITERAL
          / FLOAT_LITERAL
          / CHAR_LITERAL
          / STRING_LITERAL ) { return lit; }



/* ===== Lexical Grammar (terminals) ===== */

// FIXME: include source of number literals

FLOAT_LITERAL "float literal"
  = whole:Decimal+ "." frac:Decimal* exp:Exponent? FloatSuffix? {
      return {
        nodeType: 'lit:float',
        value: parseFloat(whole.join("") + "." + frac.join("") + exp)
      };
    }
  / "." frac:Decimal+ exp:Exponent? FloatSuffix? {
      return {
        nodeType: 'lit:float',
        value: parseFloat("." + frac.join("") + exp)
      };
    }
  / whole:Decimal+ exp:Exponent FloatSuffix? {
      return {
        nodeType: 'lit:float',
        value: parseFloat(whole.join("") + exp)
      };
    }
  / whole:Decimal+ FloatSuffix {
      return {
        nodeType: 'lit:float',
        value: parseFloat(whole.join(""))
      };
    }

Decimal
  = [0-9]

Exponent
  = e:[eE] sign:[+-]? exp:Decimal+ {
      return e + sign + exp.join("");
    }

FloatSuffix
  = [fFdD]

DECIMAL_LITERAL "decimal literal"
  = d1:[1-9] ds:Decimal* {
      return {
        nodeType: 'lit:int',
        value: parseInt(d1 + ds.join(""))
      };
    }

HEX_LITERAL "hex literal"
  = "0" [xX] digits:Hex+ {
      return {
        nodeType: 'lit:int',
        value: parseInt(digits.join(""), 16)
      };
    }

Hex
  = [0-9a-fA-F]

OCTAL_LITERAL "octal literal"
  = "0" digits:Octal* {
      return {
        nodeType: 'lit:int',
        value: parseInt(digits.join(""), 8)
      };
    }

Octal
  = [0-7]

BINARY_LITERAL "binary literal"
  = "0" [bB] bigits:Binary+ {
      return {
        nodeType: 'lit:int',
        value: parseInt(bigits.join(""), 2)
      };
    }
  / bigits:Binary+ [bB] {
      return {
        nodeType: 'lit:int',
        value: parseInt(bigits.join(""), 2)
      };
    }

INTEGER_LITERAL
  = DECIMAL_LITERAL
  / HEX_LITERAL
  / OCTAL_LITERAL
  / BINARY_LITERAL

Binary
  = [01]

CHAR_LITERAL
  = "'" ch:Character "'" { return ch; }

Character
  = ch:[^'\\\n\r] {
      return {
        nodeType: 'lit:char',
        source: ch,
        value: ch
      };
    }
  / "\\" esc:[ntbrf\\'"] {
      var source = "'\\" + esc + "'";
      return {
        nodeType: 'lit:char',
        source: source,
        value: (0,eval)(source)
      };
    }
  / ds:OctalCharacter {
      var source = "'" + ds + "'";
      var code = parseInt(ds, 8).toString(16);
      while (code.length < 4) {
        code = "0" + code;
      }
      return {
        nodeType: 'lit:char',
        source: source,
        value: (0,eval)('"\\u' + code + '"')
      };
    }

OctalCharacter
  = d1:Octal d2:Octal? { return d1 + d2; }
  / d1:[0-3] d2:Octal d3:Octal { return d1 + d2 + d3; }

STRING_LITERAL
  = '"' cs:StringCharacter* '"' {
      var value = cs.map(function(c) { return c.value; }).join("");
      var source = cs.map(function(c) { return c.source; }).join("");
      return {
        nodeType: 'lit:string',
        source: source,
        value: value
      };
    }

StringCharacter
  = "\\" code:["bfnrt/\\] {
      var source = "\\" + code;
      return {
        source: source,
        value: (0,eval)('"' + source + '"')
      };
    }
  / "\\u" d1:Hex d2:Hex d3:Hex d4:Hex {
      var source = "\\u" + d1 + d2 + d3 + d4;
      return {
        source: source,
        value: (0,eval)('"' + source + '"')
      };
    }
  / c:[^"\\] { return { source: c, value: c }; }

IDENTIFIER
  = !Keyword name:IdentifierName { return name; }

Keyword
  = ( "big"
    / "bitmask"
    / "bit"
    / "condition"
    / "const"
    / "enum"
    / "forall"
    / "int8"
    / "int16"
    / "int32"
    / "int64"
    / "in"
    / "is"
    / "leint16"
    / "leint32"
    / "leint64"
    / "leuint16"
    / "leuint32"
    / "leuint64"
    / "little"
    / "sizeof"
    / "string"
    / "uint8"
    / "uint16"
    / "uint32"
    / "uint64"
    / "union" ) !IdChar

IdentifierName
  = c1:Letter cs:IdChar* {
      return {
        nodeType: 'id',
        name: c1 + cs.join("")
      };
    }

Letter
  = [$_a-zA-Z]

IdChar
  = Letter
  / Decimal

/* ===== Whitespace ===== */

_ "whitespace"
  = (Whitespace / Comment)*

Whitespace
  = [ \t\n\r]

Comment
  = "//" [^\n]*
  / "/*" [^*]* "*"+ ([^/*] [^*]* "*"+)* "/"

