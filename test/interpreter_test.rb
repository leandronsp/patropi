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
end
