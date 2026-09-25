# Especificação da Linguagem MiniPython

**Disciplina:** BCC328 — Construção de Compiladores I

**Professor:** Rodrigo Ribeiro

---

## 1. Introdução

MiniPython é um subconjunto de Python 3 com **tipagem estática forte** projetado
para fins didáticos em disciplinas de compiladores. A linguagem mantém a sintaxe
familiar de Python: indentação como delimitador de blocos, anotações de tipo ao
estilo PEP 526/PEP 484 e literais Python. Porém, MiniPython substitui o modelo
de tipagem dinâmica de Python por um sistema de tipos **verificado em tempo de
compilação**, sem `Any`, sem coerção implícita e sem reflexão.

O objetivo é que o aluno implemente um compilador completo: analisador léxico,
três analisadores sintáticos, verificador de tipos, interpretador e gerador de
código para uma linguagem real o suficiente para exercitar todos esses
conceitos, porém simples o suficiente para caber em um semestre.

A descrição da linguagem é feita por meio de exemplos e de uma gramática formal.
A implementação das fases léxica, sintática e semântica é parte dos trabalhos a
serem desenvolvidos ao longo do semestre.

### O que MiniPython inclui

- Tipos primitivos: `int`, `float`, `bool`, `str`, `None`
- Listas homogêneas: `list[T]`
- Tipos de função: `(T1, ..., Tn) -> R`
- Funções de primeira ordem com anotações obrigatórias de parâmetros e retorno
- Variáveis locais com anotação de tipo opcional (inferência simples)
- Comandos `if/elif/else`, `while`, `for` (sobre `range` e sobre listas)
- `break`, `continue`, `pass`, `return`
- Atribuição simples, aumentada (`+=`, `-=`, `*=`, `/=`, `//=`, `%=`)
- Atribuição indexada: `xs[i] = e`
- Funções embutidas: `print`, `input`, `int`, `float`, `str`, `bool`, `len`,
  `range`, `append`
- Literais de lista: `[e1, e2, ...]`
- Classes com campos tipados, métodos e herança simples

### O que MiniPython **não** inclui

Exceções, geradores, dicionários, conjuntos, tuplas, módulos, decoradores,
compreensões, `*args`/`**kwargs`, `global`/`nonlocal`, `try`/`except`,
`with`, `assert`, herança múltipla, `isinstance`, `@classmethod`,
`@staticmethod`, `super()`.

---

## 2. Estrutura de um Programa

Um programa MiniPython é uma sequência de **definições de função**, **definições
de classe** e **instruções de nível superior** (também chamadas de _top-level_),
escritas num arquivo com extensão `.mpy`. A execução inicia na primeira
instrução de nível superior encontrada; funções e classes só são processadas
quando explicitamente invocadas.

```python
# exemplo.mpy

def fatorial(n: int) -> int:
    if n <= 1:
        return 1
    return n * fatorial(n - 1)

x: int = int(input())
print(fatorial(x))
```

Definições de função e classe devem aparecer antes de qualquer uso; instruções
de nível superior são executadas na ordem em que aparecem.

---

## 3. Tipos

### 3.1 Tipos primitivos

| Tipo    | Descrição                                        | Exemplos de literais          |
| ------- | ------------------------------------------------ | ----------------------------- |
| `int`   | Inteiro de precisão arbitrária                   | `0`, `42`, `-7`, `1_000_000`  |
| `float` | Ponto flutuante de dupla precisão                | `3.14`, `-0.5`, `1e10`, `2.0` |
| `bool`  | Booleano                                         | `True`, `False`               |
| `str`   | Cadeia de caracteres                             | `"olá"`, `'mundo'`, `""`      |
| `None`  | Tipo unitário; retorno de funções sem valor útil | `None`                        |

### 3.2 Listas

`list[T]` representa uma lista **mutável e homogênea** cujos elementos são todos
do tipo `T`. O tipo `T` pode ser qualquer tipo primitivo ou outra lista.

```python
notas: list[float] = [9.5, 8.0, 7.5]
matriz: list[list[int]] = [[1, 2], [3, 4]]
```

Operações sobre listas:

| Operação        | Tipo resultante | Descrição                                    |
| --------------- | --------------- | -------------------------------------------- |
| `xs[i]`         | `T`             | Acesso por índice (`i : int`)                |
| `xs[i] = e`     | — (comando)     | Atribuição por índice                        |
| `len(xs)`       | `int`           | Comprimento                                  |
| `append(xs, e)` | `None`          | Acrescenta `e` ao final de `xs`              |
| `[e1, ..., en]` | `list[T]`       | Literal de lista (todos os `ei` de tipo `T`) |

### 3.3 Tipos de função

Funções são cidadãs de primeira ordem e possuem tipo `(T1, ..., Tn) -> R`. Uma
função que não retorna valor útil tem tipo de retorno `None`. Expressões lambda
também possuem tipos de função e são inferidas automaticamente.

```python
def aplicar(f: (int) -> int, x: int) -> int:
    return f(x)
```

