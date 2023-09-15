class Parser
  def initialize(lexer)
    @lexer = lexer
    @current_token = nil
  end

  def parse
    ast = {}
    advance!

    if consume(:PRINT)
      consume(:LPAREN)

      string_token = expect(:STRING)

      ast.merge!({ 
        kind: 'Print',
        value: { 
          kind: 'Str',  
          value: string_token[1]
        }
      }).tap { consume(:RPAREN) } 
    else
      raise "Syntax error. Expected print statement but found #{@current_token[0]}"
    end

    ast
  end

  def advance! 
    @current_token = @lexer.next_token
  end

  def consume(token_type)
    return false unless @current_token[0] == token_type

    advance!
    true
  end

  def expect(token_type)
    @current_token.tap do |token|
      raise "Syntax error. Expected #{token_type} but found #{@current_token[0]}" if token[0] != token_type
      advance!
    end
  end
end
