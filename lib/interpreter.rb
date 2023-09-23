require 'json'

require_relative 'ext'
require_relative 'error'

class Interpreter 
  def self.run(*args) = new.run(*args)

  def initialize
    @terms = []
    @executors = []
  end

  def run(json_input)
    parsed = JSON.parse(json_input, symbolize_names: true)

    term = parsed[:expression]
    location = parsed[:location]

    @terms.push(term)
    scope = {}

    # Trampoline
    loop do 
      term = @terms.pop
      break if term.nil?
      continuation, result, scope, location = evaluate(term, scope, location)

      begin 
        case [continuation, result]
        in [:raw, result]
          executor = @executors.pop
          continuation, result, scope, location = executor&.call(result)

          next if continuation == :noop

          while executor = @executors.pop
            continuation, result, scope, location = executor&.call(result)
            break if continuation == :noop
          end
        in [:noop, nil]; next
        else raise Error.new(location, "Unknown continuation: #{continuation} with #{result}")
        end
      rescue => e
        raise Error.new(location, "Unexpected error while evaluating continuation: #{e.message}")
      end
    end
  end

  def evaluate(term, scope, location)
    case term
    in { kind: 'Str', **data }; [:raw, data[:value].to_s, scope, data[:location]]
    in { kind: 'Int', **data }; [:raw, data[:value].to_i, scope, data[:location]]
    in { kind: 'Bool', **data }; [:raw, data[:value], scope, data[:location]]

    in { kind: 'Print', **data }; evaluate_print(data[:value], scope, data[:location])
    in { kind: 'Binary', **data }; evaluate_binary(data[:op], data[:lhs], data[:rhs], scope, data[:location])
    in { kind: 'Let', **data }; evaluate_let(data[:name][:text], data[:value], data[:next], scope, data[:location])
    in { kind: 'Var', **data }; [:raw, scope[data[:text]], scope, data[:location]]
    in { kind: 'If', **data }; evaluate_if(data[:condition], data[:then], data[:otherwise], scope, data[:location])
    in { kind: 'Function', **data }; evaluate_function(data[:parameters], data[:value], scope, data[:location])
    in { kind: 'Call', **data }; evaluate_fn_call(data[:callee], data[:arguments], scope, data[:location])
    in { kind: 'Tuple', **data }; evaluate_tuple(data[:first], data[:second], scope, data[:location])
    in { kind: 'First', **data }; evaluate_tuple_access(data[:value], 0, scope, data[:location])
    in { kind: 'Second', **data }; evaluate_tuple_access(data[:value], 1, scope, data[:location])
    else raise Error.new(location, "Unknown term: #{term}")
    end
  end

  def evaluate_print(next_term, scope, location)
    @executors.push(-> (result) { 
      begin 
        print "#{result}\n"
        [:raw, result, scope, location]
      rescue => e
        raise Error.new(location, "Cannot print #{result}: #{e.message}")
      end
    })

    @terms.push(next_term)
    [:noop, nil, scope, location]
  end

  def evaluate_let(text, value, next_term, scope, location)
    @executors.push(-> (result) { 
      scope[text] = result
      @terms.push(next_term)
      [:noop, nil, scope, location]
    })

    @terms.push(value)
    [:noop, nil, scope, location]
  end

  def evaluate_if(condition, then_term, otherwise_term, scope, location)
    @executors.push(-> (result) { 
      result ? @terms.push(then_term) : @terms.push(otherwise_term)
      [:noop, nil, scope, location]
    })

    @terms.push(condition)
    [:noop, nil, scope, location]
  end

  def evaluate_function(parameters, value, scope, location)
    @executors.pop.call(-> (*args) { 
      new_scope = scope.dup

      parameters.each_with_index do |param, index|
        new_scope[param[:text]] = args[index]
      end

      scope = new_scope
      @terms.push(value)

      [:noop, nil, new_scope, location]
    })

    [:noop, nil, scope, location]
  end

  def evaluate_tuple(first, second, scope, location)
    @executors.push(-> (first) {
      @executors.push(-> (second) {
        [:raw, [first, second], scope, location]
      })

      [:noop, nil, scope, location]
    })

    @terms.push(second, first)

    [:noop, nil, scope, location]
  end

  def evaluate_tuple_access(value, index, scope, location)
    @terms.push(value)

    @executors.push(-> (tuple) { 
      (tuple.is_a?(Array) && tuple.size == 2) or 
        raise Error.new(location, "Not a tuple: #{tuple}")

      [:raw, tuple[index], scope, location]
    })

    [:noop, nil, scope, location]
  end

  def evaluate_fn_call(callee, arguments, scope, location)
    args = arguments.map do |arg|
      case arg
      in { kind: 'Binary', **data }
        left = evaluate(data[:lhs], scope, data[:location])[1]
        right = evaluate(data[:rhs], scope, data[:location])[1]

        evaluate_binary_op(data[:op], left, right, data[:location])
      else evaluate(arg, scope, location)[1]
      end
    end

    @executors.push(-> (function) {
      begin 
        function.call(*args) 
      rescue => e
        raise Error.new(location, "Cannot call #{function} with #{args}: #{e.message}")
      end
    })

    @terms.push(callee)
    [:noop, nil, scope, location]
  end

  def evaluate_binary(op, lhs, rhs, scope, location)
    @terms.push(rhs, lhs)

    @executors.push(-> (left) { 
      @executors.push(-> (right) { 
        [:raw, evaluate_binary_op(op, left, right, location), scope, location]
      })

      [:noop, nil, scope, location]
    })

    [:noop, nil, scope, location]
  end

  def evaluate_binary_op(op, lhs, rhs, location)
    case [op, lhs, rhs]
    in ['Add', Integer, Integer]; lhs + rhs
    in ['Add', _, _]; "#{lhs}#{rhs}"
    in ['Mul', Integer, Integer]; lhs * rhs
    in ['Div', Integer, Integer]; lhs / rhs
    in ['Rem', Integer, Integer]; lhs % rhs
    in ['Sub', Integer, Integer]; lhs - rhs
    in ['Eq', Integer, Integer]; lhs == rhs
    in ['Lt', Integer, Integer]; lhs < rhs
    in ['Lte', Integer, Integer]; lhs <= rhs
    in ['Gt', Integer, Integer]; lhs > rhs
    in ['Gte', Integer, Integer]; lhs >= rhs
    in ['Neq', _, _]; lhs != rhs
    in ['Or', _, _]; lhs || rhs
    in ['And', _, _]; lhs && rhs
    else  
      raise Error.new(location, "Unknown binary operation: #{op} using #{lhs} and #{rhs}")
    end

    rescue => e 
      raise Error.new(location, "Unexpected error while evaluating binary operation: #{e.message}")
  end
end
