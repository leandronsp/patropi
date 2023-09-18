require 'byebug'

class Parser
  attr_reader :ast

  BINARY_OPERATIONS = { 
    '+' => 'Add',
    '-' => 'Sub',
    '==' => 'Eq',
    '<' => 'Lt',
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
      elsif @current_token[0] == :FUNCTION
        parse_function(node[:value])
      else
        raise "Unknown token inside LET #{@current_token}"
      end

      consume(:SEMICOLON)

      node.merge!({ next: {} })
      parse!(node[:next])
    else
      raise "Syntax error. Expected print statement but found #{@current_token[0]}"
    end
  end

  def parse_print_statement(node = nil)
    node ||= {}

    case @current_token
    in [:STRING, _]; parse_string(node)
    in [:NUMBER, _]; parse_number(node)
    in [:IDENTIFIER, _]; parse_identifier(node)
    in [:IF, _]; parse_if_statement(node)
    else
      raise "Unknown token inside PRINT #{@current_token}"
    end

    node
  end

  def parse_function(node)
    node.merge!({ kind: 'Function', parameters: [] })

    consume(:FUNCTION)
    consume(:LPAREN)

    while @current_token[0] != :RPAREN
      node[:parameters] << { text: @current_token[1] }
      consume(:IDENTIFIER)
      consume(:COMMA) if @current_token[0] == :COMMA
    end

    consume(:RPAREN)
    consume(:ARROW)
    consume(:LBRACE)

    node.merge!({ value: {} })

    # TODO: refactor to make dynamically
    if @current_token[0] == :IDENTIFIER
      identifier_token = { kind: 'Var', text: @current_token[1] } 
      consume(:IDENTIFIER)
      parse_binary_op(node[:value], identifier_token)
    end

    if @current_token[0] == :IF 
      parse_if_statement(node[:value])
    end

    consume(:RBRACE)
  end

  def parse_if_statement(node)
    node.merge!({ kind: 'If', condition: {} })

    consume(:IF)
    consume(:LPAREN)

    if @current_token[0] == :TRUE
      node[:condition].merge!({ kind: 'Bool', value: true })
      consume(:TRUE)
    elsif @current_token[0] == :FALSE
      node[:condition].merge!({ kind: 'Bool', value: false })
      consume(:FALSE)
    elsif @current_token[0] == :IDENTIFIER
      parse_identifier(node[:condition])
    end

    consume(:RPAREN) 
    consume(:LBRACE)

    node.merge!({ then: {} })
    parse_print_statement(node[:then])

    consume(:RBRACE)

    if @current_token[0] == :ELSE
      consume(:ELSE)
      consume(:LBRACE)

      node.merge!({ otherwise: {} })
      #byebug
      parse_print_statement(node[:otherwise])

      consume(:RBRACE)
    end
  end

  def parse_function_call(node, identifier_token)
    node.merge!({ kind: 'Call', callee: identifier_token, arguments: [] })

    while @current_token[0] != :RPAREN
      node[:arguments] << parse_print_statement
      consume(:COMMA) if @current_token[0] == :COMMA
    end
  end

  def parse_identifier(node)
    identifier_token = { kind: 'Var', text: @current_token[1] }
    consume(:IDENTIFIER)

    if @current_token[0] == :BINARY_OP
      parse_binary_op(node, identifier_token)
    elsif @current_token[0] == :LPAREN # function call
      advance!
      parse_function_call(node, identifier_token)
      consume(:RPAREN)
      #byebug
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
