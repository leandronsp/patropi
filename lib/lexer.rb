require 'strscan'

class Lexer
  KEYWORDS = {
    'print' => :PRINT
  }

  SYMBOLS = {
    '(' => :LPAREN,
    ')' => :RPAREN,
    '+' => :BINARY_OP
  }

  def initialize(str)
    @scanner = StringScanner.new(str)
  end

  def tokenize
    tokens = []

    until @scanner.eos?
      tokens << next_token
    end

    tokens
  end

  def next_token
    return if @scanner.eos?

    # Skip whitespace
    @scanner.skip(/\s+/)

    [
      :tokenize_keyword,
      :tokenize_symbol,
      :tokenize_string,
      :tokenize_integer
    ].each do |method|
      if token = send(method)
        return token
      end
    end

    raise "Unexpected token at: #{@scanner.peek(10)}"
  end

  def tokenize_keyword
    if token = @scanner.scan(/print/)
      [KEYWORDS[token], token]
    end
  end

  def tokenize_symbol
    if token = @scanner.scan(/[\(\)\+]/)
      [SYMBOLS[token], token]
    end
  end

  def tokenize_string
    if @scanner.scan(/"(.*?)"/)
      [:STRING, @scanner[1]]
    end
  end

  def tokenize_integer
    if token = @scanner.scan(/\d+/)
      [:NUMBER, token]
    end
  end
end
