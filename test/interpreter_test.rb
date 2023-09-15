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

    ast = parser.parse

    assert_printed_to_stdout("Hello\n") do 
      Interpreter.run({ expression: ast }.to_json)
    end
  end
end
