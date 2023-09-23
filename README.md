# patropi

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

Yet another Ruby interpreter for [Rinha de Compiladores](https://github.com/aripiprazole/rinha-de-compiler)

## Requirements

* [Docker](https://docs.docker.com/get-docker/)
* [rinha](https://crates.io/crates/rinha)
* Make (optional)

## Stack

* Ruby 3.2 [+YJIT](https://shopify.engineering/ruby-yjit-is-production-ready)

## Usage

```bash
$ make help

Usage: make <target>
  help                       Prints available commands
  patropi.build              Build Patropi
  patropi.hello              Run hello world
  patropi.test               Run tests
  patropi.bench              Run benchmarks
```

## Generating the AST's

This projects uses the [rinha crate](https://crates.io/crates/rinha) created by @aripiprazole and Algebraic Sofia. In order to use it, make sure you have Rust installed, then:

```bash
$ cargo init
$ cargo install rinha
```

Now, generating AST is as simples as `rinha source.fib`. There are a bunch of generated AST's in the `examples` folder.

## Experimental

Patropi comes with a simple lexer and parser that tries to implement the rinha language specification. In order to run the unit tests:

```bash
$ make rinha.test
```

_The lexer and parser are still in experimental phase._

----

[ASCII art generator](http://www.network-science.de/ascii/)
