require 'test/unit'
require 'lib/pavatar'
require 'rubygems'
require 'fakeweb'

class PavatarTest < Test::Unit::TestCase

  OK_PNG_URL = 'http://example.com/good_pavatar.png'
  ALL_OK_METHODS_EXAMPLE_COM = <<EOB
  <html><head><link rel="pavatar" href="#{OK_PNG_URL}"/></head><body><p>42*Piou.</p></body></html> 
EOB

  def setup
    WebFaker.setup
  end

  def test_url_assignation
    assert_nil   Pavatar::Consumer.get_pavatar('/header.example.com').url, 'Invalid URL should be converted to nil'
    assert_equal '/', Pavatar::Consumer.get_pavatar('http://header.example.com').url.path, 'Valid URL with no path must return / as path'
  end

  def test_autodiscover
    assert_equal OK_PNG_URL, Pavatar::Consumer.get_pavatar('http://header.example.com').image_url.to_s, 'Valid URL with valid URL in X-Pavatar header must be recognize'
  end
end

class WebFaker

  class << self
    def setup
      @conf_done ||= begin
        FakeWeb.register_uri(:any, "http://header.example.com/", :body => PavatarTest::ALL_OK_METHODS_EXAMPLE_COM, "X-Pavatar" => 'http://example.com/good_pavatar.png' )
        FakeWeb.allow_net_connect = false
        true
      end
    end
  end

end
