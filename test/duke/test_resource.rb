require 'helper'

class TestDuke::TestResource < DukeTestCase
  def setup
    @klass = Duke::Resource
    Rack::Routes.locations.clear
  end

  def test_call_dups
    klass = Class.new(@klass) do
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
    klass = Class.new(@klass) do
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

    assert_equal 1, Rack::Routes.locations[:exact].size
  end

  def test_call_returns_valid_rack_response
    Class.new(@klass) do
      get '/path', :index
      def index() [123,{},['3']] end
    end

    get '/path'
    assert_equal 123, last_response.status
    assert_equal '3', last_response.body
  end

  def test_multiple_gets
    Class.new(@klass) do
      get '/path1', :path1
      get '/path2', :path2
      get '/path3', :path3
      def path1() 'hi1' end
      def path2() 'hi2' end
      def path3() 'hi3' end
    end

    get '/path1'
    assert_equal 'hi1', last_response.body

    get '/path2'
    assert_equal 'hi2', last_response.body

    get '/path3'
    assert_equal 'hi3', last_response.body
  end

  def test_404
    Class.new(@klass) do
      get '/path', :path
    end

    #get '/no_path'
    #assert_equal 404, last_response.status
  end

  def test_default_to_exact_matching
    Class.new(@klass) do
      get '/path', :path
      def path() 'my path' end
    end

    #get '/path_extra'
    #assert_equal 404, last_response.status

    get '/path'
    assert_equal 'my path', last_response.body
  end

  def test_adding_middleware
    Class.new(@klass) do
      app = Class.new do
        def initialize(app) @app = app end
        def call(env)
          env['test.adding.middleware'] = 'hello'
          @app.call(env)
        end
      end
      use app

      get '/path', :path
      def path()
        env['test.adding.middleware'] + ' world'
      end
    end

    get '/path'
    assert_equal 'hello world', last_response.body
  end
end
