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
    | TkEOF
    deriving(Show, Eq)

--Verifica se o token é um lex válido
tokenLexeme :: Token -> Lexeme
tokenLexeme (Token _ lx) =  lx


