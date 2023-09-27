class Evaluators::Binary 
  def self.evaluate(*args) = new(*args).evaluate

  def initialize(data, scope, terms, executors)
    @data = data
    @scope = scope
    @terms = terms
    @executors = executors
  end

  def evaluate
    op, lhs, rhs, location = @data.values_at(:op, :lhs, :rhs, :location)

    @terms.push(rhs, lhs)

    @executors.push(-> (left) { 
      @executors.push(-> (right) { 
        [:raw, evaluate_binary_op(op, left, right, location), @scope, location]
      })

      [:noop, nil, @scope, location]
    })

    [:noop, nil, @scope, location]
  end

  private

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
