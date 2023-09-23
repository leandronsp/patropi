class Array
  def to_s = "(#{self[0]}, #{self[1]})"
end

class Proc
  def to_s = "<#closure>"
end
