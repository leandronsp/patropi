require 'byebug'

class Parser
  attr_reader :ast

  def initialize(lexer)
    @lexer = lexer

    @ast = {}
    @current_token = nil
  end

  def parse!
    advance!

    case @current_token
    in [:PRINT, _]
      node = @ast.merge!({ kind: 'Print', value: {} })

      consume(:LPAREN)

      case @current_token
      in [:STRING, value]
        node[:value].merge!({ 
          kind: 'Str',  
          value: value
        })
      in [:INTEGER, value]
        node[:value].merge!({
          kind: 'Int',
          value: value
        })
      else 
        raise "Unknown token inside PRINT #{@current_token}"
      end

      consume(:RPAREN)
    else
      raise "Syntax error. Expected print statement but found #{@current_token[0]}"
    end
  end

  def advance! 
    @current_token = @lexer.next_token
  end

  def consume(token_type)
    advance!

    raise "Expected #{token_type} but found nil" unless @current_token
    raise "Expected #{token_type} but found #{@current_token[0]}" unless @current_token[0] == token_type

    advance!
  end
end
