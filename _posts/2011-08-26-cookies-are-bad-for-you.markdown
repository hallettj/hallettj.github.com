---
layout: post
title: "Cookies are bad for you: Improving web application security"
---

Most web applications today use browser cookies to keep a user logged in
while she is using the application.  Cookies are a decades-old device
and they do not stand up well to security threats that have emerged on
the modern web.  In particular, cookies are vulnerable to [cross-site
request forgery][CSRF].  Web applications can by made more secure by
using [OAuth][] for session authentication.

[CSRF]: http://en.wikipedia.org/wiki/Cross-site_request_forgery
[OAuth]: http://oauth.net/

This post is based on [a talk that I gave][session] at [Open Source
Bridge][] this year.  The slides for that talk are available
[here][slides].

[session]: http://opensourcebridge.org/sessions/663
[slides]: /talks/cookies/
[Open Source Bridge]: http://opensourcebridge.org/

<img alt="cookie authentication" src="/talks/cookies/svg/cookies.svg" style="width: 100%" />

When a user logs into a web application the application server sets
a cookie value that is picked up by the user's browser.  The browser
includes the same cookie value in every request sent to the same host
until the cookie expires.  When the application server receives
a request it can check whether the cookies attached to it contain
a value that identifies a specific user.  If such a cookie value exists
then the server can consider the request to be authenticated.

<img alt="attacks that target browser authentication" src="/talks/cookies/svg/cookie-strengths.svg" style="width: 100%" />

There are many types of attacks that can be performed against a web
application.  Three that specifically target authentication between the
browser and the server are [man-in-the-middle (MITM)][MITM], [cross-site
request forgery (CSRF)][CSRF], and [cross-site scripting (XSS)][XSS].
Plain cookie authentication is vulnerable to all three.

[MITM]: http://en.wikipedia.org/wiki/Man-in-the-middle_attack
[XSS]: http://en.wikipedia.org/wiki/Cross-site_scripting

<img alt="session hijacking" src="/talks/cookies/svg/session_hijacking.svg" style="width: 100%" />

In a MITM attack the attacker is in a position to watch traffic that
passes between some user's browser and an application server.  If that
traffic is not encrypted the attacker could steal private information.
One of the most dangerous things that an attacker can do in this
position is to hijack the user's session by reading cookie data from an
HTTP request and including that cookie data in the attacker's own
requests to the same server.  This is a form of privilege escalation
attack.  Using this technique an attacker can convince an application
server that the attacker is actually the user who originally submitted
a given cookie.  Thus the attacker gains access to all of the user's
protected resources.

Last year a Firefox extension called [Firesheep][] made some waves when
it was released.  The purpose of Firesheep was to raise awareness of the
danger of MITM attacks.  Most web applications, at that time and today,
use cookie authentication without an encrypted connection between
browser and server.  Firesheep makes it easy to spy on anybody who is
using well known applications like Facebook and Twitter on a public
network.  With the click of a button you can perform a MITM attack
yourself, steal someone's cookies, and gain access to that person's
Facebook account.

[Firesheep]: http://codebutler.com/firesheep

[MITM][] attacks can be effectively blocked by using HTTPS to encrypt
any traffic that contains sensitive information or authentication
credentials.  When using HTTPS you will almost certainly want to set the
"secure" flag on any cookies used for authentication.  That flag
prevents the browser from transmitting cookies over an unencrypted
connection.

More and more web applications are offering HTTPS - often as on opt-in
setting.  Any web site that requires a login should offer HTTPS - and
ideally it should be enabled by default.

<img alt="cross-site scripting" src="/talks/cookies/svg/xss.svg" style="width: 100%" />

[XSS][] attacks involve an attacker pushing malicious JavaScript code
into a web application.  When another user visits a page with that
malicious code in it the user's browser will execute the code.  The
browser has no way of telling the difference between legitimate and
malicious code.  Injected code is another mechanism that an attacker can
use for session hijacking: by default cookies stored by the browser can
be read by JavaScript code.  The injected code can read a user's cookies
and transmit those cookies to the attacker.  Just like in the MITM
scenario, the attacker can use those cookies to disguise herself as the
hapless user.

There are other ways that XSS be used can be used to mess with a user - but
session hijacking is probably the most dangerous.  Session hijacking via
XSS can be prevented by setting an "httpOnly" flag on cookies that are
used for authentication.  The browser will not allow JavaScript code to
read or write any cookie that is flagged with "httpOnly"; but those
cookies will still be transmitted in request headers.