### 3.4 Tipos de classe (objetos)

Cada classe declarada `C` introduz um novo tipo `C`. Variáveis, campos e
parâmetros podem ser anotados com um tipo de classe:

```python
class Ponto:
    x: int
    y: int
    def __init__(self, x: int, y: int) -> None:
        self.x = x
        self.y = y

p: Ponto = Ponto(3, 4)
```

**Subtipagem:** se `class Filho(Pai):` é declarado, então `Filho` é subtipo de
`Pai`. A relação de subtipagem é reflexiva e transitiva: um valor do tipo
`Filho` pode ser usado em qualquer contexto que espere `Pai`.

### 3.5 Variáveis de Tipo e Polimorfismo

MiniPython suporta **polimorfismo paramétrico** por meio de variáveis de tipo.
Uma variável de tipo é um identificador em minúscula como `a`, `b`, `t`, que
pode ser usada em anotações de tipo no lugar de um tipo concreto.

**Distinção entre identificadores de tipo:**

- Tipos primitivos: `int`, `float`, `bool`, `str`, `None`
- Tipos de classe: identificadores que começam com letra maiúscula (ex.:
  `Ponto`, `Animal`)
- Variáveis de tipo: identificadores em minúscula que não correspondem a nenhum
  tipo primitivo (ex.: `a`, `b`, `t`, `elem`)

Uma função cujas anotações contêm variáveis de tipo é automaticamente
**polimórfica**: pode ser aplicada a argumentos de tipos distintos, desde que a
aplicação seja consistente com as restrições impostas pelas variáveis de tipo.

**Anotações opcionais:** anotações de parâmetros, de tipo de retorno e de
variáveis locais são **opcionais**. Quando omitidas, o compilador infere o tipo
mais geral compatível com o uso. Uma variável cujo tipo não pode ser determinado
a partir do contexto é um erro de compilação.

```python
# Anotações explícitas com variável de tipo
def identidade(x: a) -> a:
    return x

# Anotações de parâmetro omitidas — tipos inferidos
def primeiro(xs):
    return xs[0]

# Uso: compilador infere a = int
n: int = identidade(42)
# Uso: compilador infere a = str
s: str = identidade("olá")
```

---

## 4. Estrutura Léxica

### 4.1 Arquivos fonte

MiniPython aceita UTF-8. Comentários iniciam com `#` e se estendem até o fim da
linha.

### 4.2 Palavras reservadas

```
and      break    bool     class    continue  def      elif     else
False    float    for      if       in        int      None
not      or       pass     return   self      str      True     while
```

### 4.3 Operadores e pontuação

| Token                          | Significado                        |
| ------------------------------ | ---------------------------------- |
| `+` `-` `*` `/`                | Aritmética                         |
| `//`                           | Divisão inteira                    |
| `%`                            | Módulo                             |
| `**`                           | Potência                           |
| `==` `!=`                      | Igualdade / desigualdade           |
| `<` `<=` `>` `>=`              | Comparação                         |
| `=`                            | Atribuição                         |
| `+=` `-=` `*=` `/=` `//=` `%=` | Atribuição aumentada               |
| `(` `)`                        | Parênteses                         |
| `[` `]`                        | Colchetes                          |
| `,`                            | Separador                          |
| `:`                            | Anotação de tipo / início de bloco |
| `->`                           | Tipo de retorno de função          |
| `.`                            | Acesso a campo ou método de objeto |

### 4.4 Identificadores e literais

- **Identificadores:** `[a-zA-Z_][a-zA-Z0-9_]*`, distintos de palavras
  reservadas.
- **Inteiros:** sequência de dígitos decimais (com `_` como separador opcional).
- **Floats:** dígitos com ponto decimal e/ou expoente `e`/`E`.
- **Strings:** delimitadas por `"..."` ou `'...'`, com sequências de escape
  `\\`, `\"`, `\'`, `\n`, `\t`, `\r`.

### 4.5 Indentação: tokens INDENT e DEDENT

MiniPython usa indentação para delimitar blocos, exatamente como Python. O
analisador léxico é responsável por converter variações de indentação em tokens
especiais `INDENT` e `DEDENT`, de modo que os analisadores sintáticos possam
tratar blocos como `INDENT stmt+ DEDENT` — análogo às chaves de linguagens
baseadas em C.

**Algoritmo do lexer:**

1. O lexer mantém uma pilha de inteiros (`pilha_indent`) inicializada com `[0]`.
2. Para cada **linha lógica** não-vazia e não-comentário: a. Calcula o nível de
   indentação `k` da linha (número de espaços iniciais; tabs são expandidos para
   o próximo múltiplo de 8). b. Se `k > topo(pilha_indent)`: emite `INDENT`,
   empilha `k`. c. Se `k < topo(pilha_indent)`: desempilha enquanto `topo > k`,
   emitindo `DEDENT` a cada desempilhamento. Erro léxico se `k` não corresponde
   a nenhum nível da pilha. d. Se `k == topo(pilha_indent)`: não emite nada
   (mesma linha lógica).
