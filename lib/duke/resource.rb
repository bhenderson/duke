require 'rack/routes'
require 'rack/request'
require 'rack/response'

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
    [:Request, :Response].each do |const|
      mod = Duke.constants.include?(const) ? Duke : Rack
      # Public: see mod::const
      const_set const, mod.const_get const
    end

    # GET '/users' HTTP/1.1
    # Accepts: */*
    # Accepts: application/duke;vers=1.1,format=json
    #
    # if not specified, return json
    # if specified as "*" or "json", return json
    # if specified as something else, try and return that, otherwise, 406 (Not
    # Acceptable)
    accepts_type 'application', true
    accepts_subtype 'duke', true
    accepts_format :json, true
    accepts_version '>= 0'

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
      # Returns nothing.
      def route verb, path, action
        Rack::Routes.location path, new(verb, action)
      end
    end

    # Public: Initialize a Resource.
    #
    # app    - An app to call if verb or action doesn't match. (default: nil)
    # verb   - A String to match exactly with the HTTP request verb.
    # action - A String or Symbol which must correlate to a public_instance_method
    def initialize app = nil, verb, action
      @app    = app
      @action = action
      @verb   = verb
    end

    def index
      [
        { 'user' => '/users/1' },
      ]
    end
  end
end
