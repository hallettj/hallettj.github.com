---
layout: post
title: "How Mobile Safari emulates mouse events"
comments: true
---

When you are adapting web apps to touchscreen devices particular
challenges come up around events like `mouseover` and `mouseout`.
Touchscreen devices like the iPad do not have a cursor, so the user
cannot exactly move the mouse over an HTML element.  However, Mobile
Safari, the web browser that comes with the iPhone and iPad, has
a fallback for websites that require hovering or cursor movement.

Usually when you tap on an element on a link or other clickable element
Mobile Safari translates that into a regular `click` event.  The browser
also produces some touch events that do not exist in a lot of browsers.
But from the perspective of a web page that was not designed with
a touchscreen in mind, what you get is a plain `click`.  More
specifically, the browser fires `mousedown`, `mouseup`, and `click` in
that order.  But if a clickable element also does something on
`mouseover` then tapping on that element will trigger a `mouseover` event
instead of a `click`.  Tapping on the same element again will produce
a `click` event.  A random example of a page that exhibits this behavior
is [the schedule page][schedule] from the [Open Source Bridge][]
website.  Try tapping on session titles and see what happens.

[schedule]: http://opensourcebridge.org/events/2011/schedule 
[Open Source Bridge]: http://opensourcebridge.org/

Mobile Safari will only produce mouse events when the user taps on
a clickable element, like a link.  You can make an element clickable by
adding an onClick event handler to it, even if that handler does
nothing.  On tap Mobile Safari fires the events `mouseover`,
`mousemove`, `mousedown`, `mouseup`, and `click` in that order - with
some caveats which are explained below.  Those events all fire together
after the user lifts her finger.  You might expect the `mousedown` event
to fire as soon as the user presses her finger to the screen - but it
does not.  When the user taps on another clickable element the browser
fires a `mouseout` event on the first element in addition to firing the
aforementioned events on the new element.

<!-- more -->

So how do we get to the behavior where one tap emulates `mouseover` and
a second tap emulates `click`?  It turns out that after any `mouseover`
event handlers run Safari checks the DOM for changes and if the content
has changed it skips the `mousedown`, `mouseup`, and `click` events.  So
these events do not fire.  When the user taps on the same element again
the `mouseover` event does not fire again, so the browser goes ahead
with the other events.

The `mousemove` event behaves in a similar way: if the DOM has changed
after any `mousemove` handlers are finished running then Mobile Safari
skips the remaining events.

<figure>
  <figcaption>
    Diagram from <a
    href="http://developer.apple.com/library/safari/#documentation/AppleApplications/Reference/SafariWebContent/HandlingEvents/HandlingEvents.html">Apple's
    documentation</a> demonstrating how the browser determines which
    mouse events to fire.
  </figcaption>
  <img src="/images/events_1_finger.jpg" alt="mouse event firing diagram" />
</figure>

Safari does not accept just any change to a DOM element as a "content
change" though.  Through testing I discovered that adding a regular
element to the DOM or showing a previously hidden element in
a `mouseover` handler would prevent the `click` event from firing.  But
removing an element, hiding an element, or changing the content of
a text node do not prevent the `click` event.  I also tried adding class
names to elements - which Safari also did not treat as a "content
change".  As far as I can tell only adding or showing an element will
cause the `mousedown`, `mouseup`, and `click` events to be skipped.

I created some fiddles on [jsfiddle.net][] to test Mobile Safari
behavior.  For your investigative pleasure I have
[an example of a `mouseover` handler that adds elements to the DOM][adds elements],
[another that shows a hidden element][shows elements],
and [a third that makes no changes to the DOM at all][makes no changes].

[jsfiddle.net]: http://jsfiddle.net/
[adds elements]: http://jsfiddle.net/hallettj/pgpLA/
[shows elements]: http://jsfiddle.net/hallettj/4wjgk/
[makes no changes]: http://jsfiddle.net/hallettj/m5EXk/