<img alt="cross-site request forgery" src="/talks/cookies/svg/csrf.svg" style="width: 100%" />

[CSRF][] attacks authentication indirectly.  A malicious web page can
trick a browser into making cross-domain requests to another web site.
If a user visiting the malicious page is already logged in to that web
site then the malicious page can access the site resources as though it
were logged in as the unsuspecting user.  For example, if a malicious
page can trick the browser into making POST requests to a microblogging
site it can post updates with spam links that appear to have been
written by the victim.

If you use Facebook you might have encountered attacks like this
yourself.  You see a post on a friend's wall with a button that says
["Don't click the button!"][Facebook worm]  When you click on it you are
taken to another site and the same message ends up posted on your wall.

[Facebook worm]: http://www.pcworld.com/businesscenter/article/182940/facebook_worm_spreads_with_a_lurid_lure.html

This works because the browser automatically sends cookies set on
a given domain with every request made to that domain, regardless of
where those requests originated.  The browser has no way of knowing that
the requests initiated by the malicious page are made without the user's
knowledge.

The malicious page could create a cross-domain request by including an
image with a `src` attribute pointing to a URL on the site that it is
trying to hack into.  The URL does not have to be an image - the browser
will make a GET request to that URL and will discard the response when
it determines that the response is not image data.  If that GET request
produced any side-effects, like posting a microblogging update, then the
malicious page has successfully performed an attack.

To make a cross-domain POST request the malicious site might include
a hidden HTML form with an `action` attribute pointing at the site to be
hacked.  The malicious page can use JavaScript to submit the form
without any interaction from the user.  This is another case where the
attacker cannot read the response that comes back but can trigger some
action in the user's account.

In some cases CSRF attacks can also be used to read data.  Because JSON
is a strict subset of JavaScript, [HTTP responses that contain JSON data
can be loaded into script tags and executed.][CSRF and JSON]  In some
browsers a malicious page can override the Object and Array constructors
to capture data from the JSON response as it is executed so that it can
be sent to an attacker.

[CSRF and JSON]: http://blog.archive.jpsykes.com/47/practical-csrf-and-json-security/

The biggest problem with CSRF is that cookies provide absolutely no
defense against this type of attack.  If you are using cookie
authentication you must also employ additional measures to protect
against CSRF.  The most basic precaution that you can take is to make
sure that your application never performs any side-effects in response
to GET requests.

To protect against cross-domain POST requests a commonly used option is
to use an [anti-forgery token][] that must be submitted with every POST,
PUT, or DELETE request.  The token is generally injected into the HTML
code for forms in such a way that malicious code on another site does
not have any way to access it.

[anti-forgery token]: https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet#General_Recommendation:_Synchronizer_Token_Pattern

JSON responses can be protected by pre-pending the JSON response with
some code that makes the response non-executable.  For example, you
could place a JavaScript loop at the beginning of the response that
never terminates.  Or you could put in a statement that throws an
exception.  Putting the whole JSON response inside of a comment block
also works.  The only way for a browser to read JSON data that has been
obfuscated like this is to fetch the resource using XHR and to remove
the extra code before parsing the actual JSON data.  XHR is limited by
the [same-origin policy][]; so a malicious page cannot make a cross-site
XHR request.

[same-origin policy]: http://en.wikipedia.org/wiki/Same_origin_policy

Such multi-layered approaches to CSRF defense work but are a pain to
implement.  I know from experience that the stateful nature of
anti-forgery tokens make them a constant source of bugs in Ajax-driven
applications where users might submit several requests to the server
without ever loading a new page.  It is too easy for the client and
server to get out of sync and to disagree about which anti-forgery
tokens are fresh.  And great care must be taken to include the
anti-forgery feature in every form and Ajax call in an application or
a security hole appears.

JSON obfuscation is easier to apply to every JSON response as a blanket
policy thanks to server-side filters and client-side hooks, such as
those in jQuery's Ajax stack.  But then you are not really serving JSON - you
are serving a JSON-like type with a proprietary wrapper.  I find that
I spend a lot of time instructing people on the existence of
obfuscation, explaining why it is there, and explaining how to set up
hooks to remove it on the client side.

<img alt="protections provided by the &quot;httpOnly&quot; and &quot;secure&quot; flags" src="/talks/cookies/svg/secure-cookie-plus-https-strengths.svg" style="width: 100%" />

By combining the "secure" and "httpOnly" flags and using HTTPS you can
make your application authentication proof against MITM attacks and
against some XSS attacks.  But there is nothing that will make cookie
authentication resistant to CSRF attacks.  The only way to protect
against CSRF is to apply additional security measures.  Often multiple
measures are required to combat different possible CSRF vectors.  And
those measures are not always simple or transparent.

