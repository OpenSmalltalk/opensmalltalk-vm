/*------------------------------------------------------------
| Ak2Types.h
|-------------------------------------------------------------
|
| PURPOSE: To provide record specifications for "Ak2".
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 01.02.94 
|          06.17.94 added 'USE_LOGFILE'.
|          08.19.97 added C++ support.
------------------------------------------------------------*/
#ifndef _AK2TYPES_H_
#define _AK2TYPES_H_

#ifdef __cplusplus
extern "C"
{
#endif

/* #define USE_LOGFILE */
        /* Define this symbol only for debugging. */
        
/* ------------------------ EQUATES ------------------------- */

#define MaxCharsPerToken 256
#define LargeSpace       4     /* a space this size and up
                                * separates expressions from
                                * one another.
                                */


/* TokenType codes */

#define SpaceToken       1  /* one or more empty spaces     */
#define NumberToken      2  /* a number token               */
#define WordToken        3  /* either a comment or name     */
#define EnumWordToken    4  /* enumerator word              */
#define ParameterToken   5  /* parameter for parametric op  */
#define CommentToken     6
#define LeftParenToken   7
#define RightParenToken  8
#define EqualToken       9  /* equals sign, expression ID */
#define UserOpToken      10 /* user prefix operator word  */
#define CommaToken       11 /* parameter delimiter        */
#define IfToken          12 /* conditional operator       */
#define EQToken          13 /* equality test operator     */
#define NEToken          14 /* inequality test operator   */
#define GTToken          15 /* greater-than test operator */
#define LTToken          16 /* less-than test operator    */
#define LEToken          17 /* less-or-equal test operator */
#define GEToken          18 /* greater-or-equal test operator */
#define AndToken         19 /* logical And operator */
#define OrToken          20 /* logical Or operator */
#define NotToken         21 /* logical Not operator */
#define PlusToken        22 /* addition operator */
#define AmbigMinusToken  23 /* ambiguous minus operator */
#define MinusToken       24 /* subtraction operator */
#define NegateToken      25 /* negation operator */
#define MultiplyToken    26 /* multiplication operator */
#define DivideToken      27 /* division operator */
#define PowerToken       28 /* power operator */
#define SqrtToken        29 /* square root operator */
#define IntToken         30 /* integer-part operator */
#define ExpToken         31 /* e^x operator  */
#define LnToken          32 /* natural logarithm operator */
#define LogToken         33 /* Base 10 log operator       */
#define SinToken         34 /* sine operator */
#define CosToken         35 /* cosine operator */
#define TanToken         36 /* tangent operator */
#define ArcSinToken      37 /* arcsine operator */
#define ArcCosToken      38 /* arccosine operator */
#define ArcTanToken      39 /* arctangent operator */
#define FixToken         40 /* fixed point formatting operator */
#define SciToken         41 /* scientific formatting operator */
#define eToken           42 /* e enumerator                   */
#define PiToken          43 /* pi enumerator                  */

#define IsWordToken      (TheDataType==WordToken)
#define IsNumberToken    (TheDataType==NumberToken)
#define IsConstantToken  (TheDataType==eToken || TheDataType==PiToken)

/* A 'QuantityToken' is a quantity, either named or numbered.
   Assumes that words designating operators have been classed
   as some token other than 'WordToken'.
 */
#define IsQuantityToken   (IsWordToken || IsNumberToken || IsConstantToken)

#define IsEqualToken      (TheDataType==EqualToken)

#define IsIfToken         (TheDataType==IfToken)

#define IsMinusToken      (TheDataType==MinusToken)
#define IsNegateToken     (TheDataType==NegateToken)
#define IsNotToken        (TheDataType==NotToken)

#define IsLeftParenToken  (TheDataType==LeftParenToken)
#define IsCommaToken      (TheDataType==CommaToken)
#define IsRightParenToken (TheDataType==RightParenToken)

#define IsAmbiguousOpToken  (TheDataType==AmbigMinusToken)
#define IsUserOpToken       (TheDataType==UserOpToken)
#define IsParameterToken    (TheDataType==ParameterToken)

#define IsAmbiguousMinusToken (TheDataType==AmbigMinusToken)
                            
#define IsEnumToken      (TokenTypes[TheDataType].AttributeCode \
                          & Enumerator)

