# frozen_string_literal: true

module Ebayr
  module TestHelper
    @success = Ebayr.xml(Ack: 'Success')

    def self.included(_mod)
      require 'webmock' unless const_defined?(:WebMock)
    rescue LoadError
      throw "Couldn't load webmock! Is it in your Gemfile?"
    end
  end
end
