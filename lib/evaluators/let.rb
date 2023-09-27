class Evaluators::Let 
  def self.evaluate(*args) = new(*args).evaluate

  def initialize(data, scope, terms, executors)
    @data = data
    @scope = scope
    @terms = terms
    @executors = executors
  end

  def evaluate
    text = @data.dig(:name, :text)
    value, next_term, location = @data.values_at(:value, :next, :location)

    @executors.push(-> (result) { 
      @scope[text] = result
      @terms.push(next_term)
      [:noop, nil, @scope, location]
    })

    @terms.push(value)
    [:noop, nil, @scope, location]
  end
end