3. Ao final do arquivo, emite `DEDENT` para cada nível restante na pilha (exceto
   o `0` inicial) e depois `EOF`.
4. Linhas em branco, linhas só com comentários e linhas continuadas dentro de
   parênteses ou colchetes abertos **não** geram `INDENT`/`DEDENT`.

**Exemplo:**

```python
def f(x: int) -> int:   # coluna 0
    if x > 0:           # INDENT (nível 4)
        return x        # INDENT (nível 8)
    return -x           # DEDENT (volta ao nível 4)
                        # DEDENT (volta ao nível 0) ao encontrar def ou EOF
```

Fluxo de tokens resultante (simplificado):

```
KW_DEF IDENT LPAREN IDENT COLON KW_INT RPAREN ARROW KW_INT COLON
INDENT
  KW_IF IDENT GT INT COLON
  INDENT
    KW_RETURN IDENT
  DEDENT
  KW_RETURN MINUS IDENT
DEDENT
EOF
```

**Tokens NEWLINE:** cada linha lógica não-vazia termina com um token `NEWLINE`
antes de qualquer `INDENT`/`DEDENT` da próxima linha.

---

## 5. Expressões

### 6.1 Literais

```python
42          # inteiro
3.14        # float
True        # booleano
"olá"       # string
None        # valor unitário
```

### 6.2 Variáveis

O nome de uma variável previamente declarada é uma expressão do tipo da
variável.

### 6.3 Operações Aritméticas

Os operadores `+`, `-`, `*` aceitam dois operandos do mesmo tipo (`int` ou
`float`) e produzem resultado do mesmo tipo. O operador unário `-` nega um
inteiro ou float.

```python
z: int = (x + y) * 2 - 1
w: float = 1.5 * altura - 0.5
```

**Divisão:** o operador `/` aceita dois `int` (produzindo `float`) ou dois
`float` (produzindo `float`). Os operadores `//` (divisão inteira) e `%`
(módulo) só aceitam operandos do tipo `int` e produzem `int`.

```python
q: int   = 17 // 5    # 3
r: int   = 17 % 5     # 2
d: float = 17 / 5     # 3.4
```

**Potência:** `**` aceita `int ** int` (produzindo `int`) ou `float ** float`
(produzindo `float`).

**Precedência** (da maior para a menor): `-` unário > `**` > `*` `/` `//` `%`

> `+` `-`.

### 6.4 Operações Relacionais

Os operadores `==`, `!=`, `<`, `<=`, `>` e `>=` comparam dois valores do mesmo
tipo (`int`, `float` ou `str`) e produzem resultado do tipo `bool`.

```python
ok: bool = x > 0 and x < 100
igual: bool = s1 == s2
```

### 6.5 Operações Lógicas

Os operadores `and` (conjunção) e `or` (disjunção) aceitam operandos do tipo
`bool` e produzem resultado do tipo `bool`. Ambos têm **semântica de
curto-circuito**: o segundo operando só é avaliado se necessário. O operador
unário `not` nega um booleano.

```python
valido: bool = x > 0 and x < 100
nulo: bool = not valido
```

**Precedência** (da maior para a menor): `not` > `and` > `or`.

### 6.6 Acesso a Elementos de Lista

O elemento de índice `i` de uma lista `xs` é obtido com `xs[i]`. O índice deve
ser do tipo `int`. O acesso fora dos limites da lista é um erro em tempo de
execução.

```python
v: int = arr[0]
```

### 6.7 Chamada de Função

Uma chamada de função tem a forma `f(e1, e2, ..., en)`, onde `f` é o nome de uma
função declarada e cada argumento `ei` deve ter o tipo correspondente ao
parâmetro formal.

```python
m: int = max_val(a, b)
```

Funções são cidadãs de primeira ordem: podem ser passadas como argumentos e
armazenadas em variáveis.

```python
def dobro(x: int) -> int:
    return x * 2

resultado: list[int] = map(dobro, xs)
```

Ao chamar uma função **polimórfica**, o compilador **instancia** as variáveis de
tipo com os tipos concretos determinados pelos argumentos fornecidos. A
instanciação é automática e sem sintaxe especial: o chamador não precisa
informar tipos explicitamente.

```python
def identidade(x: a) -> a:
    return x

n: int = identidade(42)      # a instanciada como int
s: str = identidade("olá")   # a instanciada como str
```

### 6.8 Literais de Lista

Uma lista com zero ou mais elementos é construída com colchetes:

```python
vazia: list[int]   = []
notas: list[float] = [9.5, 8.0, 7.5]
```

Todos os elementos devem ter o mesmo tipo `T`; o tipo do literal é `list[T]`.
Uma lista vazia `[]` só é aceita quando o tipo pode ser inferido da anotação da
variável.

### 6.9 Acesso a Campo e Chamada de Método

O campo `f` de um objeto `obj` do tipo de classe `C` é acessado com `obj.f`. O
tipo do resultado é o tipo declarado do campo `f` em `C`.

```python
px: int = p.x
```