In my opinion CSRF stifles innovation on the web.  Because cross-domain
requests cannot be trusted, even if they appear to be authenticated, web
applications have to be thoroughly locked down to reject any
cross-origin traffic.  There is a relatively new specification for
making cross-origin XHR requests called [Cross-Origin Resource Sharing
(CORS)][CORS].  This specification could allow for exciting new mashups
involving rich JavaScript applications and public APIs.  Most modern
browsers support CORS too - including Internet Explorer 8.  But CORS is
rarely used because it opens up a big hole that could be exploited by
CSRF.  Existing CSRF countermeasures rely on limiting XHR requests to
the same-origin policy.  For most web developers the risk is too great
to justify experimenting with new technology.

[CORS]: http://www.w3.org/TR/cors/

The way to make the web a safer place is to switch to authentication
mechanisms that provide strong protection against CSRF at the most basic
level.  The key is to choose a mechanism that is controlled by the web
application, not the browser.  The web browser has no way of
distinguishing legitimate requests from forged ones - it will attach
cookies to both.  On the other hand, application code can be written to
be smarter.

<img alt="OAuth" src="/talks/cookies/svg/Oauth_logo.svg"
style="width: 50%; display: block; margin-left: auto; margin-right: auto;" />

There are many authentication schemes that would work well.  I lean
toward OAuth 2.0.  OAuth has some nice advantages: it is standardized;
there are numerous server implementations; and the simplest form of the
[OAuth 2.0 draft specification][] is pretty easy to implement.

[OAuth 2.0 draft specification]: http://tools.ietf.org/html/draft-ietf-oauth-v2-20

<img alt="three-legged OAuth" src="/talks/cookies/svg/oauth_auth_code_step_1.svg" style="width: 100%" />

In a traditional OAuth setup there are three parties: the authorization
server / resource server, the client and the resource owner.  Through
a series of steps the resource owner, typically a user working through
a web browser, submits a password to the authorization server and the
authorization server issues an access token to the client.  You can read
more about the OAuth protocol flow on the [OAuth 2.0 web site][OAuth 2.0].

[Oauth 2.0]: http://oauth.net/2/

<img alt="two-legged OAuth" src="/talks/cookies/svg/oauth_auth_pass_step_1.svg" style="width: 100%" />

When applying OAuth to session authentication the picture becomes
simpler: the browser acts as both the resource owner and the client; so
some of the indirection of three-legged OAuth can be skipped.  Instead,
a web application can use a protocol flow that the OAuth 2.0
specification calls [Resource Owner Password Credentials][] in which the
user enters her password into a login form, the password is submitted to
the application server directly, and the server responds to that request
with an access token.  You can think of this as "two-legged" OAuth.

[Resource Owner Password Credentials]: http://tools.ietf.org/html/draft-ietf-oauth-v2-20#section-4.3

<img alt="a request signed with OAuth" src="/talks/cookies/svg/oauth_auth_pass_step_3.svg" style="width: 100%" />

In both the two- and three-legged flows requests are signed by adding an
"Authorization" header with one of two possible formats.  In the [bearer
scheme][Bearer Tokens] the authorization header value is just the access
token that was given to the client.  For example:

    GET /resource HTTP/1.1
    Host: server.example.com
    Authorization: Bearer vF9dft4qmT

The [HMAC scheme][MAC Access Authentication] is a bit
more complicated: in that case the client is given an access token id in
addition to the token itself and the authorization header includes the
token id and an HMAC-signed hash of the request URL, the request method,
a nonce, and possibly a nested hash of the request body.  The OAuth
access token is used as the key in the [HMAC algorithm][HMAC].

    POST /request HTTP/1.1
    Host: example.com
    Content-Type: application/x-www-form-urlencoded
    Authorization: MAC id="jd93dh9dh39D",
                 nonce="273156:di3hvdf8",
                 bodyhash="k9kbtCly0Cly0Ckl3/FEfpS/olDjk6k=",
                 mac="W7bdMZbv9UWOTadASIQHagZyirA="

    hello=world%21

The advantage of the HMAC scheme is that it can provide some protection
against MITM attacks even if signed requests are not encrypted with
HTTPS.

[Bearer Tokens]: http://tools.ietf.org/html/draft-ietf-oauth-v2-bearer-06
[MAC Access Authentication]: http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-00
[HMAC]: http://en.wikipedia.org/wiki/HMAC

