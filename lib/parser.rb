require 'byebug'

class Parser
  attr_reader :ast

  BINARY_OPERATIONS = { 
    '+' => 'Add',
  }

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

      consume(:PRINT)
      consume(:LPAREN)

      parse_print_statement(node[:value])
      consume(:RPAREN)
    else
      raise "Syntax error. Expected print statement but found #{@current_token[0]}"
    end
  end

  def parse_print_statement(node)
    case @current_token
    in [:STRING, _]; parse_string(node)
    in [:NUMBER, _]; parse_number(node)
    else
      raise "Unknown token inside PRINT #{@current_token}"
    end
  end

  def parse_string(node)
    node.merge!({ kind: 'Str', value: @current_token[1] })
    consume(:STRING)
  end

  def parse_number(node)
    integer_token = { kind: 'Int', value: @current_token[1].to_i }
    consume(:NUMBER)

    if @current_token[0] == :BINARY_OP
      parse_binary_op(node, integer_token)
    else 
      node.merge!(integer_token)
    end
  end

  def parse_binary_op(node, lhs_token)
    node.merge!({ 
      kind: 'BinaryOp', 
      op: BINARY_OPERATIONS[@current_token[1]], 
      lhs: lhs_token,
      rhs: {} 
    })

    consume(:BINARY_OP)
    parse_number(node[:rhs]) if @current_token[0] == :NUMBER
  end

  def advance! 
    @current_token = @lexer.next_token
  end

  def consume(token_type)
    raise "Expected #{token_type} but found nil" unless @current_token
    raise "Expected #{token_type} but found #{@current_token[0]}" unless @current_token[0] == token_type

    advance!
  end
end
