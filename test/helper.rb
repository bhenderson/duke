require 'minitest/autorun'

require 'duke'
require 'duke/resource'
require 'rack/test'

class DukeTestCase < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Rack::Routes
  end
end
class TestDuke < DukeTestCase; end