Um método `m` é invocado com `obj.m(e1, ..., en)`. O tipo de retorno é o tipo
declarado do método em `C`. O despacho é **dinâmico**: em tempo de execução, a
implementação escolhida é a do tipo concreto do objeto.

```python
area: float = forma.area()
```

### 6.10 Expressão Condicional

A expressão `e1 if c else e2` avalia `c` (do tipo `bool`); se verdadeiro,
retorna o valor de `e1`; caso contrário, retorna o valor de `e2`. As
subexpressões `e1` e `e2` devem ter o mesmo tipo.

```python
abs_x: int = x if x >= 0 else -x
```

### 6.11 Função Anônima (lambda)

Uma expressão lambda cria uma função sem nome com um corpo de **expressão única**:

```python
lambda x: x * 2
lambda x, y: x + y
lambda: 42
```

Os parâmetros não possuem anotações de tipo; o tipo da lambda é inferido a partir
do uso. Uma lambda `lambda x1, x2, ..., xn: e` tem tipo `(T1, ..., Tn) -> R`
onde `Ti` é o tipo inferido de cada parâmetro e `R` é o tipo da expressão `e`.

Lambdas são **closures**: capturam as variáveis do escopo envolvente em modo
leitura — podem ler mas não atribuir a variáveis externas. Somente variáveis
locais e parâmetros do escopo imediatamente envolvente são capturados; variáveis
de escopos mais externos (exceto o escopo global) não são acessíveis.

```python
def multiplica_por(n: int) -> (int) -> int:
    return lambda x: x * n   # captura n

dobrar: (int) -> int   = multiplica_por(2)
triplicar: (int) -> int = multiplica_por(3)
print(str(dobrar(5)))       # 10
print(str(triplicar(5)))    # 15
```

Lambdas são expressões e podem ser usadas em qualquer posição que aceite um
valor de tipo função:

```python
xs: list[int] = [1, 2, 3, 4, 5]
pares: list[int]    = filter(lambda x: x % 2 == 0, xs)
quadrados: list[int] = map(lambda x: x * x, xs)
```

---

## 6. Declarações

### 6.1 Declaração de Variável

Dentro do corpo de uma função ou no nível superior, uma variável é introduzida
com uma das formas:

```python
nome: tipo = expressão   # com anotação de tipo explícita
nome = expressão         # sem anotação; tipo inferido da expressão
```

Quando a anotação está presente, o tipo da expressão deve ser compatível com o
tipo declarado. Quando ausente, o compilador infere o tipo a partir da expressão
inicializadora. O escopo da variável começa após a declaração e se estende até o
fim do bloco corrente.

```python
n: int   = 10
ok: bool = n > 0
s        = "resultado"   # tipo str inferido
```

### 6.2 Definição de Função

Uma função é declarada com:

```python
def nome(param1: tipo1, param2: tipo2, ...) -> tipoRetorno:
    corpo
```

As anotações de tipo dos parâmetros e do retorno são **opcionais**. Quando
omitidas, o compilador infere o tipo mais geral compatível com o corpo. Uma
função definida no nível superior cujo tipo inferido contém variáveis de tipo
livres torna-se automaticamente polimórfica (ver §3.5).

O corpo é uma sequência de declarações e comandos terminada por um comando
`return`. Funções cujo tipo de retorno é `None` podem omitir o `return`.

```python
# Totalmente anotada
def soma(a: int, b: int) -> int:
    return a + b

# Retorno omitido — inferido como None
def imprime_soma(a: int, b: int) -> None:
    s: int = soma(a, b)
    print(str(s))

# Sem anotações — tipo inferido a partir do uso
def identidade(x):
    return x

# Com variável de tipo explícita — polimórfica
def aplica(f: (a) -> b, x: a) -> b:
    return f(x)
```

Funções são **recursivas** por padrão: o nome da função está em escopo dentro de
seu próprio corpo.

```python
def fat(n: int) -> int:
    if n <= 1:
        return 1
    return n * fat(n - 1)
```

Funções podem receber outras funções como parâmetros:

```python
def aplicar(f: (int) -> int, x: int) -> int:
    return f(x)
```

### 6.3 Definição de Classe

Uma classe é declarada com:

```python
class Nome:
    campo1: tipo1
    campo2: tipo2
    def __init__(self, ...) -> None:
        self.campo1 = ...
        self.campo2 = ...
    def metodo(self, ...) -> tipoRetorno:
        corpo
```

Os **campos** são declarados no corpo da classe antes dos métodos, com anotação
de tipo obrigatória. O método especial `__init__` é o construtor: é chamado
automaticamente ao criar um objeto com `Nome(args)` e deve atribuir todos os
campos declarados via `self.campo = expr`.

Herança simples é declarada com `class Filho(Pai):`. O filho herda todos os
campos e métodos do pai. Um método com o mesmo nome do pai o **sobrescreve**
(override); a assinatura deve ser idêntica.

