require 'oj'

require_relative 'error'
require_relative 'ext'
require_relative 'trampoline'

class Interpreter 
  def self.run(*args) = new.run(*args)

  def initialize
    @terms = []
    @executors = []
    @fn_cache = {}

    @trampoline = Trampoline.new(@terms, @executors)
  end

  def run(json_input)
    parsed = Oj.load(json_input, symbolize_names: true)

    @terms.push(parsed[:expression])

    @trampoline.run do |term, scope, location|
      evaluate(term, scope, location)
    end
  end

  def evaluate(term, scope, location)
    case term
    in { kind: 'Bool', **data }; [:raw, data[:value],       scope, data[:location]]
    in { kind: 'Int',  **data }; [:raw, data[:value].to_i,  scope, data[:location]]
    in { kind: 'Str',  **data }; [:raw, data[:value].to_s,  scope, data[:location]]
    in { kind: 'Var',  **data }; [:raw, scope[data[:text]], scope, data[:location]]

    in { kind: 'Print',    **data }; evaluate_print(data, scope)
    in { kind: 'Binary',   **data }; evaluate_binary(data, scope)
    in { kind: 'Let',      **data }; evaluate_let(data, scope)
    in { kind: 'If',       **data }; evaluate_if(data, scope)
    in { kind: 'Function', **data }; evaluate_function(data, scope)
    in { kind: 'Call',     **data }; evaluate_fn_call(data, scope)
    in { kind: 'Tuple',    **data }; evaluate_tuple(data, scope)
    in { kind: 'First',    **data }; evaluate_tuple_access(data, scope, 0)
    in { kind: 'Second',   **data }; evaluate_tuple_access(data, scope, 1)

    else raise Error.new(location, "Unknown term: #{term}")
    end
  end

  def evaluate_print(data, scope)
    next_term, location = data.values_at(:value, :location)

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

  def evaluate_let(data, scope)
    text = data.dig(:name, :text)
    value, next_term, location = data.values_at(:value, :next, :location)

    @executors.push(-> (result) { 
      scope[text] = result
      @terms.push(next_term)
      [:noop, nil, scope, location]
    })

    @terms.push(value)
    [:noop, nil, scope, location]
  end

  def evaluate_if(data, scope)
    condition, then_term, otherwise_term, location = data
      .values_at(:condition, :then, :otherwise, :location)

    @executors.push(-> (result) { 
      result ? @terms.push(then_term) : @terms.push(otherwise_term)
      [:noop, nil, scope, location]
    })

    @terms.push(condition)
    [:noop, nil, scope, location]
  end

  def evaluate_function(data, scope)
    parameters, value, location = data.values_at(:parameters, :value, :location)

    func = -> (*args) { 
      new_scope = scope.dup

      parameters.each_with_index do |param, index|
        new_scope[param[:text]] = args[index]
      end

      scope = new_scope
      @terms.push(value)

      [:noop, nil, new_scope, location]
    }

    @executors.pop.call(func)
    [:noop, nil, scope, location]
  end

  def evaluate_tuple(data, scope)
    first, second, location = data.values_at(:first, :second, :location)

    @executors.push(-> (first) {
      @executors.push(-> (second) {
        [:raw, [first, second], scope, location]
      })

      [:noop, nil, scope, location]
    })

    @terms.push(second, first)

    [:noop, nil, scope, location]
  end

  def evaluate_tuple_access(data, scope, index)
    value, location = data.values_at(:value, :location)

    @terms.push(value)

    @executors.push(-> (tuple) { 
      (tuple.is_a?(Array) && tuple.size == 2) or 
        raise Error.new(location, "Not a tuple: #{tuple}")

      [:raw, tuple[index], scope, location]
    })

    [:noop, nil, scope, location]
  end

  def evaluate_fn_call(data, scope)
    callee, arguments, location = data.values_at(:callee, :arguments, :location)

    args = arguments.map do |arg|
      case arg
      in { kind: 'Binary', **data }
        left = evaluate(data[:lhs], scope, data[:location])[1]
        right = evaluate(data[:rhs], scope, data[:location])[1]

        evaluate_binary_op(data[:op], left, right, data[:location])
      in { kind: 'Function', **data }
        parameters = data[:parameters]
        value = data[:value]

        -> (*args) { 
          new_scope = scope.dup

          parameters.each_with_index do |param, index|
            new_scope[param[:text]] = args[index]
          end

          scope = new_scope
          @terms.push(value)

          [:noop, nil, new_scope, data[:location]]
        }
      else evaluate(arg, scope, location)[1]
      end
    end

    cache_key = "#{callee[:text]}(#{args.join(', ')})"

    @executors.push(-> (function) {
      begin 
        ## Memoization
        if result = @fn_cache[cache_key]
          [:raw, result, scope, location]
        else 
          if callee[:text] 
            @executors.push(-> (result) { 
              @fn_cache[cache_key] = result
              [:raw, result, scope, location]
            })
          end

          function.call(*args)
        end
      rescue => e
        raise Error.new(location, "Cannot call #{function} with #{args}: #{e.message}")
      end
    })

    @terms.push(callee)
    [:noop, nil, scope, location]
  end

  def evaluate_binary(data, scope)
    op, lhs, rhs, location = data.values_at(:op, :lhs, :rhs, :location)

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
    in ['Eq', _, _]; lhs == rhs
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
