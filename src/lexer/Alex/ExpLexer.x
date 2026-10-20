-- Especificacao do Alex (regras do lex), ou seja, como reconhecer os tokens
{
module MiniPythonLexer where --nome do modulo

import MiniPythonToken --importar os tokens que o Lexer vai reconhcer
import System.IO (hPutStrLn, stderr)
}

%wrapper "monadUserState"

--Estrtura do Lex 

$white = [\ \t\n\r]
$digit = [0-9]
@number = $digit+
-- numero com expoente
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
-- pilha de indentacao
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


-- Posição do primeiro token da linha atual-> Posição do token atual que encerrou a linha anterior-> 
-- Nivel de Indent->Pilha de niveis de identaçao anterior->(pilha atualizada, lista de tokens gerados)
indentTokens :: Position -> Position -> Int -> [Int] -> Either String ([Int], [Token])
--Caso base se for chamada com uma lista vazia
indentTokens _ _ _ [] = Right ([0], [])
indentTokens pos@(Position l _) nlPos current stack@(top:_)
    --Se o nivel de indentacao atual estiver mais a direita(maior que o topo da pilha)
    | current > top = Right (current : stack, [Token pos TkIndent])
    --Desindetacao: nivel atual menor que o topo da pilha, remove os niveis da pilha ate encontra um nivel igual ao atual
    | current < top =
        --Remove os niveis da pilha ate encontrar um nivel igual ao atual, se nao retonar um erro
        let newStack = dropWhile (> current) stack
        --Apos a remocao verifica se o nivel atual ja existe na pilha, se sim, retorna a pilha atualizada, o numero de tokens dedent gerados e suas posiçoes
        in case newStack of
            (t:_) | t == current ->
                Right ( newStack
                      , replicate (length stack - length newStack) (Token nlPos TkDedent)
                      )
            _ -> Left (errorAt (Position l 1) -- Se nao encontrou um nivel igual ao atual, retorna erro de identacao
                        ("invalid indentation level: " ++ show current
                         ++ " is not in the indentation stack"))
    | otherwise = Right (stack, []) -- se o nivel atual for igual ao top da pilha, retorna pilha atual e uma lista vazia

--verifica a indentacao e coloca os tokens extras na frente dele.
--posicao->caractere analisado->token gerado
emit :: Position -> Lexeme -> Alex Token
emit pos lx = do
    state <- alexGetUserState --pega o estado atual do Alex
    if lineHasToken state --verifica se a linha ja tem um token, se sim, emite o token normalmente
        then pure (Token pos lx)
        --Se a linha nao tem token, verifica a identaçao e coloca os tokens extras na frente dele
        else case indentTokens pos (lastNewline state) (indentCount state) (indentStack state) of
            --Erro de indentacao
            Left err -> alexError err
            Right (newStack, extra) -> do --Sucesso, recebe a nova pilha de identacao e os tokens extras gerados(TkIndent e TkDedent)
                let tok = Token pos lx
                    (first, rest) = case extra of
                    --Caso nao haja indentaçao, ou seja, a linha atual igual a anterior, sem nenhum bloco aberto ou fechado, retorna o token atual e uma lista vazia
                        []     -> (tok, []) 
                        --Se possui tokens extras, retorna o primeiro token da lista e o restante no final para ser processado na proxima chamada
                        (t:ts) -> (t, ts ++ [tok])
                alexSetUserState state
                    { indentStack   = newStack
                    , lineHasToken  = True
                    , pendingTokens = rest --salva no alex o restante dos tokens
                    }
                pure first --retorna o primeiro elemento processado 

--Retira tokens da Fila: se estiver vazia->Nothing; se tiver tokens retira o primeiro  retorna Just token
getPendingToken :: Alex (Maybe Token)
getPendingToken = do
    state <- alexGetUserState
    case pendingTokens state of
        [] -> pure Nothing
        (token:rest) -> do
            alexSetUserState state { pendingTokens = rest }
            pure (Just token)

--Proximo token: primeiro esvazia a fila de pendentes, depois pede ao Alex(sempre retorna um token, mesmo que seja TkEOF)
nextToken :: Alex Token
nextToken = do
    pending <- getPendingToken --Verifica se existem tokens pendentes na fila, se sim, guarda em pending
    case pending of
        Just t  -> pure t --Se a fila nao tiver vazia e conter apenas um token, retorna o token
        Nothing -> alexMonadScan --pega o proximo token do alex, mesmo se estiver em outra linha, se for EOF retorna TkEOF

