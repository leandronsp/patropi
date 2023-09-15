# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/lexer'
require_relative '../lib/parser'

class ParserTest < Test::Unit::TestCase
  def test_print_hello
    lexer = Lexer.new('print("Hello")')
    parser = Parser.new(lexer)

    parser.parse!

    assert_equal({ kind: 'Print', value: { kind: 'Str', value: 'Hello' } }, parser.ast)
  end

  def test_print_integer
    lexer = Lexer.new('print(42)')
    parser = Parser.new(lexer)

    parser.parse!

    assert_equal({ kind: 'Print', value: { kind: 'Int', value: 42 } }, parser.ast)
  end

  def test_print_sum
    lexer = Lexer.new('print(40 + 2)')

    parser = Parser.new(lexer)
    parser.parse!

    assert_equal({ 
      kind: 'Print', value: { 
        kind: 'BinaryOp', 
        op: 'Add',
        lhs: { kind: 'Int', value: 40 }, 
        rhs: { kind: 'Int', value: 2 } 
      } 
    }, parser.ast)
  end

  def test_print_mixed_types
    lexer = Lexer.new('print("40 + 2 = " + 40 + 2)')

    parser = Parser.new(lexer)
    parser.parse!

    assert_equal({ 
      kind: 'Print', value: {
        kind: 'BinaryOp',
        op: 'Add',
        lhs: { 
          kind: 'Str', value: '40 + 2 = '
        },
        rhs: { 
          kind: 'BinaryOp',
          op: 'Add',
          lhs: { kind: 'Int', value: 40 },
          rhs: { kind: 'Int', value: 2 }
        }
      }
    }, parser.ast)
  end
end
