--Especificacao do Alex(regras do lex), ou seja, como reconhecer os tokens existentes no MiniPythonToken.hs

--Definindo o modulo(inicial)
{
module MiniPythonLexer where
import MiniPythonToken
}

%wrapper "monad"


--Estrtura do Lex 
tokens :-

<0> "+" {simpleToken TkPlus}


--Código em haskell

{
--Função que percorre o arquivo e gera a lista de Token


--Função que reconhece o token
simpleToken :: Lexeme-> AlexAction Token
simpleToken lx(st, _, _,_) _ = return $ Token(position st) lx

position :: AlexPosn -> Position --Posição no formato ALex: AlexPn offset line column
position (AlexPn _ line colum) = Position line colum --descarta o primeiro valor e pega so lin e col

--Ao chegar no final do arquivo 
alexEOF :: Alex Token
alexEOF = pure $ Token (Position 0 0) TkEOF


-- Função principal do lexer(percorre todo o arquivo)
lexer :: String -> Either String [Token]
lexer s = runAlex s go
    where
        go = do
            output <- alexMonadScan

            if tokenLexeme output == TkEOF then
                pure [output]
            else
                (output :) <$> go


}

