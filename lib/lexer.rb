require 'strscan'

class Lexer
  KEYWORDS = {
    'print' => :PRINT,
    'let' => :LET,
    'fn' => :FUNCTION,
    'if' => :IF,
    'else' => :ELSE,
    'true' => :TRUE,
    'false' => :FALSE
  }

  SYMBOLS = {
    '(' => :LPAREN,
    ')' => :RPAREN,
    '+' => :BINARY_OP,
    '-' => :BINARY_OP,
    '==' => :BINARY_OP,
    '<' => :BINARY_OP,
    '||' => :BINARY_OP,
    '=' => :ASSIGNMENT,
    ';' => :SEMICOLON,
    '{' => :LBRACE,
    '}' => :RBRACE,
    ',' => :COMMA,
    '=>' => :ARROW
  }

  def initialize(str)
    @scanner = StringScanner.new(str)
  end

  def tokenize
    tokens = []

    until @scanner.eos?
      token = next_token
      tokens << token if token
    end

    tokens
  end

  def next_token
    @scanner.skip(/\s+/) 
    @scanner.skip(/\n/)

    return if @scanner.eos?

    [
      :tokenize_keyword,
      :tokenize_symbol,
      :tokenize_identifier,
      :tokenize_string,
      :tokenize_number
    ].each do |method|
      if token = send(method)
        return token
      end
    end

    raise "Unexpected token at: #{@scanner.peek(10)}"
  end

  def tokenize_keyword
    if token = @scanner.scan(/print|let|fn|if|else|true|false/)
      [KEYWORDS[token], token]
    end
  end

  def tokenize_symbol
    # Allowed symbols
    # ( ) + - ; { } , == => = < ||
    if token = @scanner.scan(/[\(\)\+\-\;\{\}\,\<]|\=\=?\>?|\|{2}/)
      [SYMBOLS[token], token]
    end
  end

  def tokenize_identifier
    if token = @scanner.scan(/_|[a-zA-Z_][a-zA-Z0-9_]*/)
      [:IDENTIFIER, token]
    end 
  end

  def tokenize_string
    if @scanner.scan(/"(.*?)"/)
      [:STRING, @scanner[1]]
    end
  end

  def tokenize_number
    if token = @scanner.scan(/\d+/)
      [:NUMBER, token]
    end
  end
end