#define IsOpToken        (TokenTypes[TheDataType].AttributeCode \
                          & Operator)

#define IsInfixOpToken   (TokenTypes[TheDataType].AttributeCode \
                          & InfixOp)

#define IsPrefixOpToken  (TokenTypes[TheDataType].AttributeCode \
                          & PrefixOp)


#define IsParametricOpToken  ((IsPrefixOpToken) && !IsNegateToken && !IsNotToken)
        /* A Parametric operator is one which has parameters surrounded by
         * parentheses.
         */

typedef s32 (*ExitCodeProcedure)();  
                              
/* Operation Exit Codes */
        
#define OK               0 /* Valid completion of operation */
#define DivideByZero     1 /* Divide by zero error          */
#define TooIndirect      2 /* Indirection limit error       */
#define StackOverflow    3 /* too many numbers on stack     */
#define StackUnderflow   4 /* too few numbers on stack      */
#define OutOfRange       5 /* number can't represent result */
#define DomainError      6 /* outside defined function domain */
#define ParmOverflow     7 /* too many numbers on parm stack */
#define MissingParen     8 /* unbalanced parenthesis        */
#define NoFormula        9 /* no formula for the named item */
#define ReferentNotDefined 10 /* A name for an enumerator,
                               * operator or parameter was
                               * used but not defined.
                               */
#define CommaInWrongPlace  11 /* A comma was found outside of
                               * a parameter list.
                               */
#define TooManyParameters  12 /* Too many parameters supplied
                               * for the parametric operation.
                               */
#define MissingParameters  13 /* Too few parameters supplied
                               * for the parametric operation.
                               */
#define TooManyDecimalPlaces  14 /* Too many decimal places
                                  * specified for the 'Fix()'
                                  * operation. 
                                  */

/* Token AttributeCode masks */
#define Uniform      1  /* always the same image */
#define Enumerator   2
#define Operator     4
#define InfixOp      8
#define PrefixOp    16

/*------------------------------------------------------------
| TokenTypeRecord
|-------------------------------------------------------------
|
| PURPOSE: To hold information about a particular token type.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.27.93 
|          07.04.95 name changed from 'TokenType' to avoid
|                   conflict with Mac scripting type.
------------------------------------------------------------*/
typedef struct TokenTypeRecord
{
    u8   TokenTypeCode;
    u8   AttributeCode;
    u8   ParameterCount; /* for non-user ops */
    u8   OpPrecedence;
    ExitCodeProcedure Interpreter;
} TokenType2,  *AddressOfTokenType2;
                              
/*------------------------------------------------------------
| FormulaRecord
|-------------------------------------------------------------
|
| PURPOSE: To define a user-named operation or quantity.
|
| DESCRIPTION: There are two kinds of things that the user
| can name and express as a formula: 
|
|      Enumerators -- these are named expressions of quantity.
|
|      Operators -- these are named expressions of operation.
|
|
| The user can define an enumerator called 'a' like this: 
|
|                    a = 5 + 2
|
| Which means that enumerator 'a' is formed by evaluating
| the expression to the right of the equals sign, '5+2'.
| 
|
| The user can define an operator like this: 
|
|             Area(Length,Width) = Length * Width
|
|             to be used like this: z = Area(3,4)
|
| The formulation for operator 'Plus' shows the operations
| to be performed in terms of other operations and the
| parameters supplied within the parentheses. 
|
| The formula for an operator can include other 
| user-defined operators and enumerators as well.
|
| The formula for an operator can even refer to itself
| like this:
|
| To find the sum of the first x integers:
|
|      SumOfInt(x) = If( x=0, x, x+SumOfInt(x-1) )
|
|      The number of times a function may call itself
|      is limited by the size of the number and
|      parameter stacks and 'MaxOperationLevel'.
|
| In the record below, the 'FormulaList' is the list of 
| token records formed from the formula supplied by the user.  
|
| The 'OperationList' is the result of compiling the 
| 'FormulaList' into a list of operation records which
| can be evaluated by 'DoOperations'.
|
| The 'AttributeCode' is used to distinguish operators from
| enumerators and to tell if certain values have been
| assigned yet.
|
| If the record is of an Enumerator, the 'Value' field is 
| the numeric value found by executing the operation list.
|
| The name of a formula is found by searching the place
| name system for the place addressed by the formula
| record. The PlaceName record in turn holds
| the address of the FormulaRecord.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Formula records are allocated using 'AllocateMemory'
|          and freed using 'FreeMemory'.
|
| HISTORY: 12.28.93 
|          12.31.93 added CompilerExit
|          01.16.94 added OutputFormat, changed size of
|                   ParameterCount
|          05.30.94 changed 'Number' to 'DecimalNumber'.
|          11.08.98 Added symbol table field.
------------------------------------------------------------*/
/* Formula type codes: */
#define Calculation        1
#define EnumeratorFormula  2
#define CalcOrEnumFormula  3
#define OperatorFormula    4
#define UnknownFormula     5

