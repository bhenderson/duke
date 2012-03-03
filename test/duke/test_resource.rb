require 'helper'

class TestDuke::TestResource < DukeTestCase
  def setup
    app.locations.clear
  end

  def test_call_dups
    klass = Class.new(Duke::Resource) do
      get '/path', :foo
      def bar() @bar end
      def foo() @bar = '3' end
    end

    obj = klass.new
    get '/path'

    assert_equal '3', last_response.body
    refute obj.bar
  end

  def test_wrong_verb_returns_405
    klass = Class.new(Duke::Resource) do
      get '/path', :index
      post '/path', :update
      def index() 'foo' end
      def update() 'bar' end
    end

    get '/path'
    assert_equal 'foo', last_response.body

    post '/path'
    assert_equal 'bar', last_response.body

    delete '/path'
    assert_equal 405, last_response.status
  end

  def test_call_returns_valid_rack_response
    Class.new(Duke::Resource) do
      get '/path', :index
      def index() [123,{},['3']] end
    end

    get '/path'
    assert_equal 123, last_response.status
    assert_equal '3', last_response.body
  end
end
