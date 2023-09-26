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
        kind: 'Binary', 
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
        kind: 'Binary',
        op: 'Add',
        lhs: { 
          kind: 'Str', value: '40 + 2 = '
        },
        rhs: { 
          kind: 'Binary',
          op: 'Add',
          lhs: { kind: 'Int', value: 40 },
          rhs: { kind: 'Int', value: 2 }
        }
      }
    }, parser.ast)
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

    assert_equal({ 
      kind: 'Let', 
      name: { text: 'a' },
      value: { kind: 'Int', value: 40 },
      next: {
        kind: 'Let', 
        name: { text: 'b' },
        value: { kind: 'Int', value: 2 },
        next: { 
          kind: 'Print', 
          value: { 
            kind: 'Binary',
            op: 'Add',
            lhs: { kind: 'Var', text: 'a' },
            rhs: { kind: 'Var', text: 'b' }
          }
        }
      }
    }, parser.ast)
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

    assert_equal({ 
      kind: 'Print',
      value: { 
        kind: 'If',
        condition: { kind: 'Bool', value: true },
        then: { kind: 'Str', value: 'verdadeiro' },
        otherwise: { kind: 'Str', value: 'falso' }
      }
    }, parser.ast)
  end

  def test_print_let_if 
    program = <<~PROGRAM
      let a = 42;
      print(if (a == 42) {
        "a is 42"
      } else {
        "a is NOT 42"
      })
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)
    parser.parse!

    assert_equal({ 
      kind: 'Let',
      name: { text: 'a' },
      value: { kind: 'Int', value: 42 },
      next: { 
        kind: 'Print',
        value: { 
          kind: 'If',
          condition: { 
            kind: 'Binary',
            op: 'Eq',
            lhs: { kind: 'Var', text: 'a' },
            rhs: { kind: 'Int', value: 42 }
          },
          then: { kind: 'Str', value: 'a is 42' },
          otherwise: { kind: 'Str', value: 'a is NOT 42' }
        }
      }
    }, parser.ast)
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

    assert_equal({
      kind: 'Let',
      name: { text: 'add' },
      value: { 
        kind: 'Function',
        parameters: [
          { text: 'a' },
          { text: 'b' }
        ],
        value: { 
          kind: 'Binary',
          op: 'Add',
          lhs: { kind: 'Var', text: 'a' },
          rhs: { kind: 'Var', text: 'b' }
        }
      },
      next: { 
        kind: 'Print',
        value: {
          kind: 'Call',
          callee: { kind: 'Var', text: 'add' },
          arguments: [
            { kind: 'Int', value: 40 },
            { kind: 'Int', value: 2 }
          ]
        }
      }
    }, parser.ast)
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

    assert_equal({ 
      kind: 'Let',
      name: { text: 'sum' },
      value: { 
        kind: 'Function',
        parameters: [
          { text: 'n' },
          { text: 'acc' }
        ],
        value: { 
          kind: 'If',
          condition: {
            kind: 'Binary',
            op: 'Eq',
            lhs: { kind: 'Var', text: 'n' },
            rhs: { kind: 'Int', value: 0 }
          },
          then: { kind: 'Var', text: 'acc' },
          otherwise: { 
            kind: 'Call',
            callee: { kind: 'Var', text: 'sum' },
            arguments: [
              { 
                kind: 'Binary',
                op: 'Sub',
                lhs: { kind: 'Var', text: 'n' },
                rhs: { kind: 'Int', value: 1 }
              },
              { 
                kind: 'Binary',
                op: 'Add',
                lhs: { kind: 'Var', text: 'acc' },
                rhs: { kind: 'Var', text: 'n' }
              }
            ]
          }
        }
      },
      next: {
        kind: 'Print',
        value: { 
          kind: 'Call',
          callee: { kind: 'Var', text: 'sum' },
          arguments: [
            { kind: 'Int', value: 10 },
            { kind: 'Int', value: 0 }
          ]
        }
      }
    }, parser.ast)
  end

  def test_tuple_first
    program = <<~PROGRAM
      let person = ("Leandro", 42);
      print(first(person))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)

    parser.parse!

    assert_equal({ 
      kind: 'Let',
      name: { text: 'person' },
      value: { 
        kind: 'Tuple',
        first: { kind: 'Str', value: 'Leandro' },
        second: { kind: 'Int', value: 42 },
      },
      next: { 
        kind: 'Print',
        value: { 
          kind: 'First', 
          value: { 
            kind: 'Var',
            text: 'person'
          }
        }
      }
    }, parser.ast)
  end

  def test_tuple_second
    program = <<~PROGRAM
      let person = ("Leandro", 42);
      print(second(person))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)

    parser.parse!

    assert_equal({ 
      kind: 'Let',
      name: { text: 'person' },
      value: { 
        kind: 'Tuple',
        first: { kind: 'Str', value: 'Leandro' },
        second: { kind: 'Int', value: 42 },
      },
      next: { 
        kind: 'Print',
        value: { 
          kind: 'Second', 
          value: { 
            kind: 'Var',
            text: 'person'
          }
        }
      }
    }, parser.ast)
  end

  def test_tuple_anonymous
    program = <<~PROGRAM
      print(first(("Leandro", 42)))
    PROGRAM

    lexer = Lexer.new(program)
    parser = Parser.new(lexer)

    parser.parse!

    assert_equal({ 
      kind: 'Print',
      value: { 
        kind: 'First',
        value: { 
          kind: 'Tuple',
          first: { kind: 'Str', value: 'Leandro' },
          second: { kind: 'Int', value: 42 },
        }
      }
    }, parser.ast)
  end
end
