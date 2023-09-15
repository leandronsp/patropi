require 'json'

class Interpreter 
  def self.run(*args) = new.run(*args)

  def run(json_input)
    parsed = JSON.parse(json_input, symbolize_names: true)

    evaluate(parsed[:expression])
  end

  def evaluate(term)
    case term
    in { kind: 'Print', value: value }; puts evaluate(value)
    in { kind: 'Int', value: value }; value.to_i
    in { kind: 'Str', value: value }; value.to_s
    else 
      puts "Invalid term #{term}"
    end
  end
end
