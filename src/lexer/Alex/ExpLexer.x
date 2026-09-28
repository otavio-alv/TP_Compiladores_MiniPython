-- Especificacao do Alex (regras do lex), ou seja, como reconhecer os tokens

{
module MiniPythonLexer where

import MiniPythonToken
import System.IO (hPutStrLn, stderr)
}

%wrapper "monadUserState"

--Estrtura do Lex 

$white = [\ \t\n\r]
$digit = [0-9]
@number = $digit+
-- numero com expoente
@number = $digit+
@frac = \. $digit+
@exponent = [eE] [\+\-]? $digit+

@float = $digit+ (@frac @exponent? | @exponent)

--Identificadores
$letter = [a-zA-Z_]
@ident = $letter [a-zA-Z0-9_]*

--Stings
@doubleString = \"([^\"\\]|\\.)*\"
@singleString = \'([^\'\\]|\\.)*\'

tokens :-

<0> [\ \t]+ { indentationToken }
<0> \n { newlineToken }
<0> "#" .* ;
<0> "+" {simpleToken TkPlus}
<0> "-" {simpleToken TkMinus}
<0> "//" {simpleToken TkDSlash}
<0> "**" {simpleToken TkDStar}
<0> "*" {simpleToken TkStar}
<0> "/" {simpleToken TkSlash}
<0> "%" {simpleToken TkPercent}
<0> "==" {simpleToken TkEqEq}
<0> "!=" {simpleToken TkNeq}
<0> "<=" {simpleToken TkLe}
<0> ">=" {simpleToken TkGe}
<0> "<"  {simpleToken TkLt}
<0> ">"  {simpleToken TkGt}
<0> "="  {simpleToken TkAssign}
<0> "//=" {simpleToken TkDSlashEq}
<0> "+="  {simpleToken TkPlusEq}
<0> "-="  {simpleToken TkMinusEq}
<0> "*="  {simpleToken TkStarEq}
<0> "/="  {simpleToken TkSlashEq}
<0> "%="  {simpleToken TkPercentEq} 
<0> "("  {simpleToken TkLParen}
<0> ")"  {simpleToken TkRParen}
<0> "["  {simpleToken TkLBracket}
<0> "]"  {simpleToken TkRBracket}
<0> ","  {simpleToken TkComma}
<0> ":"  {simpleToken TkColon}
<0> "."  {simpleToken TkDot}
<0> "->" {simpleToken TkArrow}

<0> @float {floatToken}
--numero com expoente
<0> $digit+ @exponent {floatToken}
<0> @number {intToken}
--Palavras reservadas
<0> "and"      {simpleToken TkAnd}
<0> "break"    {simpleToken TkBreak}
<0> "bool"     {simpleToken TkBoolKw}
<0> "class"    {simpleToken TkClass}
<0> "continue" {simpleToken TkContinue}
<0> "def"      {simpleToken TkDef}
<0> "elif"     {simpleToken TkElif}
<0> "else"     {simpleToken TkElse}
<0> "float"    {simpleToken TkFloatKw}
<0> "for"      {simpleToken TkFor}
<0> "if"       {simpleToken TkIf}
<0> "in"       {simpleToken TkIn}
<0> "int"      {simpleToken TkIntKw}
<0> "lambda"   {simpleToken TkLambda}
<0> "None"     {simpleToken TkNoneKw}
<0> "not"      {simpleToken TkNot}
<0> "or"       {simpleToken TkOr}
<0> "pass"     {simpleToken TkPass}
<0> "return"   {simpleToken TkReturn}
<0> "self"     {simpleToken TkSelf}
<0> "str"      {simpleToken TkStrKw}
<0> "while"    {simpleToken TkWhile}
--Booleanos
<0> "True"     {simpleToken (TkBoolLit True)}
<0> "False"    {simpleToken (TkBoolLit False)}
<0> @ident     {identToken}
--Strings
<0> @doubleString {stringToken}
<0> @singleString {stringToken}
--Caractere invalido 
<0> .          {invalidCharToken}

