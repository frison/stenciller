module Stenciller


  # A builder for template substitution
  class Builder

    MATCH = /(\\\\)?\{\{([^\}]+)\}\}/

    def initialize(*args)
      @property_sets = []
      @cache = {}
    end

    def prepend_property_set(property, *args)
      @property_sets.unshift Stenciller::PropertySet.new(property, args)
    end

    def append_property_set(property, *args)
      @property_sets << Stenciller::PropertySet.new(property, args)
    end
    alias_method :add_property_set, :append_property_set

    def result_for(text, *args)
      return text.map { |k| result_for(k, args) } if text.is_a? Array

      entry = interpolate(text, args)
      entry
    end
    alias_method :draw, :result_for


    private

    def lookup(key)
      return @cache[key] if @cache.has_key?(key)
      @property_sets.each do |property_set|
        value = property_set.get(key)
        return @cache[key] = value if value
      end

      nil
    end


    # Interpolates values into a given string.
    #
    #   interpolate "file {{file}} opened by \\{{user}}", :file => 'test.txt', :user => 'Mr. X'
    #   # => "file test.txt opened by {{user}}"
    #
    # Note that you have to double escape the <tt>\\</tt> when you want to escape
    # the <tt>{{...}}</tt> key in a string (once for the string and once for the
    # interpolation).
    #
    # Note that when a value is not found in the options map, it will be looked for by using
    # the +@property_sets+ array, starting with the lowest index first.
    def interpolate(text, *args)
      return text unless text.is_a?(String)

      values = args.last.is_a?(::Hash) ? args.pop : {}

      text.gsub(MATCH) do
        escaped, pattern, key = $1, $2, $2.to_sym

        if escaped
          pattern
        elsif values.include?(key)
          values[key]
        elsif v = lookup(key)
          v
        else
          key.to_s
        end
      end
    end
  end

end
