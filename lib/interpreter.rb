require 'json'

class Interpreter 
  def self.run = new.run

  def run
    input = read_stdin
    parsed = JSON.parse(input, symbolize_names: true)

    evaluate(parsed[:expression])
  end

  private

  def evaluate(term)
    puts term
  end

  def read_stdin
    input = ""

    while line = STDIN.gets
      input += line
    end

    input
  end
end
