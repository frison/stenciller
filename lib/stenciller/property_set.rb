module Stenciller
  class PropertySet
    def initialize(property, *args)
      default_options = {:exclusion_text => ""}
      options = args.flatten.last.is_a?(::Hash) ? args.flatten.pop : {}


      @options = default_options.merge(options)
      @property = property
      @exclusions = options[:exclusions] || []
    end

    def get(element)
      get_from_exclusions(element) || \
      get_from_hash(element) || \
      get_from_method(element) || \
      get_from_method(element, true) || \
      @options[:default]
    end

    private
    def get_from_hash(element)
      begin
        value = @property[element] || @property[element.to_sym]
      rescue
      end
      value
    end

    def get_from_method(element, force=false)
      begin
        value = @property.send(element.to_sym) if force or @property.respond_to?(element.to_sym)
      rescue
      end
      value
    end

    # If it's excluded make sure the user knows
    def get_from_exclusions(element)
      if @exclusions.include?(element.to_s) || @exclusions.include?(element.to_sym)
        @options[:exclusion_text]
      end
    end
  end
end
