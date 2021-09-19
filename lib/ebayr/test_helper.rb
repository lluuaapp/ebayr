# frozen_string_literal: true

module Ebayr
  module TestHelper
    @@success = Ebayr.xml(Ack: 'Success')

    def self.included(_mod)
      require 'fakeweb' unless const_defined?(:FakeWeb)
    rescue LoadError
      throw "Couldn't load fakeweb! Is it in your Gemfile?"
    end

    # Allows you to stub out the calls within the given block. For example:
    #
    #   def test_something
    #     stub_ebay_call!(:GeteBayOffficialTime, :Timestamp => "Yo") do
    #       assert Ebayr.call(:GeteBayOfficialTime) # => stubbed call
    #     end
    #   end
    #
    # This method is deprecated, and will be removed in a future release.
    def stub_ebay_call!(call, content)
      puts <<~DEPRECATION
        stub_ebay_call! is deprecated, and will be removed in a future release. Please
        use Ruby techniques to stub eBay calls your way. See the wiki for details.
      DEPRECATION
      content = Ebayr.xml(content) unless content.is_a?(String)
      allow_net_connect = FakeWeb.allow_net_connect?
      FakeWeb.allow_net_connect = false
      body = <<-XML
        <#{call}Response>
          #{Ebayr.xml(Ack: 'Success')}
          #{content}
        </#{call}Response>
      XML
      FakeWeb.register_uri(:any, Ebayr.uri, body: body)
      yield
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = allow_net_connect
    end
  end
end
