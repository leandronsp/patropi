require 'json'
require 'pry-byebug'

class Interpreter 
  def self.run(*args) = new.run(*args)

  def initialize
    @stack = []
    @executors = []
  end

  def run(json_input)
    parsed = JSON.parse(json_input, symbolize_names: true)
    @stack.push(parsed[:expression])
    scope = {}

    # Trampoline
    loop do 
      term = @stack.pop
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
      else raise "Unkonwn result: #{[continuation, result]}"
      end
    end
  end

  def evaluate(term, scope = nil)
    scope ||= {}

    case term
    in { kind: 'Str', value: value }; [:raw, value.to_s, scope]
    in { kind: 'Int', value: value }; [:raw, value.to_i, scope]
    in { kind: 'Bool', value: value }; [:raw, value, scope]
    in { kind: 'Print', value: next_term }
      @executors.push(-> (result) { puts result })
      @stack.push(next_term)
      [:noop, nil, scope]
    in { kind: 'BinaryOp', op: op, lhs: lhs, rhs: rhs }
      @executors.push(-> (left) { 
        @executors.push(-> (left, right) { 
          result = case [op, left, right]
                   in ['Add', Integer, Integer]; left + right
                   in ['Add', _, _]; "#{left}#{right}"
                   in ['Sub', Integer, Integer]; left - right
                   in ['Eq', Integer, Integer]; left == right
                   in ['Lt', Integer, Integer]; left < right
                   else raise "Unkown operation #{[op, left, right]}"
                   end
          [:raw, result, scope]
        }.curry[left])

        [:noop, nil, scope]
      })

      @stack.push(rhs, lhs)
      [:noop, nil, scope]
    in { kind: 'Let', name: { text: text }, value: value, next: next_term }
      @executors.push(-> (result) { 
        scope[text] = result
        [:noop, nil, scope]
      })

      @stack.push(next_term, value)
      [:noop, nil, scope]
    in { kind: 'Var', text: text }
      [:raw, scope[text], scope]
    in { kind: 'If', condition: condition, then: then_term, otherwise: otherwise_term }
      @executors.push(-> (result) { 
        @stack.push(result ? then_term : otherwise_term)  
        [:noop, nil, scope]
      })

      @stack.push(condition)
      [:noop, nil, scope]
    in { kind: 'Function', parameters: parameters, value: value }
      @executors.pop.call(-> (*args) { 
        params = parameters.map { |param| param[:text] }
        fn_args = params.zip(args).to_h
        scope.merge!(fn_args)
        @stack.push(value)
        [:noop, nil, scope]
      })

      [:noop, nil, scope]
    in { kind: 'Call', callee: callee, arguments: arguments }
      args = arguments.map do |arg|
        case arg
        in { kind: 'BinaryOp', op: op, lhs: lhs, rhs: rhs }
          left = evaluate(lhs, scope)[1]
          right = evaluate(rhs, scope)[1]

          case [op, left, right]
          in ['Add', Integer, Integer]; left + right
          in ['Add', _, _]; "#{left}#{right}"
          in ['Sub', Integer, Integer]; left - right
          in ['Eq', Integer, Integer]; left == right
          in ['Lt', Integer, Integer]; left < right
          else raise "Unkown operation #{[op, left, right]}"
          end
        else evaluate(arg, scope)[1]
        end
      end

      @executors.push(-> (function) {
        function.call(*args)
      })

      @stack.push(callee)
      [:noop, nil, scope]
    else raise "Unkonwn term: #{term}"
    end
  end
end