I propose a design in which the browser submits credentials from a login
form to the server via XHR, gets an access token back, and uses that
access token to sign subsequent requests.  Full page requests and form
posts are difficult to sign with OAuth - hyperlinks and form tags do not
provide a way to specify an "Authorization" header.  So OAuth-signed
requests would probably be limited to XHR.  The browser could store the
OAuth access token in a persistent client-side store to give the user an
experience that is indistinguishable from a cookie-based application - but
that is more secure.

It is entirely possible for JavaScript code running in a web browser to
sign requests with HMAC.  There are pure JavaScript implementations
available of many cryptographic functions, including [SHA-1 and
SHA-256][], which are the hash functions that are used for OAuth HMAC
signing.  However, if your application uses HTTPS to protect every
request then the simpler bearer scheme is entirely sufficient.

[SHA-1 and SHA-256]: http://jssha.sourceforge.net/

In this design form posts would be eliminated.  Instead form data would
be serialized in JavaScript and submitted using Ajax.  That way all
requests that produce side-effects would be channeled through
OAuth-signed XHR.  I am not suggesting eliminating form tags though - form
tags are an essential tool for semantic markup and for accessibility.
I recommend that JavaScript be used to intercept form "submit" events.

<img alt="the BigPipe design" src="/talks/cookies/svg/bigpipe_step_1.svg" style="width: 100%" />

There are a couple of options for dealing with full page loads.  One
possibility is to not require any authentication for requests for HTML
pages and to design your application so that HTML responses do not
include any protected information.  Such an application would serve
pages as skeletons, with empty areas that to be filled in with dynamic
and protected content after page load using Ajax.  The dynamic responses
could be HTML fragments that are protected by OAuth, or they could be
JSON responses that are rendered as HTML using client-side templates.

Facebook uses a process like this which they call [BigPipe][].
Facebook's rationale for BigPipe is actually performance, not security.
In my opinion the BigPipe approach gives a best-of-both-worlds blend of
performance and security.  Plus, it lets you put caching headers on full
page responses, even in apps with lots of dynamic content.

[BigPipe]: https://www.facebook.com/notes/facebook-engineering/bigpipe-pipelining-web-pages-for-high-performance/389414033919

A downside of BigPipe is that content that is loaded via Ajax generally
cannot be indexed by search engines.  Google's recently published
specification for [making Ajax applications crawlable][] may provide
a solution to that problem.  Or you might choose to use the BigPipe
approach everywhere in your application except for publicly accessible
pieces of content.

[making Ajax applications crawlable]: http://code.google.com/web/ajaxcrawling/

Another way to handle full page loads would be to continue using cookie
authentication for HTML resources.  HTML responses are less vulnerable
to CSRF snooping than JSON because HTML is not executable in script
tags.  In this case you should still require OAuth signing on requests
for JSON resources and on any requests that could produce side-effects.
But allowing cookie authentication on non-side-effect-producing GET
requests for HTML resources should be safe.

<img alt="strengths of OAuth" src="/talks/cookies/svg/oauth-plus-https-strengths.svg" style="width: 100%" />

Using JavaScript to manage access tokens rather than relying on
a built-in browser function makes CSRF attacks impractical.  A malicious
third-party site can no longer rely on browsers to automatically attach
authentication credentials to requests that it triggers.  Client-side
storage implementations are generally protected by the [same origin
policy][] - so only code running in your application can retrieve an
access token and produce an authenticated request.  And if you combine
OAuth with HTTPS then you are also protected against MITM attacks.

[same origin policy]: http://en.wikipedia.org/wiki/Same_origin_policy

A drawback is that you lose the XSS protection that the "httpOnly"
cookie flag provides with cookie authentication.  An application that
uses OAuth will have to use other methods to block XSS.  But in my
opinion there are better options for dealing with XSS than there are for
dealing with CSRF.  By consistently sanitizing user-generated content
you can effectively block XSS at the presentation layer of your
application.  That would be necessary anyway, since "httpOnly" only
prevents XSS-based privilege escalation attacks and by itself does not
prevent other XSS shenanigans.

To track a session using OAuth applications will need some way to store
access tokens for the duration of a user's session.  There are various
ways to do that:

- In the simplest case you can store the token in memory by assigning it
  to a JavaScript variable.  This might be useful in a single page
  application.  The user will have to log in again if she goes to
  another page or opens your app in a new window.

- [localStorage][] can be used to store a token so that is persistent
  even if the user closes and re-opens the browser.  Data stored in
  localStorage is available to all windows on the same domain.  You will
  probably want to include a hook to clear local storage when the user
  logs out of your application.

