require 'strscan'

class Lexer
  KEYWORDS = {
    'print' => :PRINT,
    'let' => :LET
  }

  SYMBOLS = {
    '(' => :LPAREN,
    ')' => :RPAREN,
    '+' => :BINARY_OP,
    '-' => :BINARY_OP,
    '==' => :BINARY_OP,
    '=' => :ASSIGNMENT,
    ';' => :SEMICOLON
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
    if token = @scanner.scan(/print|let/)
      [KEYWORDS[token], token]
    end
  end

  def tokenize_symbol
    if token = @scanner.scan(/[\(\)\+\-\;]|\=\=?/)
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