--Contar espaços e tabulações de cada linha
indentationToken :: AlexAction Token
indentationToken (_, _, _, str) len = do
    --guarda o estado atual do Alex 
    state <- alexGetUserState
    --Verifica se a linha ja possui um token, se sim, pula para o próximo token, sem mudar o contador de indentação
    if lineHasToken state
        then nextToken
        --Se a linha não possui tokens, conta os espaços e tabulações e atualiza o contador de indenta
        else do
            let count n '\t' = ((n `div` 8) + 1) * 8 --Se for tabulação, incrementa o contador para o próximo múltiplo de 8
            --Se for espaço comum, incrementa 1 no contador de indentação
                count n _    = n + 1 
                --Atualiza o contador com a contagem de espaçoes e tabulações recursivamente, enquanto str tiver caracteres
                newCount = foldl count (indentCount state) (take len str)
            --Apos contar tudo, atualiza o estado do Alex com o novo valor 
            alexSetUserState state { indentCount = newCount }
            nextToken --pula para  o proximo token, com o contador atualizado e come

--Função para lidar com quebra de linha
newlineToken :: AlexAction Token
newlineToken (st, _, _, _) _ = do
    state <- alexGetUserState
    --se o nro de parantes abertos for maior que 0 = expressão ainda nao terminou
    if parenLevel state > 0
        then nextToken   --avaça para o proximo token, ignorando a quebra de linha 
        --Se for 0, ou seja, expressão terminou
        else do
            let nl = position st --guarda a posição do token onde a quebra de linha foi encotrada
            --Atualiza o estado do Alex, para a proxima linha começar "limpa"
            alexSetUserState state
                { lineHasToken = False
                , indentCount  = 0
                --se a linha atual possuir um token, retorna a posição dele, caso contrario, retorna a posição do ultimo TkNewline emitido
                , lastNewline  = if lineHasToken state then nl else lastNewline state
                }
            --Apos atualizar o alex quando nao tem parenteses abertos, verifica se a linha atual tem tokens e emite um TkNewline, caso contrario pula para o proximo token e ignora a linha em branco
            if lineHasToken state
                then pure $ Token nl TkNewline
                else nextToken


--Função que reconhece o token simples (operadores, palavras reservadas...)
simpleToken :: Lexeme -> AlexAction Token
simpleToken lx (st, _, _, _) _ = do
    --guarda a posição do token e o tipo do token reconhecido
    tok <- emit (position st) lx
    --Se o token for um abre parenteses ou colchetes, atualiza o contador de aninhamento de parenteses, somando 1 (parenLevel)
    --Se for um fecha, atualiza o contador subtraindo 1(parenLevel)
    trackParens lx
    pure tok --retorna o token reconhecido 

--FUnção que atualiza o contador de aninhamento de parenteses e colchetes
trackParens :: Lexeme -> Alex ()
trackParens lx
    | lx == TkLParen || lx == TkLBracket = bump 1
    | lx == TkRParen || lx == TkRBracket = bump (-1)
    | otherwise = pure ()
    where
        bump d = do
            state <- alexGetUserState --armazena o estado do usuário do Alex
            --Armazena o novo estado do usuário do Alex, atualizando o contador de aninhamento
            --Max compara 0 com o valor atual e retorna o maior, garantindo que o contador não seja negativo
            alexSetUserState state { parenLevel = max 0 (parenLevel state + d) }

--Reconhece um numero inteiro
intToken :: AlexAction Token
--Pega a posição do token, a string restante do arquivo e o tamanho de quantos caracteres formam o número 
intToken (st, _, _, str) len =
    emit (position st) (TkIntLit (read (take len str))) --recorta a string do arquivo e pega somente o que forma numeros e transforma em um número real e e ite a posição e o tipo do token

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

--Função que oonverte uma string com aspas simples para aspas duplas
readString :: String -> String
--Separa a primeira aspas simples do restante da string(':..'), init remove o ultimmo caracte da string (') e concatena com as aspas duplas 
readString ('\'':xs) = read ('"' : init xs ++ "\"")
--Se a string ja começa com aspas duplas, apenas lê a string
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

--Função chamada quando chega no final do arquivo,
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