/* OutputFormat bytes is encoded like this:
 *
 *       [######fs]
 *        76543210
 *
 * where:  ###### is the number of fixed point decimal places
 *              f is 1 if fixed point format is selected.
 *              s is 1 if scientific format is selected.
 */
 
typedef struct FormulaRecord
{
    List*          FormulaList;
    List*          OperationList;
    DecimalNumber  Value;
    s32            EvalExit;
    u8             FormulaType;
    u8             ValueExists;
    u8             ParameterCount;
    u8             OutputFormat;
    NameAt*        SymbolTable;
                   // The table that associates words with 
                   // memory addresses.
} Formula;

/*------------------------------------------------------------
| ExpressionRecord
|-------------------------------------------------------------
|
| PURPOSE: To record the source location of a particular 
|          formula.
|
| DESCRIPTION: An expression is understood to mean a particular
| utterance of a formula; the same formula can be expressed
| in several locations.
|
| Each expression is defined by a record like this:
|
|      ExpressionRecord
|      ---------------
|      |    Formula  |
|      ---------------
|          4 bytes         
|
| where: Formula holds the address of the formula record
|                for the expression.
|
| If Formula == 0, then an attempt to redefine an existing
| formula occured.
|
| EXAMPLE:  
|
| NOTE: Not to be confused with an expression list, which is
|       a list of token records -- AKA 'FormulaList'.
|
| ASSUMES: Expression records are dynamically allocated.
|
| HISTORY: 12.31.93 
|          01.20.94 removed fields 'IndexInLine', 'SourceLine'
|
------------------------------------------------------------*/
typedef struct ExpressionRecord
{
    Formula*   Formula;
} Expression;


/*------------------------------------------------------------
| OperationRecord
|-------------------------------------------------------------
|
| PURPOSE: To define a particular operation.
|
| DESCRIPTION: Each operation is defined by an operation 
|              record like this:
|
|             Operation Record
|      -----------------------------
|      |   Procedure  |   Operand  |
|      -----------------------------
|          4 bytes      12 bytes
|
| where: Procedure is the address of an operation procedure
|
|        Operand contains data that is passed by reference
|                to the operation procedure.
|
|                The operand may be one of the following:
|
|                1. An twelve-byte 'DecimalNumber'
|                   if 'Procedure' is 'DoNumber'.
|
|                2. A symbol table address if 'Procedure'
|                   is 'DoName'.
|
|                3. Unused, if 'Procedure' is a math
|                   operation.
|
|                4. A parameter index byte.
|
|                5. An item address for DoBranch op.
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 'Number' data type is 10 bytes long.
|
| HISTORY: 11.28.93 
|          01.02.93 changed Operand to u8 type.
|          01.07.94 changed from 8-byte floats to 10-byte
|                   to fix compiler error.
|          05.30.94 changed Operand to 'DecimalNumber' type.
------------------------------------------------------------*/
typedef struct OperationRecord
{
    ExitCodeProcedure   Procedure;
    DecimalNumber       Operand;
} Operation;

/* -------------------------- DATA -------------------------- */

/* -------------------PROTOTYPES----------------------------- */

#ifdef __cplusplus
} // extern "C"
#endif

#endif
