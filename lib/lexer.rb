require 'strscan'

class Lexer
  KEYWORDS = {
    'print' => :PRINT
  }

  TOKENS = {
    '(' => :LPAREN,
    ')' => :RPAREN
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

    if token = @scanner.scan(/print/)
      [KEYWORDS[token], token]
    elsif token = @scanner.scan(/[\(\)]/)
      [TOKENS[token], token]
    elsif token = @scanner.scan(/"(.*?)"/)
      [:STRING, @scanner[1]]
    else 
      raise "Unexpected token at: #{@scanner.peek(10)}"
    end
  end
end