- [sessionStorage][] works like localStorage, except that data is only
  accessible from the same window that stored it and the whole store for
  a given window is wiped when the user closes that window.  So the user
  does not have to log in again if she goes to another page; but she
  does have to log in again if she opens your app in a new window.

  sessionStorage can be a more secure option than localStorage - especially
  on a shared or a public computer.  If you decide to use a storage
  option that does not expire automatically when the browser is closed
  I suggest including a "remember me" checkbox in your login form and
  using sessionStorage instead when the user does not check that box.

- Although I have been arguing that cookies are not the best option for
  authentication, storing an access token in a cookie works just fine.
  The key is that the server should not consider the cookie to be
  sufficient for authentication.  Instead it should require that the
  access token be copied from the cookie value into an OAuth header.

  For the cookie option to be secure you should set the "secure" flag so
  that it is not transmitted over a connection that could be read via
  a MITM attack.  You should not set the "httpOnly" flag because the
  cookie needs to be accessible from JavaScript.

  A nice advantage of the cookie option is that users have been trained
  that they can delete cookies to reset a session.  On the other hand,
  most users do not know about localStorage and most browsers do not
  provide an obvious way to clear localStorage.  So the cookie option is
  likely to conform best to user expectations.  Cookies can also be
  configured to expire when the browser is closed or to persist for
  a long period of time.

- Other options include [IndexedDB][], which is a more sophisticated
  store that is similar to localStorage, [Flash cookies][], and
  [userData][] in IE.

There is a good summary of client-side storage implementations and how
to use them on [Dive Into HTML5][storage summary].  Or if you want
a pre-built solution that avoids most cross-browser headaches you can
use [PersistJS][] or a similar tool.

[localStorage]: https://developer.mozilla.org/en/dom/storage#localStorage
[sessionStorage]: https://developer.mozilla.org/en/dom/storage#sessionStorage
[IndexedDB]: https://developer.mozilla.org/en/IndexedDB
[Flash cookies]: http://en.wikipedia.org/wiki/Flash_cookies
[userData]: http://msdn.microsoft.com/en-us/library/ms531424(v=vs.85).aspx
[PersistJS]: http://pablotron.org/software/persist-js/
[storage summary]: http://diveintohtml5.org/storage.html

Web applications that rely on cookie authentication can often be
designed to degrade gracefully, so that if JavaScript is disabled or is
not available the application will still work.  With OAuth that is not
possible.  I can imagine this being a major objection to ditching cookie
authentication.  Some people prefer to disable JavaScript for security
or for privacy reasons.  Many of the more basic mobile and text-only web
browsers do not support JavaScript.  And in the past screen readers have
not handled JavaScript-driven web apps well.

In my opinion the requirement that JavaScript be enabled to use an
application is generally worthwhile.  Mobile browsers that do support
JavaScript are rapidly pushing out those that do not.  Text-only
browsers will have to start supporting JavaScript sooner or later to
keep up.  The people who designed your web browser took great care to
ensure that your security and privacy are protected even when JavaScript
is enabled.  Screen readers are much better than they used to be at
making JavaScript-driven web sites accessible.

You should consider your target audience, your application requirements,
and your security needs and decide for yourself whether dropping the
noscript option is the right choice for your application.

No security protocol is bulletproof.  Do lots of research and use common
sense whenever you are working on an application that needs to be
secure.

Image credits:

The [OAuth logo][] by Chris Messina is licensed under the
[Creative Commons][] [Attribution-Share Alike 3.0 Unported][] license.

Other images used in diagrams are from the [Open Clip Art Library][] and
are in the public domain.

[OAuth logo]: http://en.wikipedia.org/wiki/File:Oauth_logo.svg
[Creative Commons]: http://en.wikipedia.org/wiki/en:Creative_Commons
[Attribution-Share Alike 3.0 Unported]: http://creativecommons.org/licenses/by-sa/3.0/deed.en
[Open Clip Art Library]: http://en.wikipedia.org/wiki/Open_Clip_Art_Library

tags: osb11

*[CORS]: Cross-Origin Resource Sharing
*[CSRF]: cross-site request forgery
*[HTTP]: Hypertext Transfer Protocol
*[HTTPS]: HTTP Secure
*[JSON]: JavaScript Object Notation
*[MITM]: man-in-the-middle
*[URL]: Uniform Resource Locator
*[XHR]: XMLHttpRequest
*[XSS]: cross-site scripting
