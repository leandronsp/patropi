require 'json'

class Interpreter 
  def self.run(*args) = new.run(*args)

  def run(json_input)
    parsed = JSON.parse(json_input, symbolize_names: true)

    evaluate(parsed[:expression])
  end

  def evaluate(term, scope = {})
    case term
    in { kind: 'Print', value: value }; puts evaluate(value, scope)
    in { kind: 'Int', value: value }; value.to_i
    in { kind: 'Str', value: value }; value.to_s
    in { kind: 'Bool', value: value }; value
    in { kind: 'Binary', op: op, lhs: lhs, rhs: rhs }
      operation = { 'Add' => '+', 'Sub' => '-', 'Eq' => '==', 'Lt' => '<' }[op]

      left = evaluate(lhs, scope)
      right = evaluate(rhs, scope)

      case [left, right]
      in [Integer, Integer]; left.send(operation.to_sym, right) 
      else "#{left}#{right}"
      end
    in { kind: 'Var', text: text }; scope[text]
    in { kind: 'Let', name: { text: text }, value: value, next: next_ }
      scope[text] = evaluate(value, scope)
      evaluate(next_, scope)
    in { kind: 'Function', parameters: parameters, value: value }
      ->(*args) do 
        params = parameters.map { |param| param[:text] }
        arguments = params.zip(args).to_h

        evaluate(value, scope.merge(arguments))
      end
    in { kind: 'Call', callee: callee, arguments: arguments }
      args = arguments.map { |arg| evaluate(arg, scope) }
      function = evaluate(callee, scope)
      function.(*args)
    in { kind: 'If', condition: condition, then: then_, otherwise: otherwise }
      if evaluate(condition, scope)
        evaluate(then_, scope)
      else 
        evaluate(otherwise, scope)
      end
    else 
      puts "Invalid term #{term}"
    end
  end
end
