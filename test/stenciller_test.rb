require File.dirname(__FILE__) + '/test_helper'
require 'ostruct'

class String
  def ends_with?(s)
    self[-1..-1] == s
  end
end

# This is to take care of those annoying classes where people do crazy things
# and respond_to? doesn't "really" work, because they forgot to implement a
# proper version of it.
class Annoying
  def initialize
    @attribute_cache = {}
  end

  def method_missing(method_id, *args, &block)
    method_id = method_id.to_s
    if method_id.ends_with?("=")
      @attribute_cache[method_id[0..-2]] = args[0]
    else
      @attribute_cache[method_id]
    end
  end
end

# To test if the caching is working.
class Mutator
  def initialize(value)
    @value = value
  end
  def value
    old = @value
    @value = @value[1..-1] + @value[0..0]
    old
  end
end


class StencillerTest < Test::Unit::TestCase
  # Replace this with your real tests.
  def test_can_instantiate
    builder = Stenciller::Builder.new
    assert !builder.nil?
  end

  def test_can_add_property_sets
    builder = builder_for_simple_tests

    property_sets = builder.send(:instance_variable_get, :@property_sets)

    assert property_sets.count == 4
    assert property_sets[0].get('first') == 'obama'
  end

  def test_can_update_a_string
    builder = builder_for_simple_tests

    assert builder.draw("This is a test") == "This is a test"
    assert builder.draw("This is {{house}}") == "This is Edmonton"
    assert builder.draw("This is {{animal}}") == "This is deer"
    assert builder.draw("This is {{first}}") == "This is obama"
    assert builder.draw("This is {{happy_feet}}") == "This is happy_feet"
  end

  def test_can_update_multiple_parts_of_a_string
    builder = builder_for_medium_tests

    assert builder.draw("Please override me {{first_time}}") == "Please override me Overridden"
    assert builder.draw("Please override me {{second_time}}") == "Please override me Overridden2"

    assert builder.draw("{{second}}, {{third}}, {{foo}}") == "Keep me, Keep me, Default Value"
  end

  def test_can_update_multilines_and_annoying_instances
    builder = builder_for_hard_tests

    assert builder.draw( <<-END
This is a test to see if {{name}}
Can be found at the right {{location}}

Thanks
{{prefix}} Bond, {{designation}}
{{date}}
    END
    ) == <<-END
This is a test to see if Annoying
Can be found at the right Stage 1

Thanks
Dr. Bond, CEO
Today
    END

  end

  def test_cache_works_property
    builder = builder_for_hard_tests
    assert builder.draw("{{value}} {{value}}") == "mississippi mississippi"    
  end


  def test_exclusion_list_works_propertly
    builder = Stenciller::Builder.new
    builder.add_property_set(OpenStruct.new({:non_restricted => "ok", :restricted => "not_show_up"}), :exclusions => [:restricted])

    assert builder.draw("{{non_restricted}}") == "ok"
    assert builder.draw("{{restricted}}") != "not_show_up"
  end

  private
  def builder_for_simple_tests
    builder = Stenciller::Builder.new

    builder.add_property_set({:house => "Edmonton"})
    builder.add_property_set(OpenStruct.new({:animal => "deer", :food => "chicken"}))
    builder.prepend_property_set(OpenStruct.new({:first => 'obama'}))
    builder.append_property_set({:default => "Sky Walker"})

    return builder
  end

  def builder_for_medium_tests
    builder = Stenciller::Builder.new

    builder.add_property_set({:first_time => "Override me", :second => "Keep me"})
    builder.add_property_set({:second_time => "Override me", :third => "Keep me"})
    builder.prepend_property_set(OpenStruct.new({:first_time => "Overridden", :second_time => "Overridden2"}))

    # Make sure this is at the end or it will eat up everything!
    builder.append_property_set(nil, {:default => "Default Value"})

    builder
  end

  def builder_for_hard_tests
    builder = Stenciller::Builder.new

    annoying_object = Annoying.new
    annoying_object.name = "Annoying"
    annoying_object.location = "Stage 2"

    builder.add_property_set(annoying_object)
    builder.add_property_set({:name => "Newsletter", :date => Time.now.to_s})
    builder.prepend_property_set(OpenStruct.new({:location => "Stage 1", :date => "Today"}))
    builder.add_property_set({:designation => "CEO", :prefix => "Dr."})
    builder.add_property_set(Mutator.new("mississippi"))

    builder
  end
end
