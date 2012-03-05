require 'rack/routes'
require 'duke/request'
require 'duke/response'

module Duke
  # Public: Class to describe a "hypermedia" object. Subclass this Class to
  #   describe new resources
  #
  # A Hypermedia object should have one URI which responds to different HTTP
  #   verbs and versions (spedified by the HTTP header +Accepts+)
  #
  # Examples
  #
  #   class Users < Duke::Resource
  #
  #     #GET     /users     # index
  #     #GET     /users/:id # show
  #     #PUT     /users/:id # create
  #     #POST    /users/:id # update
  #     #DELETE  /users/:id # destroy
  #   end
  class Resource
    class Request < Duke::Request; end
    class Response < Duke::Response; end

    # GET '/users' HTTP/1.1
    # Accepts: */*
    # Accepts: application/duke;vers=1.1,format=json
    #
    # if not specified, return json
    # if specified as "*" or "json", return json
    # if specified as something else, try and return that, otherwise, 406 (Not
    # Acceptable)
    #accepts_type 'application', true
    #accepts_subtype 'duke', true
    #accepts_format :json, true
    #accepts_version '>= 0'

    class << self

      # Public: rack interface
      #
      # Returns rack response
      def call(env)
        new.call(env)
      end

      # Public: Defines a DELETE route
      def delete(*a)  route 'DELETE', *a end

      # Public: Defines a GET route
      def get(*a)     route 'GET', *a end

      # Public: Defines a OPTIONS route
      def options(*a) route 'OPTIONS', *a end

      # Public: Defines a POST route
      def post(*a)    route 'POST', *a end

      # Public: Defines a PUT route
      def put(*a)     route 'PUT', *a end

      # Public: Define a new route for this resource.
      #   Only one path can be defined globally.
      #   Each path can have multiple verbs.
      #   Each path/verb pair can have only one action.
      # Changes the default behavior of Rack::Routes to use exact matching by
      #   default. Pass :exact => false to match beginning of the path.
      #
      # verb   - A String (see #initialize).
      # path   - The path to match on for this particular verb/action pair.
      #          (see Duke::location).
      # action - A String or Symbol (see #initialize).
      #
      # Returns nothing
      def route verb, path, action
        r_path = routes[path]

        # defining multiple verbs will have no effect
        Rack::Routes.location path, {:exact => true}, self.new(nil, path) if r_path.empty?

        r_path[verb] = action
        nil
      end

      # Private: Hash of routes that have been defined for this resource
      #
      # Examples
      #
      #   routes[path][verb] = action
      def routes
        @routes ||= Hash.new{|h,k| h[k]={}}
      end

      def use middleware, *args, &blk
        middlewares << [middleware, *args, blk]
      end

      def middlewares
        @middlewares ||= []
      end
    end

    # Public: Returns the action for the current call.
    attr_reader :action

    # Public: Returns the response object for the current call.
    attr_reader :response

    # Public: Returns the request object for the current call.
    attr_reader :request

    # Public: Initialize a Resource.
    #
    # app    - An app to call if verb or action doesn't match. (default: nil)
    # path   - Private: The path for this resource. This doesn't have any
    #            meaning for the request as it probably will differ from the actual
    #            request path.
    def initialize app = nil, path = nil
      @app = app
      @__path = path
    end

    # Public: Rack interface.
    def call(env)
      app = self.class.middlewares.reverse.
              inject(dup){|app, (m,a,b)| m.new(app, *a,&b)}
      app.call! env
    end

    # Private: Used for actual call method on dup'd object.
    def call! env
      @env = env
      @request = Request.new(@env)
      @response = Response.new

      @action = matching_action

      response.write_body invoke

      response.finish
    end

    # Public: Merge or return current response headers.
    #
    # opts - A hash of response headers
    def headers opts={}
      response.headers.merge! opts
    end

    # Public: Calls the current action.
    #
    # Returns the response body
    def invoke
      status 200 # set default status
      resp = __send__ @action
      if Array === resp and resp.size == 3
        st, hd, resp = resp
        status st
        headers hd
      end
      resp
    end

    # Private: The action to perform for this request.
    #
    # Returns a Symbol that should be a valid instance method. Defaults to method_not_allowed.
    def matching_action
      self.class.routes[@__path][request.request_method] || :method_not_allowed
    end

    # Private: Set and return appropriate values for HTTP status 405 (Method not allowed)
    def method_not_allowed
      status 405
      "method not allowed"
    end

    # Public: Set or return the response status for the current response.
    #
    # num - An Integer to set the response status. (default: nil)
    def status num = nil
      return response.status unless num
      response.status = num.to_i
    end
  end
end
