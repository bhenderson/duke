require 'rack/response'

module Duke
  class Response < Rack::Response
    # Public: Writes +resp+ to the current response object
    #
    # This method duplicates the code in Rack::Response#initialize
    # 
    # Example
    #
    #   response.write_resp '3'
    #   # Same as response.write '3'
    #
    #   response.write_resp ['3']
    #   # similar to response.body = ['3']
    #
    # Returns response.body
    def write_body body
      if body.respond_to? :to_str
        write body.to_str
      elsif body.respond_to?(:each)
        body.each { |part|
          write part.to_s
        }
      else
        raise TypeError, "stringable or iterable required"
      end
    end
  end
end