```python
class Animal:
    nome: str
    def __init__(self, nome: str) -> None:
        self.nome = nome
    def falar(self) -> str:
        return "..."

class Cachorro(Animal):
    def falar(self) -> str:
        return "Au!"
```

Para reutilizar o construtor da superclasse, use a chamada qualificada
`Pai.__init__(self, args)`:

```python
class Retangulo(Forma):
    largura: float
    altura: float
    def __init__(self, largura: float, altura: float) -> None:
        self.largura = largura
        self.altura = altura
```

---

## 7. Comandos

### 7.1 Atribuição

Atribui o valor de uma expressão a uma variável previamente declarada:

```python
nome = expressão
```

O tipo da expressão deve ser compatível com o tipo da variável.

**Atribuição aumentada:** combina operação aritmética e atribuição. As formas
disponíveis são `+=`, `-=`, `*=`, `/=`, `//=` e `%=`. Os tipos dos operandos
devem satisfazer as mesmas restrições dos operadores correspondentes.

```python
i += 1
s += " mundo"
```

### 7.2 Atribuição Indexada e de Campo

A atribuição a um elemento de lista usa colchetes:

```python
arr[i] = expressão
```

O índice deve ser do tipo `int` e a expressão deve ter o tipo dos elementos da
lista.

A atribuição a um campo de objeto usa ponto:

```python
obj.campo = expressão
```

O tipo da expressão deve ser compatível com o tipo declarado do campo.

### 7.3 Condicional

```python
if expressão_bool:
    comandos_then
elif expressão_bool:
    comandos_elif
else:
    comandos_else
```

As cláusulas `elif` e `else` são opcionais e podem ser repetidas (no caso de
`elif`). Cada condição deve ser do tipo `bool`.

```python
def classifica(n: int) -> str:
    if n > 0:
        return "positivo"
    elif n < 0:
        return "negativo"
    else:
        return "zero"
```

### 7.4 Repetição — while

```python
while expressão_bool:
    comandos
```

O corpo é executado enquanto a condição for `True`. Dentro do corpo, `break`
encerra o laço imediatamente e `continue` avança para a próxima iteração.

```python
def fat_iter(n: int) -> int:
    res: int   = 1
    count: int = n
    while count > 1:
        res   = count * res
        count = count - 1
    return res
```

### 7.5 Iteração — for

O comando `for` itera sobre uma lista ou sobre uma sequência de inteiros gerada
por `range`:

```python
for variável in expressão_lista:
    comandos

for variável in range(n):
    comandos

for variável in range(início, fim):
    comandos

for variável in range(início, fim, passo):
    comandos
```

A variável de iteração assume o tipo dos elementos da lista, ou `int` quando
usada com `range`. Dentro do corpo, `break` e `continue` têm o mesmo efeito que
no `while`.

```python
def soma_lista(xs: list[int]) -> int:
    s: int = 0
    for x in xs:
        s = s + x
    return s
```

### 7.6 Retorno

```python
return expressão
```

Encerra a execução da função corrente e devolve o valor da expressão ao
chamador. O tipo da expressão deve corresponder ao tipo de retorno declarado. Em
funções `None`, o `return` pode ser omitido ou escrito sem expressão:

```python
return
```

### 7.7 Instrução pass

```python
pass
```

Não faz nada. Usada para preencher blocos que sintaticamente exigem ao menos uma
instrução mas que ainda não possuem conteúdo.

---

## 8. Funções Primitivas

| Função              | Tipo                            | Descrição                                        |
| ------------------- | ------------------------------- | ------------------------------------------------ |
| `print(x)`          | `(str) -> None`                 | Imprime `x` seguido de nova linha                |
| `input()`           | `() -> str`                     | Lê uma linha da entrada padrão                   |
| `int(x)`            | `(str ou float) -> int`         | Converte para inteiro                            |
| `float(x)`          | `(str ou int) -> float`         | Converte para ponto flutuante                    |
| `str(x)`            | `(int ou float ou bool) -> str` | Converte para string                             |
| `bool(x)`           | `(int) -> bool`                 | `0` resulta em `False`; qualquer outro em `True` |
| `len(xs)`           | `(list[T] ou str) -> int`       | Comprimento da lista ou string                   |
| `range(n)`          | `(int) -> list[int]`            | Gera `[0, 1, ..., n-1]`                          |
| `range(s, e)`       | `(int, int) -> list[int]`       | Gera `[s, s+1, ..., e-1]`                        |
| `range(s, e, step)` | `(int, int, int) -> list[int]`  | Gera sequência com passo `step`                  |
| `append(xs, e)`     | `(list[T], T) -> None`          | Acrescenta `e` ao final de `xs`                  |

A forma `xs.append(e)` é açúcar sintático para `append(xs, e)`.

---

## 9. Exemplos Completos

### 9.1 — Máximo Divisor Comum (iterativo)

```python
def mdc(a: int, b: int) -> int:
    while b != 0:
        t: int = b
        b = a % b
        a = t
    return a

def main() -> None:
    a: int = int(input())
    b: int = int(input())
    print(str(mdc(a, b)))

main()
```

### 9.2 — Fibonacci (recursivo)

