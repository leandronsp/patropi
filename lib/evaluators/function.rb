class Evaluators::Function 
  def self.evaluate(*args) = new(*args).evaluate

  def initialize(data, scope, terms, executors)
    @data = data
    @scope = scope
    @terms = terms
    @executors = executors
  end

  def evaluate
    parameters, value, location = @data.values_at(:parameters, :value, :location)

    func = -> (*args) { 
      new_scope = @scope.dup

      parameters.each_with_index do |param, index|
        new_scope[param[:text]] = args[index]
      end

      @scope = new_scope
      @terms.push(value)

      [:noop, nil, new_scope, location]
    }

    @executors.pop.call(func)
    [:noop, nil, @scope, location]
  end
end
