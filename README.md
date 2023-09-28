# patropi

Yet another implementation for [rinha](https://github.com/aripiprazole/rinha-de-compiler/blob/main/SPECS.md).

![tests](https://github.com/leandronsp/patropi/actions/workflows/ruby.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

```
                /\ \__                       __    
 _____      __  \ \ ,_\  _ __   ___   _____ /\_\   
/\ '__`\  /'__`\ \ \ \/ /\`'__\/ __`\/\ '__`\/\ \  
\ \ \L\ \/\ \L\.\_\ \ \_\ \ \//\ \L\ \ \ \L\ \ \ \ 
 \ \ ,__/\ \__/.\_\\ \__\\ \_\\ \____/\ \ ,__/\ \_\
  \ \ \/  \/__/\/_/ \/__/ \/_/ \/___/  \ \ \/  \/_/
   \ \_\                                \ \_\      
    \/_/                                 \/_/      

```

As of 2023' September, Patropi is a [tree-walking interpreter](https://craftinginterpreters.com/a-tree-walk-interpreter.html) written entirely in Ruby 3.2 [+YJIT](https://shopify.engineering/ruby-yjit-is-production-ready).

## Somente para a rinha

Em caso se for necessário o build local:
```bash
$ docker build -t patropi .

$ docker run \
  -v ./examples/showcase.json:/var/rinha/source.rinha.json \
  --memory=2gb \
  --cpus=2 \
  patropi
```

Ou, caso prefira buscar a imagem do Docker Hub:
```bash
$ docker run \
  -v ./examples/showcase.json:/var/rinha/source.rinha.json \
  --memory=2gb \
  --cpus=2 \
  leandronsp/patropi

```

## Requirements

* [Docker](https://docs.docker.com/get-docker/)
* [Rinha crate](https://crates.io/crates/rinha) to generate the AST. Requires Rust installed.

## TL;DR

```bash
$ docker build -t patropi .
$ rinha examples/hello.rinha | docker run --rm -i patropi

Hello, world
```

There are a bunch of other examples in the `./examples` folder.

## Usage with Make (optional)

This project leverages on the use of Makefile to organize commands. 
However if you don't want to use Make, feel free to check out the commands located in the `./bin/` folder.

```bash
$ make help

Usage: make <target>
  help                       Prints available commands
  patropi.build              Build Patropi
  patropi.hello              Run hello world
  patropi.showcase           Run showcase examples
  patropi.test               Run tests
  patropi.bench              Run benchmarks
```

Optionally you can run directly with `bin/patropi`:

```bash
$ bin/patropi examples/showcase.rinha
```

## Architecture

As mentioned before, Patropi is currently a tree-walking interpreter written in Ruby, implemented for [rinha](https://github.com/aripiprazole/rinha-de-compiler/blob/main/SPECS.md).

The evaluation phase is made using the [Trampoline](https://en.wikipedia.org/wiki/Trampoline_(computing)) technique along with [Continuation-passing style](https://en.wikipedia.org/wiki/Continuation-passing_style)(CPS), which aims to avoid deep recursion thus mitigating risks of [stack buffer overflow](https://en.wikipedia.org/wiki/Stack_buffer_overflow).

![patropi architecture](https://github.com/leandronsp/patropi/blob/main/screenshots/patropi.png)

_Note: the implementation is very simple and naive, mainly used for learning more about compilers_.

## Examples

Fibonacci with no tail call
```bash
cat > temp.rinha <<EOF
let fib = fn (n) => {
  if (n < 2) {
    n
  } else {
    fib(n - 1) + fib(n - 2)
  }
};
print("fib: " + fib(10))
EOF

rinha temp.rinha | docker run --rm -i patropi
```

Fibonacci with tail call
```bash
cat > temp.rinha <<EOF
let fib = fn (n, a, b) => {
  if (n == 0) {
    a
  } else {
    fib(n - 1, b, a + b)
  }
};
print("fib: " + fib(10, 0, 1))
EOF

rinha temp.rinha | docker run --rm -i patropi
```

O QA pediu pra rodar
```bash
cat > temp.rinha <<EOF
let sum = fn (a, b) => { a + b };
let other_sum = fn (n) => { sum(n, 2) };
let tuple = (
	print(other_sum(10)), 
	(fn (a, b) => { a - b })(10, 2)
);
print(tuple)
EOF

rinha temp.rinha | docker run --rm -i patropi
```

## Parser (experimental)

Ideally, Patropi should be a complete intrepreter implementing a built-in parser for the rinha specification. 

At this moment, it comes with a simple lexer and parser that are still in experimental phase. Checkout the `./lib` for further details.

The parser is composed by the following components:

### Lexer

The lexer scans the input looking for regular expressions and produces grammar tokens. It is implemented using the `StringScanner` built-in Ruby class.

### Parser

The parser looks at the next token according to the grammar in a recursive top-down manner, which makes it a [recursive descent parser](https://en.wikipedia.org/wiki/Recursive_descent_parser). It is implemented in pure Ruby with no additional gems.

_All the unit tests in this project are already using the built-in Patropi parser. We're yet to implement the remaining language specs, such as Tuples and Location._

## Future development

* LALR parsing
* LLVM IR
* Advanced optimizations

----

[ASCII art generator](http://www.network-science.de/ascii/)
