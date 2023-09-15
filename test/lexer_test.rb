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
end