```python
def fib(n: int) -> int:
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

def main() -> None:
    n: int = int(input())
    i: int = 0
    while i <= n:
        print(str(fib(i)))
        i = i + 1

main()
```

### 9.3 — Busca Linear

```python
def busca(arr: list[int], val: int) -> int:
    i: int = 0
    while i < len(arr):
        if arr[i] == val:
            return i
        i += 1
    return -1

def main() -> None:
    n: int = int(input())
    arr: list[int] = []
    i: int = 0
    while i < n:
        append(arr, int(input()))
        i += 1
    val: int = int(input())
    pos: int = busca(arr, val)
    if pos >= 0:
        print("Encontrado na posicao " + str(pos))
    else:
        print("Nao encontrado")

main()
```

### 9.4 — Ordenação por Seleção

```python
def min_idx(arr: list[int], inicio: int) -> int:
    m: int = inicio
    i: int = inicio + 1
    while i < len(arr):
        if arr[i] < arr[m]:
            m = i
        i += 1
    return m

def selection_sort(arr: list[int]) -> None:
    n: int = len(arr)
    i: int = 0
    while i < n:
        j: int = min_idx(arr, i)
        t: int = arr[i]
        arr[i] = arr[j]
        arr[j] = t
        i += 1

def main() -> None:
    n: int = int(input())
    arr: list[int] = []
    i: int = 0
    while i < n:
        append(arr, int(input()))
        i += 1
    selection_sort(arr)
    for x in arr:
        print(str(x))

main()
```

### 9.5 — Média e Desvio Padrão

```python
def soma(xs: list[float]) -> float:
    s: float = 0.0
    for x in xs:
        s = s + x
    return s

def media(xs: list[float]) -> float:
    return soma(xs) / float(len(xs))

def desvio(xs: list[float]) -> float:
    m: float = media(xs)
    s: float = 0.0
    for x in xs:
        d: float = x - m
        s = s + d * d
    return s / float(len(xs))

def main() -> None:
    n: int = int(input())
    xs: list[float] = []
    i: int = 0
    while i < n:
        append(xs, float(input()))
        i += 1
    print("media: " + str(media(xs)))
    print("variancia: " + str(desvio(xs)))

main()
```

### 9.6 — Números Primos (Crivo Simplificado)

```python
def eh_primo(n: int) -> bool:
    if n < 2:
        return False
    i: int = 2
    while i * i <= n:
        if n % i == 0:
            return False
        i += 1
    return True

def main() -> None:
    limite: int = int(input())
    i: int = 2
    while i <= limite:
        if eh_primo(i):
            print(str(i))
        i += 1

main()
```

### 9.7 — Verificação de Palíndromo

```python
def palindromo(s: str) -> bool:
    n: int = len(s)
    i: int = 0
    ok: bool = True
    while i < n // 2:
        if s[i] != s[n - 1 - i]:
            ok = False
        i += 1
    return ok

def main() -> None:
    s: str = input()
    if palindromo(s):
        print("palindromo")
    else:
        print("nao e palindromo")

main()
```

### 9.8 — Funções de Alta Ordem

```python
def dobro(x: int) -> int:
    return x * 2

def positivo(x: int) -> bool:
    return x > 0

def map(f: (int) -> int, xs: list[int]) -> list[int]:
    resultado: list[int] = []
    for x in xs:
        append(resultado, f(x))
    return resultado

def filter(p: (int) -> bool, xs: list[int]) -> list[int]:
    resultado: list[int] = []
    for x in xs:
        if p(x):
            append(resultado, x)
    return resultado

def main() -> None:
    xs: list[int] = [-3, -1, 0, 2, 4, 7]
    dobrados: list[int] = map(dobro, xs)
    positivos: list[int] = filter(positivo, dobrados)
    for x in positivos:
        print(str(x))

main()
```

### 9.9 — Busca Binária

```python
def busca_binaria(arr: list[int], val: int) -> int:
    esq: int = 0
    dir: int = len(arr) - 1
    while esq <= dir:
        meio: int = (esq + dir) // 2
        if arr[meio] == val:
            return meio
        elif arr[meio] < val:
            esq = meio + 1
        else:
            dir = meio - 1
    return -1

def main() -> None:
    n: int = int(input())
    arr: list[int] = []
    i: int = 0
    while i < n:
        append(arr, int(input()))
        i += 1
    val: int = int(input())
    print(str(busca_binaria(arr, val)))

main()
```

### 9.10 — Calculadora de IMC

```python
def classifica(imc: float) -> str:
    if imc < 18.5:
        return "Abaixo do peso"
    elif imc < 25.0:
        return "Peso normal"
    elif imc < 30.0:
        return "Sobrepeso"
    else:
        return "Obesidade"

def main() -> None:
    peso: float = float(input())
    altura: float = float(input())
    imc: float = peso / (altura * altura)
    print("IMC: " + str(imc))
    print(classifica(imc))

main()
```

### 9.11 — Formas Geométricas (herança)

