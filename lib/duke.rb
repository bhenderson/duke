module Duke
  VERSION = '0.1.0'

  # Public: Rack interface
  #
  # Passes to Rack::Routes
  def self.call env
    Rack::Routes.new.call(env)
  end

end
