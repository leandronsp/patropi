require 'json'
require 'pry-byebug'

class Interpreter 
  def self.run(*args) = new.run(*args)

  def initialize
    @stack = []
    @executors = []
    @scope = {}
  end

  def run(json_input)
    parsed = JSON.parse(json_input, symbolize_names: true)
    @stack.push(parsed[:expression])

    # Trampoline
    loop do 
      term = @stack.pop
      break if term.nil?
      continuation, result = evaluate(term)

      case [continuation, result]
      in [:raw, result]
        executor = @executors.pop
        continuation, result = executor&.call(result)

        next if continuation == :noop

        while executor = @executors.pop
          continuation, result = executor&.call(result)
          break if continuation == :noop
        end
      in [:noop, nil]; next
      else raise "Unkonwn result: #{[continuation, result]}"
      end
    end
  end

  def evaluate(term)
    case term
    in { kind: 'Str', value: value }; [:raw, value.to_s]
    in { kind: 'Int', value: value }; [:raw, value.to_i]
    in { kind: 'Bool', value: value }; [:raw, value]
    in { kind: 'Print', value: next_term }
      @executors.push(-> (result) { puts result })
      @stack.push(next_term)
      [:noop, nil]
    in { kind: 'BinaryOp', op: op, lhs: lhs, rhs: rhs }
      @executors.push(-> (left) { 
        @executors.push(-> (left, right) { 
          result = case [op, left, right]
                   in ['Add', Integer, Integer]; left + right
                   in ['Add', _, _]; "#{left}#{right}"
                   in ['Sub', Integer, Integer]; left - right
                   in ['Eq', Integer, Integer]; left == right
                   else raise "Unkown operation #{[op, left, right]}"
                   end
          [:raw, result]
        }.curry[left])

        [:noop, nil]
      })

      @stack.push(rhs, lhs)
      [:noop, nil]
    in { kind: 'Let', name: { text: text }, value: value, next: next_term }
      @executors.push(-> (result) { 
        @scope[text] = result
        [:noop, nil]
      })

      @stack.push(next_term, value)
      [:noop, nil]
    in { kind: 'Var', text: text }; [:raw, @scope[text]]
    in { kind: 'If', condition: condition, then: then_term, otherwise: otherwise_term }
      @executors.push(-> (result) { 
        @stack.push(result ? then_term : otherwise_term)  
        [:noop, nil]
      })

      @stack.push(condition)
      [:noop, nil]
    in { kind: 'Function', parameters: parameters, value: value }
      @executors.pop.call(-> (*args) { 
        params = parameters.map { |param| param[:text] }
        fn_args = params.zip(args).to_h
        @scope.merge!(fn_args)
        @stack.push(value)
        [:noop, nil]
      })

      [:noop, nil]
    in { kind: 'Call', callee: callee, arguments: arguments }
      args = arguments.map { |arg| evaluate(arg)[1] }

      @executors.push(-> (function) {
        function.call(*args)
      })

      @stack.push(callee)
      [:noop, nil]
    else raise "Unkonwn term: #{term}"
    end
  end
end