```python
class Forma:
    def area(self) -> float:
        return 0.0
    def perimetro(self) -> float:
        return 0.0
    def descricao(self) -> str:
        return "area=" + str(self.area()) + " perimetro=" + str(self.perimetro())

class Retangulo(Forma):
    largura: float
    altura: float
    def __init__(self, largura: float, altura: float) -> None:
        self.largura = largura
        self.altura = altura
    def area(self) -> float:
        return self.largura * self.altura
    def perimetro(self) -> float:
        return 2.0 * (self.largura + self.altura)

class Quadrado(Retangulo):
    def __init__(self, lado: float) -> None:
        Retangulo.__init__(self, lado, lado)

def imprimir(f: Forma) -> None:
    print(f.descricao())

def main() -> None:
    r: Retangulo = Retangulo(3.0, 4.0)
    q: Quadrado = Quadrado(5.0)
    imprimir(r)
    imprimir(q)

main()
```

### 9.12 — Pilha (classe sem herança)

```python
class Pilha:
    dados: list[int]
    topo: int
    def __init__(self) -> None:
        self.dados = []
        self.topo = 0
    def push(self, x: int) -> None:
        append(self.dados, x)
        self.topo = self.topo + 1
    def pop(self) -> int:
        self.topo = self.topo - 1
        return self.dados[self.topo]
    def vazia(self) -> bool:
        return self.topo == 0

def main() -> None:
    p: Pilha = Pilha()
    p.push(10)
    p.push(20)
    p.push(30)
    while not p.vazia():
        print(str(p.pop()))

main()
```

### 9.13 — Funções Polimórficas com Inferência

```python
def identidade(x: a) -> a:
    return x

def aplica(f: (a) -> b, x: a) -> b:
    return f(x)

def compose(f: (b) -> c, g: (a) -> b, x: a) -> c:
    return f(g(x))

def dobro(n: int) -> int:
    return n * 2

def para_str(n: int) -> str:
    return str(n)

n: int = identidade(42)
s: str = identidade("olá")
resultado: str = aplica(para_str, aplica(dobro, 5))
print(resultado)

dobrado: int = compose(dobro, dobro, 3)
print(str(dobrado))
```

### 9.14 — Funções de Ordem Superior Polimórficas

```python
def map(f: (a) -> b, xs: list[a]) -> list[b]:
    resultado: list[b] = []
    for x in xs:
        append(resultado, f(x))
    return resultado

def filter(p: (a) -> bool, xs: list[a]) -> list[a]:
    resultado: list[a] = []
    for x in xs:
        if p(x):
            append(resultado, x)
    return resultado

def fold(f: (b, a) -> b, acc: b, xs: list[a]) -> b:
    for x in xs:
        acc = f(acc, x)
    return acc

def eh_par(n: int) -> bool:
    return n % 2 == 0

def quadrado(n: int) -> int:
    return n * n

def somar(acc: int, x: int) -> int:
    return acc + x

nums: list[int] = [1, 2, 3, 4, 5]
pares: list[int] = filter(eh_par, nums)
quadrados: list[int] = map(quadrado, nums)
soma: int = fold(somar, 0, nums)
print(str(soma))

vals: list[float] = [1.5, 2.5, 3.0]

def dobro_float(x: float) -> float:
    return x * 2.0

def para_str_float(x: float) -> str:
    return str(x)

strs: list[str] = map(para_str_float, map(dobro_float, vals))
for v in strs:
    print(v)
```

### 9.15 — Uso de Funções Anônimas

```python
def map(f: (a) -> b, xs: list[a]) -> list[b]:
    resultado: list[b] = []
    for x in xs:
        append(resultado, f(x))
    return resultado

def filter(p: (a) -> bool, xs: list[a]) -> list[a]:
    resultado: list[a] = []
    for x in xs:
        if p(x):
            append(resultado, x)
    return resultado

def fold(f: (b, a) -> b, acc: b, xs: list[a]) -> b:
    for x in xs:
        acc = f(acc, x)
    return acc

def compose(f: (b) -> c, g: (a) -> b) -> (a) -> c:
    return lambda x: f(g(x))

def multiplica_por(n: int) -> (int) -> int:
    return lambda x: x * n

nums: list[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

pares: list[int]     = filter(lambda x: x % 2 == 0, nums)
impares: list[int]   = filter(lambda x: x % 2 != 0, nums)
quadrados: list[int] = map(lambda x: x * x, nums)
soma: int            = fold(lambda acc, x: acc + x, 0, nums)
produto: int         = fold(lambda acc, x: acc * x, 1, nums)

print(str(soma))     # 55
print(str(produto))  # 3628800

dobrar: (int) -> int        = multiplica_por(2)
triplicar: (int) -> int     = multiplica_por(3)
dobra_e_quadra: (int) -> int = compose(lambda x: x * x, dobrar)

for x in pares:
    print(str(dobrar(x)))

print(str(dobra_e_quadra(3)))   # (3*2)^2 = 36

palavras: list[str] = ["banana", "abacaxi", "laranja", "uva", "kiwi"]
longas: list[str]   = filter(lambda s: len(s) > 4, palavras)
for p in longas:
    print(p)
```

