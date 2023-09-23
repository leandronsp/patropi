require 'json'
require 'pry-byebug'

require_relative './ext'

class Interpreter 
  def self.run(*args) = new.run(*args)

  def initialize
    @terms = []
    @executors = []
  end

  def run(json_input)
    parsed = JSON.parse(json_input, symbolize_names: true)
    @terms.push(parsed[:expression])
    scope = {}

    # Trampoline
    loop do 
      term = @terms.pop
      break if term.nil?
      continuation, result, scope = evaluate(term, scope)

      case [continuation, result]
      in [:raw, result]
        executor = @executors.pop
        continuation, result, scope = executor&.call(result)

        next if continuation == :noop

        while executor = @executors.pop
          continuation, result, scope = executor&.call(result)
          break if continuation == :noop
        end
      in [:noop, nil]; next
      else raise "Unknown result: #{[continuation, result]}"
      end
    end
  end

  def evaluate(term, scope = nil)
    scope ||= {}

    case term
    in { kind: 'Str', value: value }; [:raw, value.to_s, scope]
    in { kind: 'Int', value: value }; [:raw, value.to_i, scope]
    in { kind: 'Bool', value: value }; [:raw, value, scope]
    in { kind: 'Print', value: next_term }; evaluate_print(next_term, scope)
    in { kind: 'Binary', op: op, lhs: lhs, rhs: rhs }; evaluate_binary(op, lhs, rhs, scope)
    in { kind: 'Let', name: { text: text }, value: value, next: next_term }; evaluate_let(text, value, next_term, scope)
    in { kind: 'Var', text: text }; [:raw, scope[text], scope]
    in { kind: 'If', condition: condition, then: then_term, otherwise: otherwise_term }; evaluate_if(condition, then_term, otherwise_term, scope)
    in { kind: 'Function', parameters: parameters, value: value }; evaluate_function(parameters, value, scope)
    in { kind: 'Call', callee: callee, arguments: arguments }; evaluate_fn_call(callee, arguments, scope)
    in { kind: 'Tuple', first: first, second: second }; evaluate_tuple(first, second, scope)
    in { kind: 'First', value: value }; evaluate_tuple_access(value, 0, scope)
    in { kind: 'Second', value: value }; evaluate_tuple_access(value, 1, scope)
    else raise "Unknown term: #{term}"
    end
  end

  def evaluate_print(next_term, scope)
    @executors.push(-> (result) { 
      print "#{result}\n"
      [:raw, result]
    })

    @terms.push(next_term)
    [:noop, nil, scope]
  end

  def evaluate_let(text, value, next_term, scope)
    @executors.push(-> (result) { 
      scope[text] = result
      @terms.push(next_term)
      [:noop, nil, scope]
    })

    @terms.push(value)
    [:noop, nil, scope]
  end

  def evaluate_if(condition, then_term, otherwise_term, scope)
    @executors.push(-> (result) { 
      result ? @terms.push(then_term) : @terms.push(otherwise_term)
      [:noop, nil, scope]
    })

    @terms.push(condition)
    [:noop, nil, scope]
  end

  def evaluate_function(parameters, value, scope)
    @executors.pop.call(-> (*args) { 
      new_scope = scope.dup

      parameters.each_with_index do |parameter, index|
        new_scope[parameter[:text]] = args[index]
      end

      scope = new_scope

      @terms.push(value)
      [:noop, nil, new_scope]
    })

    [:noop, nil, scope]
  end

  def evaluate_tuple(first, second, scope)
    @executors.push(-> (first) {
      @executors.push(-> (second) {
        [:raw, [first, second], scope]
      })

      [:noop, nil, scope]
    })

    @terms.push(second, first)

    [:noop, nil, scope]
  end

  def evaluate_tuple_access(value, index, scope)
    @terms.push(value)

    @executors.push(-> (tuple) { 
      [:raw, tuple[index], scope]
    })

    [:noop, nil, scope]
  end

  def evaluate_fn_call(callee, arguments, scope)
    args = arguments.map do |arg|
      case arg
      in { kind: 'Binary', op: op, lhs: lhs, rhs: rhs }
        left = evaluate(lhs, scope)[1]
        right = evaluate(rhs, scope)[1]

        evaluate_binary_op(op, left, right)
      else evaluate(arg, scope)[1]
      end
    end

    @executors.push(-> (function) {
      function.call(*args) 
    })

    @terms.push(callee)
    [:noop, nil, scope]
  end

  def evaluate_binary(op, lhs, rhs, scope)
    @terms.push(rhs, lhs)

    @executors.push(-> (left) { 
      @executors.push(-> (right) { 
        [:raw, evaluate_binary_op(op, left, right), scope]
      })

      [:noop, nil, scope]
    })

    [:noop, nil, scope]
  end

  def evaluate_binary_op(op, lhs, rhs)
    case [op, lhs, rhs]
    in ['Add', Integer, Integer]; lhs + rhs
    in ['Add', _, _]; "#{lhs}#{rhs}"
    in ['Sub', Integer, Integer]; lhs - rhs
    in ['Eq', Integer, Integer]; lhs == rhs
    in ['Lt', Integer, Integer]; lhs < rhs
    in ['Or', _, _]; lhs || rhs
    else raise "Unknown operation #{[op, lhs, rhs]}"
    end
  end
end
