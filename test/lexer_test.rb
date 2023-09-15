# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/lexer'

class LexerTest < Test::Unit::TestCase
  def test_print
    lexer = Lexer.new('print("Hello")')

    assert_equal([
      [:PRINT, 'print'], 
      [:LPAREN, '('], 
      [:STRING, 'Hello'], 
      [:RPAREN, ')']
    ], lexer.tokenize)
  end
end
