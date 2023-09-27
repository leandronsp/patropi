class Evaluators::Call 
  def self.evaluate(*args) = new(*args).evaluate

  def initialize(data, scope, terms, executors)
    @data = data
    @scope = scope
    @terms = terms
    @executors = executors
  end

  def evaluate
    callee, arguments, location = @data.values_at(:callee, :arguments, :location)

    args = arguments.map do |arg|
      case arg
      in { kind: 'Binary', **binary_data }
        left = evaluate(binary[:lhs], @scope, binary_data[:location])[1]
        right = evaluate(binary[:rhs], @scope, binary_data[:location])[1]

        evaluate_binary_op(binary_data[:op], left, right, binary_data[:location])
      in { kind: 'Function', **function_data }
        parameters = function_data[:parameters]
        value = function_data[:value]

        -> (*args) { 
          new_scope = @scope.dup

          parameters.each_with_index do |param, index|
            new_scope[param[:text]] = args[index]
          end

          @scope = new_scope
          @terms.push(value)

          [:noop, nil, new_scope, function_data[:location]]
        }
      else evaluate(arg, @scope, location)[1]
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
    [:noop, nil, @scope, location]
  end
end
