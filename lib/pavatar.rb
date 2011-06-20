require 'net/http'
require 'rubygems'
require 'hpricot'

module Pavatar
  SPEC_VERSION = '0.3.0'
  SPEC_URL     = 'http://pavatar.com/spec/'

  # Order honors specifications
  AUTODISCOVER_METHOD = ['http_header', 'link_element', 'direct_url']

  class Exception < ::Exception
     attr_accessor :pavatar
     def initialize(pavatar)
       self.pavatar = pavatar
     end

     def to_s
       message
     end
  end

  class Refused < Exception
    def message
      "URL explicitly refused Pavatar (spec 2.b.) when autodiscovering via #{discover_method} on given #{pavatar.url.inspect}"
    end
  end

  class BadUrl < Exception
    def message
      "Given URL is not an absolute URL (given: #{pavatar.url.inspect}, waiting url like: http://my.site.com/ )"
    end
  end

  class NoPavatar < Exception
    def message
      "No Pavatar was found on the given URL (#{pavatar.url.inspect})"
    end
  end


  class Consumer
    attr_accessor :exceptions
    attr_accessor :debug
    attr_accessor :discover_method

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

    def image_url=(url)
      return (@image_url = nil) if url.nil?
      return (@image_url = 'none') if /^none$/i.match(url)

      @image_url = URI.parse(url) rescue nil

      if !@image_url.is_a?(URI::HTTP)
        @exceptions << BadUrl.new(self)
        @image_url = nil
      else
        @image_url.path = '/' if '' == @image_url.path
      end

      @image_url
    end

    def image_url
      @image_url
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
      true
    end

    # Validate as describe in Spec 2.a. Technical definition   
    def valid_content_type?
    end

    def autodiscover_http_header
      @response = Net::HTTP.start(@url.host) { |http| http.head(@url.path) }
      if '200' == @response.code
        self.image_url = @response['X-Pavatar']
        if 'none' == self.image_url
          self.image_url = nil
          @exceptions << Refused.new(self)
          @autodiscover_blocked = true
        else
          @autodiscover_blocked = true if self.image_url
        end  
      end
    end

    def autodiscover_link_element
      @response = Net::HTTP.start(@url.host) { |http| http.get(@url.path) }
      if '200' ==  @response.code
        doc = Hpricot(@response.body)
        pavatar_link = (doc/'link[@rel="pavatar"]')
        pavatar_href = pavatar_link.attr('href') unless pavatar_link.empty?
        if 'none' == pavatar_href
          @exceptions << Refused.new(self)
          self.image_url = nil
          @autodiscover_blocked = true
        else
          self.image_url = pavatar_href
          @autodiscover_blocked = true # Can't ensure the image_url is valid without a HEAD request, so we delegate that for later
        end
      end
    end

    def autodiscover_direct_url
      @url.path = '/pavatar.png'
      @response = Net::HTTP.start(@url.host) { |http| http.head(@url.path) }
      case @response.code
      when '200'
        self.image_url = @url.to_s
        @autodiscover_blocked = true
      end
    end

    def autodiscover
      return nil unless @exceptions.empty?
      @autodiscover_blocked = false
      AUTODISCOVER_METHOD.each do |meth| 
        @discover_method = meth 
        send("autodiscover_#{meth}") 
        break if @autodiscover_blocked
      end
      @exceptions << NoPavatar.new(self) unless self.image_url
      self.image_url
    end
  end
end
