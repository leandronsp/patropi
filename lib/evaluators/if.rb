class Evaluators::If 
  def self.evaluate(*args) = new(*args).evaluate

  def initialize(data, scope, terms, executors)
    @data = data
    @scope = scope
    @terms = terms
    @executors = executors
  end

  def evaluate
    condition, then_term, otherwise_term, location = @data
      .values_at(:condition, :then, :otherwise, :location)

    @executors.push(-> (result) { 
      result ? @terms.push(then_term) : @terms.push(otherwise_term)
      [:noop, nil, @scope, location]
    })

    @terms.push(condition)
    [:noop, nil, @scope, location]
  end
end
