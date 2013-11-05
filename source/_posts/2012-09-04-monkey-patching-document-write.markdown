---
layout: post
title: "Monkey patching document.write()"
comments: true
---

This is one of the crazier workarounds that I have implemented.  I was
working on a web page that embeds third-party widgets.  The widgets are
drawn in the page document - they do not get their own frames.  And
sometimes the widgets are redrawn after page load.

We had a problem with one widget invoking `document.write()`.  In case
you are not familiar with it, if that method is called while the page is
rendering it inserts content into the DOM immediately after the script
tag in which the call is made.  But if `document.write()` is called
after page rendering is complete it erases the entire DOM.  When this
widget was redrawn after page load it would kill the whole page.

The workaround we went with was to disable `document.write()` after page
load by replacing it with a wrapper that checks whether the jQuery ready
event has fired.

{% highlight js %}
(function() {
    var originalWrite = document.write;
    document.write = function() {
        if (typeof jQuery !== 'undefined' && jQuery.isReady) {
            if (typeof console !== 'undefined' && console.warn) {
                console.warn("document.write called after page load");
            }
        }
        else {
            // In IE before version 8 `document.write()` does not
            // implement Function methods, like `apply()`.
            return Function.prototype.apply.call(
                originalWrite, document, arguments
            );
        }
    }
})();
{% endhighlight %}

The new implementation checks the value of `jQuery.isReady` and
delegates to the original `document.write()` implementation if the page
is not finished rendering yet.  Otherwise it does nothing other than to
output a warning message.

<!-- more -->

Disabling `document.write()` means that the problematic widget will not
be fully functional if it is redrawn after page load.  It happens that
in the case of this app that is ok.  The redrawn widget is only used as
a preview when editing widget layouts.

A particular problem came up with IE compatibility.  I wanted to use the
`apply` method that is implemented by all functions in JavaScript to
invoke the original `document.write()` implementation, like this:

{% highlight js %}
return originalWrite.apply(document, arguments);
{% endhighlight %}

But in older versions of Internet Explorer, `document.write()` is not
really a function.  There are a lot of examples in IE of native API
methods and properties that do not behave like regular JavaScript
values.  For example if you pass too many arguments to a DOM API method
in old IE you will get an exception.  Normal JavaScript functions just
silently ignore extra arguments.  If you look at the value of `typeof
document.write` the result is not `"function"`.  What is particularly
problematic in this case is that `document.write` does not implement
`call` or `apply`.

Fortunately I found that the Function prototype does implement both
`call` and `apply` and furthermore you can borrow those methods to use
on function-like values like `document.write`.  `call` and `apply` are
themselves real function values - so `call` and `apply` both implement
`call` and `apply`.  

{% highlight js %}
typeof Function.prototype.apply.apply.apply  // evaluates to 'function'
typeof Function.prototype.apply.call.call  // evaluates to 'function'
{% endhighlight %}

In the workaround above I applied `apply` to `document.write` by taking
the `Function.prototype.apply` value and using its `call` method.  So
this expression,

{% highlight js %}
Function.prototype.apply.call(originalWrite, document, arguments);
{% endhighlight %}

is equivalent to this one,

{% highlight js %}
originalWrite.apply(document, arguments);
{% endhighlight %}

Except that the first version works in IE7.

If you find this difficult to follow, you are not alone.

We have had this workaround in our code for a couple of years now.  So
far it is working nicely.
