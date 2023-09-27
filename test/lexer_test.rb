# frozen_string_literal: true

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

  def test_print_if
    program = <<~PROGRAM
      print(if (true) {
        "verdadeiro"
      } else {
        "falso"
      })
    PROGRAM

    lexer = Lexer.new(program)

    assert_equal([
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:IF, 'if'],
      [:LPAREN, '('],
      [:TRUE, 'true'],
      [:RPAREN, ')'],
      [:LBRACE, '{'],
      [:STRING, 'verdadeiro'],
      [:RBRACE, '}'],
      [:ELSE, 'else'],
      [:LBRACE, '{'],
      [:STRING, 'falso'],
      [:RBRACE, '}'],
      [:RPAREN, ')']
    ], lexer.tokenize)
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

    assert_equal([
      [:LET, 'let'],
      [:IDENTIFIER, 'a'],
      [:ASSIGNMENT, '='],
      [:NUMBER, '42'],
      [:SEMICOLON, ';'],
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:IF, 'if'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'a'],
      [:BINARY_OP, '=='],
      [:NUMBER, '42'],
      [:RPAREN, ')'],
      [:LBRACE, '{'],
      [:STRING, 'a is 42'],
      [:RBRACE, '}'],
      [:ELSE, 'else'],
      [:LBRACE, '{'],
      [:STRING, 'a is NOT 42'],
      [:RBRACE, '}'],
      [:RPAREN, ')']
    ], lexer.tokenize)
  end

  def test_print_function
    program = <<~PROGRAM
      let add = fn (a, b) => {
        a + b
      };
      print(add(1, 2))
    PROGRAM

    lexer = Lexer.new(program)

    assert_equal([
      [:LET, 'let'],
      [:IDENTIFIER, 'add'],
      [:ASSIGNMENT, '='],
      [:FUNCTION, 'fn'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'a'],
      [:COMMA, ','],
      [:IDENTIFIER, 'b'],
      [:RPAREN, ')'],
      [:ARROW, '=>'],
      [:LBRACE, '{'],
      [:IDENTIFIER, 'a'],
      [:BINARY_OP, '+'],
      [:IDENTIFIER, 'b'],
      [:RBRACE, '}'],
      [:SEMICOLON, ';'],
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'add'],
      [:LPAREN, '('],
      [:NUMBER, '1'],
      [:COMMA, ','],
      [:NUMBER, '2'],
      [:RPAREN, ')'],
      [:RPAREN, ')']
    ], lexer.tokenize)
  end

  def test_print_recursive_sum
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

    assert_equal([
      [:LET, 'let'],
      [:IDENTIFIER, 'sum'], 
      [:ASSIGNMENT, '='],
      [:FUNCTION, 'fn'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'n'],
      [:COMMA, ','],
      [:IDENTIFIER, 'acc'],
      [:RPAREN, ')'],
      [:ARROW, '=>'],
      [:LBRACE, '{'],
      [:IF, 'if'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'n'],
      [:BINARY_OP, '=='],
      [:NUMBER, '0'],
      [:RPAREN, ')'],
      [:LBRACE, '{'],
      [:IDENTIFIER, 'acc'],
      [:RBRACE, '}'],
      [:ELSE, 'else'],
      [:LBRACE, '{'],
      [:IDENTIFIER, 'sum'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'n'],
      [:BINARY_OP, '-'],
      [:NUMBER, '1'],
      [:COMMA, ','],
      [:IDENTIFIER, 'acc'],
      [:BINARY_OP, '+'],
      [:IDENTIFIER, 'n'],
      [:RPAREN, ')'],
      [:RBRACE, '}'],
      [:RBRACE, '}'],
      [:SEMICOLON, ';'],
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'sum'],
      [:LPAREN, '('],
      [:NUMBER, '10'],
      [:COMMA, ','],
      [:NUMBER, '0'],
      [:RPAREN, ')'],
      [:RPAREN, ')']
    ], lexer.tokenize)
  end

  def test_tuple 
    program = <<~PROGRAM
      let person = ("Leandro", 42);
      print(first(person))
    PROGRAM

    lexer = Lexer.new(program)

    assert_equal([ 
      [:LET, 'let'],
      [:IDENTIFIER, 'person'],
      [:ASSIGNMENT, '='],
      [:LPAREN, '('],
      [:STRING, 'Leandro'],
      [:COMMA, ','],
      [:NUMBER, '42'],
      [:RPAREN, ')'],
      [:SEMICOLON, ';'],
      [:PRINT, 'print'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'first'],
      [:LPAREN, '('],
      [:IDENTIFIER, 'person'],
      [:RPAREN, ')'],
      [:RPAREN, ')']
    ], lexer.tokenize)
  end
end
