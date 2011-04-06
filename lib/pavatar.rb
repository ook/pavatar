require 'net/http'

module Pavatar
  SPEC_VERSION = '0.3.0'
  SPEC_URL     = 'http://pavatar.com/spec/'

  class Exception < ::Exception
     attr_accessor :pavatar
     def initialize(pavatar)
       self.pavatar = pavatar
     end
  end

  class Refused < Exception
    def message
      'URL explicitly refused Pavatar (spec 2.b.)'
    end
  end

  class BadUrl < Exception
    def message
      "Given URL is not an absolute URL (given: #{pavatar.url.inspect}, waiting url like: http://my.site.com/ )"
    end
  end

  class Consumer
    attr_accessor :exceptions
    attr_accessor :debug

    class << self
      def get_pavatar(url, options = {})
        # initialize instance
        pavatar = new
        pavatar.debug = !!options[:debug]
        pavatar.exceptions = []

        # setting up
        pavatar.url = url   

        # fetching
        pavatar.autodiscover
        pavatar
      end
    end

    def url=(url)
      @url = URI.parse(url)

      if !@url.is_a?(URI::HTTP)
        @exceptions << BadUrl.new(self)
        @url = nil
      else
        @url.path = '/' if '' == @url.path
      end

      @url
    end

    def url
      @url
    end

    # Validate as describe in Spec 2.a. Technical definition   
    def strictly_valid?
      valid_weight? && valid_dimensions? && valid_content_type?
    end
    alias :valid? :strictly_valid?

    # Validate as describe in Spec 2.a. Technical definition   
    def valid_weight?
    end
    
    # Validate as describe in Spec 2.a. Technical definition   
    def valid_dimensions?
    end

    # Validate as describe in Spec 2.a. Technical definition   
    def valid_url?
    end

    # Validate as describe in Spec 2.a. Technical definition   
    def valid_content_type?
    end

    def autodiscover
      return nil unless valid?
      response = Net::HTTP.start(@url.host) { |http| http.head(@url.path) }
      response['X-Pavatar']
    end
  end
end
