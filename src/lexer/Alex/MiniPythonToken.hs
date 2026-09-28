--Lista de tokens do Alex(quais tokens existem)

module MiniPythonToken where 

--Guardando a posição de cada token 
data Position = Position 

    {line :: Int
    , colum :: Int
    }

    deriving(Show, Eq)

--Criando o token + posição + caractere lido
data Token 
    = Token Position Lexeme
    deriving(Show, Eq)

--caracters que vão sendo lidos(tipos básicos que o lexe produz)
data Lexeme
    = TkPlus
    | TkMinus
    | TkStar
    | TkSlash
    | TkPercent
    | TkEOF
    | TkDSlash
    | TkDStar
    | TkEqEq
    | TkNeq
    | TkLt
    | TkLe
    | TkGt
    | TkGe
    | TkAssign
    | TkPlusEq
    | TkMinusEq
    | TkStarEq
    | TkSlashEq
    | TkDSlashEq
    | TkPercentEq
    | TkLParen
    | TkRParen
    | TkLBracket
    | TkRBracket
    | TkComma
    | TkColon
    | TkDot
    | TkArrow
    --reconhecendo números inteiros
    | TkIntLit Int
    --Numero floats
    | TkFloatLit Double
    --Recinhecendo identidicadores
    | TkIdent String
    | TkAnd
    | TkBreak
    | TkBoolKw
    | TkClass
    | TkContinue
    | TkDef
    | TkElif
    | TkElse
    | TkFloatKw
    | TkFor
    | TkIf
    | TkIn
    | TkIntKw
    | TkLambda
    | TkNoneKw
    | TkNot
    | TkOr
    | TkPass
    | TkReturn
    | TkSelf
    | TkStrKw
    | TkWhile
    --reconhendo booleanos
    | TkBoolLit Bool
    --reconhecendo strings
    | TkStrLit String
    --Tratamento de espaços e tabulaçoes
    | TkNewline
    | TkIndent
    | TkDedent
    deriving (Show, Eq)


--Verifica se o token é um lex válido
tokenLexeme :: Token -> Lexeme
tokenLexeme (Token _ lx) =  lx
