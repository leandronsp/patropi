class Error < StandardError
  def initialize(location, message)
    @location = location
    @message = message

    if location
      super("Error: #{message} at #{location[:filename]}:#{location[:start]}:#{location[:end]}")
    else 
      super("Error: #{message}")
    end
  end
end
