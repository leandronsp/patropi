class Evaluators::Print 
  def self.evaluate(*args) = new(*args).evaluate

  def initialize(data, scope, terms, executors)
    @data = data
    @scope = scope
    @terms = terms
    @executors = executors
  end

  def evaluate
    @executors.push(executor)
    @terms.push(@data[:value])

    [:noop, nil, @scope, @data[:location]]
  end

  private

  def executor
    -> (result) { 
      begin
        print "#{result}\n"
        [:raw, result, @scope, @data[:location]]
      rescue => e
        raise Error.new(@data[:location], "Cannot print #{result}: #{e.message}")
      end
    }
  end
end
