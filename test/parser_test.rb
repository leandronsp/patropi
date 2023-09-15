# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/lexer'
require_relative '../lib/parser'

class ParserTest < Test::Unit::TestCase
  def test_print
    lexer = Lexer.new('print("Hello")')
    parser = Parser.new(lexer)

    ast = parser.parse

    assert_equal({ kind: 'Print', value: { kind: 'Str', value: 'Hello' } }, ast)
  end
end
