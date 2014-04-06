module Pipeline::Tasks::MSDeploySupport
  class Mapper
    class << self
      def map(args = {})
        args.map { |key, value|
          value = [value] unless value.kind_of?(Array)

          value.map do |val|
            map_key(key, val)
          end
        }.flatten.reject(&:nil?)
      end

      def quote(value)
        value = value.gsub(/"/, '""') if value.kind_of?(String)
        return %Q{"#{value}"} if value =~ /\s/
        value
      end

      private
      def map_key(key, value)
        if value.kind_of?(Enumerable)
          value = value.map { |k, v|
            map_nested(k, v)
          }.reject(&:nil?).join(',')
        else
          value = camel_case(value)
        end

        map_top_level(key, value)
      end

      def map_top_level(key, value)
        return nil unless value
        return nil if value.to_s.strip.length == 0

        prefix, separator, value = omit_true(value)

        "#{prefix}#{camel_case(key)}#{separator}#{value}"
      end

      def map_nested(key, value)
        return nil if value.nil?

        "#{camel_case(key)}=#{camel_case(value)}"
      end

      def omit_true(value)
        prefix = '-'
        separator = ':'

        return [prefix, separator, value] unless value.kind_of?(TrueClass)
        prefix
      end

      def camel_case(value)
        return quote(value) unless value.kind_of?(Symbol)
        value.camelize
      end
    end
  end
end
