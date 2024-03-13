# frozen_string_literal: true

module Ebayr # :nodoc:
  # A response to an Ebayr::Request.
  class Response < Record
    def initialize(request, response)
      @request = request
      @command = @request.command if @request
      @response = response
      @body = response.body if @response
      hash = self.class.from_xml(@body, @request.config) if @body
      response_data = hash["#{@command}Response"] if hash
      super(response_data) if response_data
    end

    def to_struct(struct_name)
      Struct.new(struct_name, *keys).new(*values)
    end

    class << self
      def from_xml(xml_io, config = Ebayr::Configuration.default)
        result = LibXML::XML::Parser.io(StringIO.new(xml_io))
        result = result.parse
        return { result.root.name => xml_node_to_hash(result.root, config) }
      end

      def xml_node_to_hash(node, config)
        # If we are at the root of the document, start the hash
        return prepare(node.content.to_s, config) unless node.element?

        result_hash = {}
        if node.attributes.length.positive?
          result_hash[:attributes] = {}
          node.attributes.each do |key|
            result_hash[:attributes][key.name.to_sym] = prepare(key.value, config)
          end
        end

        return result_hash unless node.children.size.positive?

        node.children.each do |child|
          result = xml_node_to_hash(child, config)

          if child.name == 'text'
            unless child.next || child.prev
              return prepare(result, config) unless result_hash[:attributes]

              # this helps us add attributes into the result hash (e.g. currency of an amount)
              result_hash['value'] = prepare(result, config)
              return result_hash
            end
          elsif result_hash[child.name.to_sym]
            if result_hash[child.name.to_sym].is_a?(Object::Array)
              result_hash[child.name.to_sym] << prepare(result, config)
            else
              result_hash[child.name.to_sym] = [result_hash[child.name.to_sym]] << prepare(result, config)
            end
          else
            result_hash[child.name.to_sym] = prepare(result, config)
          end
        end

        return result_hash
      end

      def prepare(data, config)
        return data unless config.convert_integers

        data.instance_of?(String) && data.to_i.to_s == data ? data.to_i : data
      end
    end
  end
end
