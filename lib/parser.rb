require 'byebug'

class Parser
  attr_reader :ast

  BINARY_OPERATIONS = { 
    '+' => 'Add',
    '-' => 'Sub',
    '==' => 'Eq',
    '<' => 'Lt'
  }

  def initialize(lexer)
    @lexer = lexer

    @ast = {}
    @current_token = nil

    advance!
  end

  def parse!
    @ast.merge!(parse_current_term)
  end

  def parse_current_term
    case @current_token 
    in [:STRING, _]; maybe_binary_op { parse_string }
    in [:NUMBER, _]; maybe_binary_op { parse_integer }
    in [:IDENTIFIER, _]; maybe_binary_op { parse_identifier }
    in [:TRUE, _]; parse_boolean
    in [:FALSE, _]; parse_boolean
    in [:PRINT, _]; parse_print
    in [:LET, _]; parse_let
    in [:IF, _]; parse_if_statement
    in [:FUNCTION, _]; parse_function
    end
  end

  def parse_print 
    node = { kind: 'Print', value: {} }
    consume(:PRINT)
    consume(:LPAREN)

    node[:value] = parse_current_term

    consume(:RPAREN)
    node
  end

  def parse_let 
    node = { kind: 'Let', name: { text: nil }, value: {} }
    consume(:LET)

    node[:name][:text] = @current_token[1]
    consume(:IDENTIFIER)
    consume(:ASSIGNMENT)

    node[:value] = parse_current_term
    consume(:SEMICOLON)
    node[:next] = parse_current_term

    node
  end

  def parse_if_statement
    node = { kind: 'If', condition: {}, then: {}, otherwise: {} }

    consume(:IF)
    consume(:LPAREN)

    node[:condition] = parse_current_term

    consume(:RPAREN)
    consume(:LBRACE)

    node[:then] = parse_current_term

    consume(:RBRACE)

    if @current_token[0] == :ELSE
      consume(:ELSE)
      consume(:LBRACE)

      node[:otherwise] = parse_current_term

      consume(:RBRACE)
    end

    node
  end

  def parse_function
    node = { kind: 'Function', parameters: [], value: {} }

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

    node[:value] = parse_current_term

    consume(:RBRACE)
    node
  end

  def parse_function_call(callee)
    node = { kind: 'Call', callee: callee, arguments: [] }

    while @current_token[0] != :RPAREN
      node[:arguments] << parse_current_term
      consume(:COMMA) if @current_token[0] == :COMMA
    end

    node
  end

  def parse_identifier
    node = { kind: 'Var', text: @current_token[1] }
    consume(:IDENTIFIER)

    if @current_token[0] == :LPAREN # function call
      consume(:LPAREN)
      function_call_node = maybe_binary_op { parse_function_call(node) }
      consume(:RPAREN)
      return function_call_node
    end

    node
  end

  def parse_string
    node = { kind: 'Str', value: @current_token[1] }
    consume(:STRING)

    node
  end

  def parse_integer
    node = { kind: 'Int', value: @current_token[1].to_i }
    consume(:NUMBER)

    node
  end

  def parse_boolean
    node = { kind: 'Bool', value: @current_token[1] == 'true' }
    consume(@current_token[0].upcase.to_sym)

    node
  end

  def maybe_binary_op
    return unless block_given?

    lhs = yield
    return lhs unless @current_token[0] == :BINARY_OP

    operation = BINARY_OPERATIONS[@current_token[1]]
    consume(:BINARY_OP)

    { 
      kind: 'Binary', 
      op: operation,
      lhs: lhs,
      rhs: parse_current_term
    }
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