--Código em haskell
{
 pilha de indentacao
data AlexUserState = AlexUserState
    { indentStack   :: [Int]
    , lineHasToken  :: Bool
    , indentCount   :: Int     -- contador de indentacao
    , pendingTokens :: [Token] -- tokens pendentes (ex.: ao sair de 8 -> 0)
    , parenLevel    :: Int     -- nivel de aninhamento de ( ) e [ ]
    , lastNewline   :: Position -- posicao do ultimo TkNewline emitido (os TkDedent usam ela)
    }

alexInitUserState :: AlexUserState
alexInitUserState = AlexUserState
    { indentStack   = [0]
    , lineHasToken  = False
    , indentCount   = 0
    , pendingTokens = []
    , parenLevel    = 0
    , lastNewline   = Position 0 0
    }


--Compara a indentacao atual com a pilha. Devolve a nova pilha e os
--tokens TkIndent/TkDedent a emitir (ou erro de indentacao invalida)
--TkIndent usa a posicao do primeiro token da linha; cada TkDedent usa a
--posicao do ultimo TkNewline (fim da linha logica anterior)
indentTokens :: Position -> Position -> Int -> [Int] -> Either String ([Int], [Token])
indentTokens _ _ _ [] = Right ([0], [])
indentTokens pos@(Position l _) nlPos current stack@(top:_)
    | current > top = Right (current : stack, [Token pos TkIndent])
    | current < top =
        let newStack = dropWhile (> current) stack
        in case newStack of
            (t:_) | t == current ->
                Right ( newStack
                      , replicate (length stack - length newStack) (Token nlPos TkDedent)
                      )
            _ -> Left (errorAt (Position l 1)
                        ("invalid indentation level: " ++ show current
                         ++ " is not in the indentation stack"))
    | otherwise = Right (stack, [])

--verifica a indentacao e coloca os tokens extras na frente dele.
emit :: Position -> Lexeme -> Alex Token
emit pos lx = do
    state <- alexGetUserState
    if lineHasToken state
        then pure (Token pos lx)
        else case indentTokens pos (lastNewline state) (indentCount state) (indentStack state) of
            Left err -> alexError err
            Right (newStack, extra) -> do
                let tok = Token pos lx
                    (first, rest) = case extra of
                        []     -> (tok, [])
                        (t:ts) -> (t, ts ++ [tok])
                alexSetUserState state
                    { indentStack   = newStack
                    , lineHasToken  = True
                    , pendingTokens = rest
                    }
                pure first

--Retira tokens da Fila: se estiver vazia->Nothing; se tiver tokens retira o primeiro  retorna Just token
getPendingToken :: Alex (Maybe Token)
getPendingToken = do
    state <- alexGetUserState
    case pendingTokens state of
        [] -> pure Nothing
        (token:rest) -> do
            alexSetUserState state { pendingTokens = rest }
            pure (Just token)

--Proximo token: primeiro esvazia a fila de pendentes, depois pede ao Alex
nextToken :: Alex Token
nextToken = do
    pending <- getPendingToken
    case pending of
        Just t  -> pure t
        Nothing -> alexMonadScan

--Contar espaços e tabulações de cada linha
indentationToken :: AlexAction Token
indentationToken (_, _, _, str) len = do
    state <- alexGetUserState
    if lineHasToken state
        then nextToken
        else do
            let count n '\t' = ((n `div` 8) + 1) * 8
                count n _    = n + 1
                newCount = foldl count (indentCount state) (take len str)
            alexSetUserState state { indentCount = newCount }
            nextToken

--Função para lidar com quebra de linha
--Linha com token -> emite TkNewline; linha vazia/so comentario -> ignora
newlineToken :: AlexAction Token
newlineToken (st, _, _, _) _ = do
    state <- alexGetUserState
    if parenLevel state > 0
        then nextToken   -- dentro de ( ) ou [ ]: a linha logica continua
        else do
            let nl = position st
            alexSetUserState state
                { lineHasToken = False
                , indentCount  = 0
                , lastNewline  = if lineHasToken state then nl else lastNewline state
                }
            if lineHasToken state
                then pure $ Token nl TkNewline
                else nextToken


--Função que reconhece o token simples (operadores, palavras reservadas...)
simpleToken :: Lexeme -> AlexAction Token
simpleToken lx (st, _, _, _) _ = do
    tok <- emit (position st) lx
    trackParens lx
    pure tok

--Conta o aninhamento de ( ) e [ ]. Enquanto for > 0, newlineToken ignora
--as quebras de linha e a indentacao das linhas de continuacao nao conta.
--(fica aqui dentro para nao ser preciso mexer nas regras dos parenteses)
trackParens :: Lexeme -> Alex ()
trackParens lx
    | lx == TkLParen || lx == TkLBracket = bump 1
    | lx == TkRParen || lx == TkRBracket = bump (-1)
    | otherwise = pure ()
    where
        bump d = do
            state <- alexGetUserState
            alexSetUserState state { parenLevel = max 0 (parenLevel state + d) }

--Reconhece um numero inteiro
intToken :: AlexAction Token
intToken (st, _, _, str) len =
    emit (position st) (TkIntLit (read (take len str)))

--Floats/Doubles
floatToken :: AlexAction Token
floatToken (st, _, _, str) len =
    emit (position st) (TkFloatLit (read (take len str)))

--Função para reconhcer Identificadores, pega um texto reconhecido e transforma em um TkIdent
identToken :: AlexAction Token
identToken (st, _, _, str) len =
    emit (position st) (TkIdent (take len str))

--Função para pegar um texto ja conhecido e transforma em um TkString,se a string possuir aspas simples converte para aspas duplas
stringToken :: AlexAction Token
stringToken (st, _, _, str) len =
    emit (position st) (TkStrLit (readString (take len str)))

readString :: String -> String
readString ('\'':xs) = read ('"' : init xs ++ "\"")
readString xs = read xs

--Retorna a posicao de um lex
position :: AlexPosn -> Position --Posição no formato ALex: AlexPn offset line column
position (AlexPn _ line colum) = Position line colum --descarta o primeiro valor e pega so lin e col

--Mensagem de erro 
errorAt :: Position -> String -> String
errorAt (Position l c) msg = show l ++ ":" ++ show c ++ ": error: " ++ msg

--Exemplo: 1:5: error: invalid character: '@'
invalidCharToken :: AlexAction Token
invalidCharToken (st, _, _, str) _ =
    case str of
        (c:_) -> alexError (errorAt (position st) ("invalid character: '" ++ [c] ++ "'"))
        []    -> alexError (errorAt (position st) "invalid character")

--Os tokens ficam na fila; o estado e zerado para nao repetir nada.
alexEOF :: Alex Token
alexEOF = do
    (pn, _, _, _) <- alexGetInput
    state <- alexGetUserState
    let p = position pn
        nlPos = if lineHasToken state then p else lastNewline state
        newline = [Token p TkNewline | lineHasToken state]
        dedents = replicate (length (indentStack state) - 1) (Token nlPos TkDedent)
        eof = Token (Position 0 0) TkEOF   -- enunciado: TkEOF sempre em 0:0
        (first, rest) = case newline ++ dedents of
            []     -> (eof, [])
            (t:ts) -> (t, ts ++ [eof])
    alexSetUserState state
        { indentStack   = [0]
        , lineHasToken  = False
        , indentCount   = 0
        , pendingTokens = rest
        }
    pure first

-- Função principal do lexer(percorre todo o arquivo)
lexer :: String -> Either String [Token]
lexer s = runAlex s go
    where
        go = do
            output <- nextToken

            if tokenLexeme output == TkEOF then
                pure [output]
            else
                (output :) <$> go

-- linha:coluna Construtor [valor]
--Ex.: 1:5 TkIdent "fib" 
showToken :: Token -> String
showToken (Token (Position l c) lx) = show l ++ ":" ++ show c ++ " " ++ show lx

-- arquivo:linha:coluna: error: mensagem
lexerFile :: FilePath -> String -> Either String [Token]
lexerFile file src = either (\e -> Left (file ++ ":" ++ e)) Right (lexer src)

--Imprime um token por linha; erro vai para stderr
lexFile :: FilePath -> IO ()
lexFile path = do
    src <- readFile path
    case lexerFile path src of
        Left err -> hPutStrLn stderr err
        Right ts -> mapM_ (putStrLn . showToken) ts

}
