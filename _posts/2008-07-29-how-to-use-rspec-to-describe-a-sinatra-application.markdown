---
layout: post
title: How to use RSpec to describe a Sinatra application
---

[Sinatra][] is a fun little web application microframework. Recently I
started working on an application using Sinatra - and since I am
working on good programming habits, before I dove into any coding I
sat down to work out how to write specs for a Sinatra application.

[Sinatra]: http://sinatrarb.com/

Sinatra comes bundled with support for [test/spec][]: a spec framework
that builds on top of Rail's own Test::Unit to provide support for
writing specs. Which is a really neat idea. But I have been using
[RSpec][] for my other work, and I wanted to continue doing so.

[test/spec]: http://chneukirchen.org/repos/testspec/README
[RSpec]: http://rspec.info/

It turns out that RSpec takes a little bit of manual work to get
going with Sinatra. I read a [helpful article on gittr.com][] that
pointed me in the right direction. The article advised me to add these
lines to my spec files:

    require File.expand_path(File.dirname(__FILE__) + '/your_application')
    require 'spec'
    require 'spec/interop/test'
    require 'sinatra/test/unit'

The first line loads your application; the second line loads RSpec;
the third loads an RSpec-Test::Unit compatibility layer; and the
fourth loads Sinatra's test helpers, which are written for
Test::Unit.

[helpful article on gittr.com]: http://www.gittr.com/index.php/archive/sinatra-rspec-integration-without-a-patch-with-examples/

Contrary to Sinatra's instructions for writing tests, you
want to avoid loading 'sinatra/test/spec', which defines Sinatra's
helper methods for test/spec, because that would load test/spec itself
which conflicts with RSpec.

Those instructions mostly worked. I could write and run specs. But I
had trouble with matchers. For example, this example:

    it "should not have a cookie"
      instance.cookie.should be_nil
    end

Would give an error message like this:

    undefined method `be_nil' for nil:NilClass

Which I'm sure you can imagine is pretty annoying.

It was easy enough to identify 'sinatra/test/unit' as the root of the
problem. When I removed that line RSpec's matchers worked fine; but
then I didn't get Sinatra's test helpers, which make spec-writing much
easier. So that wasn't a great solution either.

Examining Sinatra's code, I found that all 'sinatra/test/unit' does is
to load 'sinatra/test/methods' - the actual helper methods - and mixes
them into Test::Unit::TestCase. So I bypassed 'sinatra/test/unit' by
copying and adapting some code from it to make the top of my spec file
look like this:

    require File.expand_path(File.dirname(__FILE__) + '/your_application')
    require 'spec'
    require 'spec/interop/test'
    require 'sinatra/test/methods'
    
    include Sinatra::Test::Methods
    
    Sinatra::Application.default_options.merge!(
      :env =&gt; :test,
      :run =&gt; false,
      :raise_errors =&gt; true,
      :logging =&gt; false
    )
    
    Sinatra.application.options = nil

Since that is a fair amount of setup, I moved all of it into a
separate file called spec_helper.rb, which I loaded into my actual
spec files. Because I am weird enough to write a Sinatra application
that is split into multiple files and multiple spec files.

Anyway, now my specs run just as they should, with Sinatra's helpers
and everything:

    it "should deliver a cookie" do
      get_it '/cookie'
      @response.should be_ok
      @response.headers['Content-Type'].should == 'application/x-baked-goods'
      @response.body.should_not be_empty
    end

The next challenge was to write specs for Sinatra helpers. Although
Sinatra actions and helpers generally appear in the outermost
namespace, the DSL methods that define them actually bind the helpers
to Sinatra::EventContext. You can't invoke helper methods directly
from an example context; you have to create an instance of
Sinatra::EventContext and send the method call to that - much the same
way Rails instantiates a subclass of ActionController::Base to handle a
controller action. Here is the code you will want in your example
groups:

    before :all do
      request = mock("request")
      response = mock("response", :body= =&gt; nil)
      route_params = mock("route_params")
      @event_context = Sinatra::EventContext.new(request, response, route_params)
    end

A `body=` method has to be defined on the response mock to prevent an
error. But it doesn't have to actually do anything. With that setup
code in place, you can do this:

    it "should use a helper to make cookies" do
      @event_context.bake_a_cookie.should be_an_instance_of(Cookie)
    end

and write something like this in your application:

    helper do
      def bake_a_cookie
        Cookie.new(:kind =&gt; :chocolate_chip)
      end
    end

And now you have a reasonably complete speccing setup. There are still
a couple of issues though. For one thing, the spec helpers are missing
a much needed `assigns[]` method. As it stands there is no good way to
pry apart the behavior of an action if there is no convenient method
call to stub. You can only define the parameters that are passed to
it, and read response. On the upside, this does help to enforce good
behavior-driven development.

The other issue is more of an annoyance than a serious problem. It
seems that somewhere in all of this there are one or two
`method_missing` definitions that bounce calls back and forth. If call
a method that is not defined, you generally won't get an "undefined
method" error, you will get a "stack level too deep" error
instead. This is particularly unhelpful because it does not tell you
what class received the undefined method, or which method is
undefined. So a little extra manual stack tracing is required when
this happens.

*Update* 10/11/08:
The Sinatra application that led to this article is now open source and is available at [http://github.com/hallettj/restful_captcha][restful_captcha]. If you want to see the RSpec techniques that I used in context, check out the code there.

[restful_captcha]: http://github.com/hallettj/restful_captcha
