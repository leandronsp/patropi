require 'byebug'

class Parser
  attr_reader :ast

  BINARY_OPERATIONS = { 
    '+' => 'Add',
    '-' => 'Sub',
    '==' => 'Eq'
  }

  def initialize(lexer)
    @lexer = lexer

    @ast = {}
    @current_token = nil

    advance!
  end

  def parse!(scope = nil)
    scope ||= @ast

    case @current_token
    in [:PRINT, _]
      node = scope.merge!({ kind: 'Print', value: {} })

      consume(:PRINT) 
      consume(:LPAREN)

      parse_print_statement(node[:value])
      consume(:RPAREN)
    in [:LET, _]
      node = scope.merge!({ kind: 'Let', value: {} })
      consume(:LET)

      # consume identifier
      identifier = @current_token[1]
      node.merge!({ name: { text: identifier } })
      consume(:IDENTIFIER)
      consume(:ASSIGNMENT)

      # consume value
      if @current_token[0] == :STRING
        parse_string(node[:value])
      elsif @current_token[0] == :NUMBER
        parse_number(node[:value])
      end

      consume(:SEMICOLON)

      node.merge!({ next: {} })
      parse!(node[:next])
    else
      raise "Syntax error. Expected print statement but found #{@current_token[0]}"
    end
  end

  def parse_print_statement(node)
    case @current_token
    in [:STRING, _]; parse_string(node)
    in [:NUMBER, _]; parse_number(node)
    in [:IDENTIFIER, _]; parse_identifier(node)
    else
      raise "Unknown token inside PRINT #{@current_token}"
    end
  end

  def parse_identifier(node)
    identifier_token = { kind: 'Var', text: @current_token[1] }
    consume(:IDENTIFIER)

    if @current_token[0] == :BINARY_OP
      parse_binary_op(node, identifier_token)
    else 
      node.merge!(identifier_token)
    end
  end

  def parse_string(node)
    string_token = { kind: 'Str', value: @current_token[1] }
    consume(:STRING)

    if @current_token[0] == :BINARY_OP
      parse_binary_op(node, string_token)
    else
      node.merge!(string_token)
    end
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
    parse_string(node[:rhs]) if @current_token[0] == :STRING
    parse_identifier(node[:rhs]) if @current_token[0] == :IDENTIFIER
  end

  def advance! 
    @current_token = @lexer.next_token
  end

  def consume(token_type)
    raise "Expected #{token_type} but found nil" unless @current_token
    raise "Expected #{token_type} but found #{@current_token[0]} in #{@current_token}" unless @current_token[0] == token_type

    advance!
  end
end