---

## 10. Restrições e Regras Semânticas

1. **Tipagem forte:** não há coerção implícita entre tipos distintos. Em
   particular, `int` e `float` não são intercambiáveis: `1 + 1.0` é erro de
   tipo. A única exceção é a divisão `/` entre dois `int`, que produz `float`.
2. **Declaração antes do uso:** toda variável deve ser declarada antes de ser
   referenciada. Referenciar um nome não declarado é erro de compilação.
3. **Shadowing:** uma variável declarada em um bloco interno oculta a variável
   de mesmo nome do bloco externo, mas não altera o ambiente externo.
4. **Mutabilidade:** toda variável é mutável após sua declaração. Listas são
   mutadas em place por `xs[i] = e` e `append(xs, e)`.
5. **Índices de lista:** acessos fora do intervalo `[0, len-1]` são erros em
   tempo de execução; o verificador de tipos não verifica limites de índice.
6. **Recursão:** funções podem chamar a si mesmas diretamente. O verificador de
   tipos inclui a própria função no ambiente ao verificar seu corpo.
7. **Funções de primeira ordem:** funções podem ser passadas como argumentos e
   armazenadas em variáveis. Funções nomeadas (`def`) não formam closures: não
   capturam variáveis do escopo em que foram definidas. Expressões lambda são
   closures: capturam variáveis do escopo imediatamente envolvente em modo de
   leitura; atribuição a variáveis capturadas é erro de compilação.
8. **`break` e `continue`:** só são válidos dentro de um laço `while` ou `for`;
   seu uso fora de um laço é erro de compilação.
9. **`return` obrigatório:** toda função cujo tipo de retorno não é `None` deve
   ter um comando `return` em todos os caminhos de execução.
10. **Operadores restritos a `int`:** `//` e `%` só aceitam operandos do tipo
    `int`. O operador `/` aceita `int/int` (resultado `float`) ou `float/float`
    (resultado `float`), mas não combinações mistas.
11. **Sem sobrecarga:** não é permitido declarar dois identificadores com o
    mesmo nome no mesmo escopo.
12. **Herança simples:** cada classe pode ter no máximo uma superclasse. A
    relação de subtipagem é reflexiva e transitiva: se `D` herda de `C` e `C`
    herda de `B`, então `D <: B`.
13. **`__init__` e campos:** toda classe com campos declarados deve possuir um
    método `__init__` que atribua todos os campos via `self.campo = expr`. Usar
    um campo antes de atribuí-lo em `__init__` é erro de compilação.
14. **`self`:** é uma palavra reservada exclusiva de métodos; não pode ser
    reatribuída nem usada fora do corpo de um método de instância.
15. **Override:** um método em `Filho` que possui o mesmo nome de um método em
    `Pai` o sobrescreve. A assinatura (tipos dos parâmetros e tipo de retorno)
    deve ser idêntica à do método sobrescrito.
16. **Subtipagem em atribuição e argumentos:** um valor do tipo `D` pode ser
    atribuído a uma variável do tipo `C`, ou passado como argumento onde `C` é
    esperado, desde que `D <: C`.
17. **Despacho dinâmico:** chamadas de método são resolvidas em tempo de
    execução pelo tipo concreto do objeto. O verificador de tipos usa o tipo
    estático para verificar existência do método e compatibilidade dos
    argumentos.
18. **Inferência de tipos:** quando uma anotação de tipo é omitida, o compilador
    infere o tipo mais geral compatível com o uso da variável ou função. Uma
    variável ou parâmetro cujo tipo não pode ser determinado a partir do
    contexto é um erro de compilação.
19. **Let-polimorfismo:** definições de função de nível superior são
    generalizadas após a inferência: variáveis de tipo livres no tipo inferido
    tornam-se parâmetros de tipo quantificados universalmente. Funções locais
    (definidas dentro do corpo de outra função) não são generalizadas.
20. **Instanciação:** ao chamar uma função polimórfica, cada variável de tipo
    quantificada é instanciada com um tipo concreto, determinado pelos tipos dos
    argumentos fornecidos na chamada. Chamadas distintas podem instanciar as
    mesmas variáveis de tipo com tipos diferentes.
21. **Occurs check:** a unificação de tipos rejeita substituições circulares
    (por exemplo, tentar unificar `a` com `list[a]`). Tal situação é um erro de
    compilação.
22. **Consistência de anotações:** quando uma anotação de tipo está presente,
    ela é unificada com o tipo inferido para aquela posição. Se a unificação
    falhar, o compilador reporta erro de tipo com a posição (linha e coluna) da
    anotação conflitante.
23. **Lambdas e expressões:** o corpo de uma lambda deve ser uma única expressão;
    comandos (`if`, `while`, `for`, `return`, etc.) não são permitidos dentro de
    lambdas. O tipo da lambda é sempre inferido; anotações de parâmetro não são
    permitidas na sintaxe lambda.
