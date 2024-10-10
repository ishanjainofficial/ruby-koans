require File.expand_path(File.dirname(__FILE__) + '/neo')

class Proxy
  def initialize(target_object)
    @object = target_object
    @messages = []
    @method_call_count = Hash.new(0)
  end

  def messages
    @messages
  end

  def called?(method_name)
    @method_call_count.key?(method_name)
  end

  def number_of_times_called(method_name)
    @method_call_count[method_name]
  end

  def method_missing(method_name, *args, &block)
    @messages << method_name
    @method_call_count[method_name] += 1
    @object.send(method_name, *args, &block)
  end

  def respond_to_missing?(method_name, include_private = false)
    @object.respond_to?(method_name, include_private) || super
  end
end

class AboutProxyObjectProject < Neo::Koan
  def test_proxy_method_returns_wrapped_object
    tv = Proxy.new(Television.new)
    assert tv.instance_of?(Proxy)
  end

  def test_tv_methods_still_perform_their_function
    tv = Proxy.new(Television.new)

    tv.channel = 10
    tv.power

    assert_equal 10, tv.channel
    assert tv.on?
  end

  def test_proxy_records_messages_sent_to_tv
    tv = Proxy.new(Television.new)

    tv.power
    tv.channel = 10

    assert_equal [:power, :channel=], tv.messages
  end

  def test_proxy_handles_invalid_messages
    tv = Proxy.new(Television.new)

    assert_raise(NoMethodError) do
      tv.no_such_method
    end
  end

  def test_proxy_reports_methods_have_been_called
    tv = Proxy.new(Television.new)

    tv.power
    tv.power

    assert tv.called?(:power)
    assert ! tv.called?(:channel)
  end

  def test_proxy_counts_method_calls
    tv = Proxy.new(Television.new)

    tv.power
    tv.channel = 48
    tv.power

    assert_equal 2, tv.number_of_times_called(:power)
    assert_equal 1, tv.number_of_times_called(:channel=)
    assert_equal 0, tv.number_of_times_called(:on?)
  end

  def test_proxy_can_record_more_than_just_tv_objects
    proxy = Proxy.new("Code Mash 2009")

    proxy.upcase!
    result = proxy.split

    assert_equal ["CODE", "MASH", "2009"], result
    assert_equal [:upcase!, :split], proxy.messages
  end
end

class Television
  attr_accessor :channel

  def power
    @power = (@power == :on) ? :off : :on
  end

  def on?
    @power == :on
  end
end
