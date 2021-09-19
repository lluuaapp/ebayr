# frozen_string_literal: true

module Ebayr
  class Record < Hash
    def initialize(initial = {})
      super()
      initial.each { |k, v| self[k] = v }
    end

    def <=>(other)
      return false unless other.respond_to(:keys) && other.respond_to(:"[]")

      other.each_key do |k|
        return false unless convert_value(other[k]) == self[k]
      end
      true
    end

    def [](key)
      super(convert_key(key))
    end

    def []=(key, value)
      key = convert_key(key)
      value = convert_value(value)
      (class << self; self; end).send(:define_method, key) { value }
      super(key, value)
    end

    def key?(key)
      super(convert_key(key))
    end

    class << self
      def convert_key(key)
        key.to_s.underscore.gsub(/e_bay/, 'ebay').to_sym
      end

      def convert_value(arg)
        case arg
        when Hash then Record.new(arg)
        when Array then arg.map { |a| convert_value(a) }
        else arg
        end
      end
    end

    protected

      def convert_key(key)
        self.class.convert_key(key)
      end

      def convert_value(arg)
        self.class.convert_value(arg)
      end
  end
end
