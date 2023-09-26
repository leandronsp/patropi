# frozen_string_literal: true

require 'test/unit'
require 'json'
require 'stringio'
require_relative '../lib/lexer'
require_relative '../lib/parser'
require_relative '../lib/interpreter'

def assert_printed_to_stdout(message)
  stdout = StringIO.new
  original_stdout = $stdout
  $stdout = stdout

  yield

  $stdout = original_stdout
  assert_equal(message, stdout.string)
end

class InterpreterTest < Test::Unit::TestCase
  def test_print_hello
    lexer = Lexer.new('print("Hello")')
    parser = Parser.new(lexer)

    parser.parse!

    assert_printed_to_stdout("Hello\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_nested
    lexer = Lexer.new('print(print("Hello"))')
    parser = Parser.new(lexer)

    parser.parse!

    assert_printed_to_stdout("Hello\nHello\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_integer
    lexer = Lexer.new('print(42)')
    parser = Parser.new(lexer)

    parser.parse!

    assert_printed_to_stdout("42\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_sum
    lexer = Lexer.new('print(40 + 2)')

    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("42\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_sub
    lexer = Lexer.new('print(42 - 2)')

    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("40\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_eq
    lexer = Lexer.new('print(42 == 2)')

    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("false\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_sum_mixed_types
    lexer = Lexer.new('print("40 + 2 = " + 40 + 2)')

    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("40 + 2 = 42\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_sub_mixed_types
    lexer = Lexer.new('print("42 - 2 = " + 42 - 2)')

    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("42 - 2 = 40\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_sum_of_two_variables
    program = <<~PROGRAM
      let a = 40;
      let b = 2;
      print(a + b)
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("42\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_if
    program = <<~PROGRAM
      print(if (true) {
        "verdadeiro"
      } else {
        "falso"
      })
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("verdadeiro\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_function
    program = <<~PROGRAM
      let add = fn(a, b) => { 
        a + b
      };
      print(add(40, 2))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("42\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_recursive_sum 
    program = <<~PROGRAM
      let sum = fn(n, acc) => { 
        if (n == 0) {
          acc
        } else {
          sum(n - 1, acc + n)
        }
      };
      print(sum(10, 0))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("55\n") do 
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end
  
  def test_fibonacci_function
    program = <<~PROGRAM
      let fib = fn (n) => {
        if (n < 2) {
          n
        } else {
          fib(n - 1) + fib(n - 2)
        }
      };

      print("fib: " + fib(10))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("fib: 55\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_fibonacci_function_tc_10
    program = <<~PROGRAM
      let fib = fn (n, a, b) => {
        if (n == 0) {
          a
        } else {
          fib(n - 1, b, a + b)
        }
      };

      print("fib: " + fib(10, 0, 1))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("fib: 55\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_fibonacci_function_tc_1000
    program = <<~PROGRAM
      let fib = fn (n, a, b) => {
        if (n == 0) {
          a
        } else {
          fib(n - 1, b, a + b)
        }
      };

      print("fib: " + fib(1000, 0, 1))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("fib: 43466557686937456435688527675040625802564660517371780402481729089536555417949051890403879840079255169295922593080322634775209689623239873322471161642996440906533187938298969649928516003704476137795166849228875\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_combination
    program = <<~PROGRAM
      let combination = fn (n, k) => {
          let a = k == 0;
          let b = k == n;
          if (a || b)
          {
              1
          }
          else {
              combination(n - 1, k - 1) + combination(n - 1, k)
          }
      };

      print(combination(10, 2))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("45\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_print_closure
    program = <<~PROGRAM
      let add = fn(a, b) => { 
        a + b 
      };
      print(add)
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("<#closure>\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_tuple
    program = <<~PROGRAM
      let person = ("Leandro", 42);
      print("Tuple: " + person)
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("Tuple: (Leandro, 42)\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end

  def test_tuple_complex
    program = <<~PROGRAM
      let person = ("Leandro", 42);
      print(first(person))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_printed_to_stdout("Leandro\n") do
      Interpreter.run({ expression: parser.ast }.to_json)
    end
  end
end
