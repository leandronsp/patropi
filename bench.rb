#RubyVM::InstructionSequence.compile_option = { tailcall_optimization: true }
# frozen_string_literal: true

require 'json'

require_relative 'lib/lexer'
require_relative 'lib/parser'
require_relative 'lib/interpreter'

def patropi(program)
  lexer = Lexer.new(program)
  parser = Parser.new(lexer)
  parser.parse!
  Interpreter.run({ expression: parser.ast }.to_json)
end

rinha = -> (number) { 
  <<~PROGRAM
    let fib = fn (n, a, b) => {
      if (n == 0) {
        a
      } else {
        fib(n - 1, b, a + b)
      }
    };
    let _ = fib(#{number}, 0, 1);
    print("fib(#{number}) done.")
  PROGRAM
}

def fib(n, a, b)
  return a if n == 0

  fib(n - 1, b, a + b)
end

def fib_lambda(n, a, b)
  return a if n == 0

  -> { fib_lambda(n - 1, b, a + b) }
end

def fib_trampoline(n)
  result = fib_lambda(n, 0, 1)

  while result.is_a?(Proc)
    result = result.call
  end

  result
end

require 'benchmark'

number = 100_000

Benchmark.bm do |x|
  x.report('patropi') { patropi(rinha.call(number)) }
  #x.report('ruby_tco') { fib(number, 0, 1) }
  x.report('ruby_trampoline') { fib_trampoline(number) }
end
