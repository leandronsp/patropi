# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/lexer'

class LexerTest < Test::Unit::TestCase
  def test_print_hello
    lexer = Lexer.new('print("Hello")')

    assert_equal([
      [:PRINT, 'print'], 
      [:LPAREN, '('], 
      [:STRING, 'Hello'], 
      [:RPAREN, ')']
    ], lexer.tokenize)
  end

  def test_print_integer
    lexer = Lexer.new('print(42)')

    assert_equal([
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:NUMBER, '42'],
      [:RPAREN, ')']
    ], lexer.tokenize)
  end

  def test_print_sum
    lexer = Lexer.new('print(40 + 2)')

    assert_equal([
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:NUMBER, '40'],
      [:BINARY_OP, '+'],
      [:NUMBER, '2'],
      [:RPAREN, ')']
    ], lexer.tokenize)
  end

  def test_print_mixed_types
    lexer = Lexer.new('print("40 + 2 = " + 40 + 2)')

    assert_equal([
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:STRING, '40 + 2 = '],
      [:BINARY_OP, '+'],
      [:NUMBER, '40'],
      [:BINARY_OP, '+'],
      [:NUMBER, '2'],
      [:RPAREN, ')']
    ], lexer.tokenize)
  end

  def test_print_sum_of_two_variables 
    program = <<~PROGRAM
      let a = 40;
      let b = 2;
      print(a + b)
    PROGRAM

    lexer = Lexer.new(program)

    assert_equal([
      [:LET, 'let'],
      [:IDENTIFIER, 'a'],
      [:ASSIGNMENT, '='],
      [:NUMBER, '40'],
      [:SEMICOLON, ';'],
      [:LET, 'let'],
      [:IDENTIFIER, 'b'],
      [:ASSIGNMENT, '='],
      [:NUMBER, '2'],
      [:SEMICOLON, ';'],
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'a'],
      [:BINARY_OP, '+'],
      [:IDENTIFIER, 'b'],
      [:RPAREN, ')']
    ], lexer.tokenize)
  end
end
