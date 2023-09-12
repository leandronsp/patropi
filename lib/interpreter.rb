require 'json'

class Interpreter 
  def self.run = new.run

  def initialize(scope = nil)
    @scope = scope || {}
  end

  def run
    input = read_stdin # json
    parsed = JSON.parse(input, symbolize_names: true)

    evaluate(parsed[:expression])
  end

  def evaluate(term)
    #puts "Term: #{term}"

    case term
    in { kind: 'Print', value: value }; puts evaluate(value)
    in { kind: 'Int', value: value }; value.to_i
    in { kind: 'Str', value: value }; value.to_s
    in { kind: 'Bool', value: value }; value
    in { kind: 'Binary', op: 'Add', lhs: lhs, rhs: rhs }
      left = evaluate(lhs)
      right = evaluate(rhs)

      case [left, right]
      in [Integer, Integer]; left + right
      else "#{left}#{right}"
      end
    in { kind: 'Binary', op: 'Sub', lhs: lhs, rhs: rhs }
      left = evaluate(lhs)
      right = evaluate(rhs)

      case [left, right]
      in [Integer, Integer]; left - right
      else "#{left}#{right}"
      end
    in { kind: 'Binary', op: 'Lt', lhs: lhs, rhs: rhs }
      left = evaluate(lhs)
      right = evaluate(rhs)

      case [left, right]
      in [Integer, Integer]; left < right
      else "#{left}#{right}"
      end
    in { kind: 'Binary', op: 'Eq', lhs: lhs, rhs: rhs }
      left = evaluate(lhs)
      right = evaluate(rhs)

      case [left, right]
      in [Integer, Integer]; left == right
      else "#{left}#{right}"
      end
    in { kind: 'If', condition: condition, then: then_do, otherwise: otherwise_do }
      if [true, 'true'].include?(evaluate(condition))
        evaluate(then_do)
      else 
        evaluate(otherwise_do)
      end
    in { kind: 'Let', name: { text: text }, value: value, next: next_term }
      raw_value = evaluate(value)

      @scope[text] = raw_value
      evaluate(next_term)
    in { kind: 'Var', text: text }; @scope[text]
    in { kind: 'Function', parameters: parameters, value: value }
      params = parameters.map { |param| param[:text] }

      -> (*args) do
        arguments = params.zip(args).to_h

        arguments.each do |(name, value)|
          @scope[name] = value
        end

        Interpreter.new(@scope.clone).evaluate(value)
      end
    in { kind: 'Call', callee: callee, arguments: arguments }
      args = arguments.map(&method(:evaluate))

      function = evaluate(callee)

      function.call(*args)

      # Trampoline
      #while result.is_a?(Proc)
      #  result = result.call
      #end

      #result
    else 
      puts "Invalid term #{term}"
    end
  end

  def read_stdin
    input = ""

    while line = STDIN.gets
      input += line
    end

    input
  end
end
