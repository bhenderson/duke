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
      #
      # verb   - A String (see #initialize).
      # path   - The path to match on for this particular verb/action pair.
      #          (see Duke::location).
      # action - A String or Symbol (see #initialize).
      #
      # Returns new app.
      def route verb, path, action
        routes[verb] = action
        Rack::Routes.location path, new
      end

      def routes
        @routes ||= Hash.new
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
    # verb   - A String to match exactly with the HTTP request verb.
    # action - A String or Symbol which must correlate to a public_instance_method
    def initialize app = nil
      @app = app
    end

    # Public: Rack interface.
    def call(env)
      dup.call! env
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

    # Private: Calls the current action, handling any errors
    #
    # Returns a response body
    def invoke
      unless @action
        status 405
        return "method not allowed"
      end

      begin
        status 200
        resp = __send__ @action
        if Array === resp and resp.size == 3
          st, hd, bd = resp
          status st
          headers hd
          resp
        else
          resp
        end
      rescue ::Exception => e
        status 500
        e.message
      end
    end

    # Private: Returns the appropriate action for the current HTTP verb
    def matching_action
      self.class.routes[request.request_method]
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
