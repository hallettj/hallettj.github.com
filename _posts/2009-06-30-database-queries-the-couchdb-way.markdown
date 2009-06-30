---
layout: post
title: Database Queries the CouchDB Way
---

[CouchDB][] is a document-oriented database. It has no rows or tables. Instead
CouchDB is a collection of JSON documents. It uses a map-reduce pattern to
index data. Queries in CouchDB pull data from what are essentially stored
procedures called views. A view is made up of a map function and optionally a
reduce function.  Ninety percent of the time all you need is the map function,
so I will focus on map-only views here.

[CouchDB]: http://couchdb.apache.org/

A map function is a JavaScript function that takes a single document as an
argument and emits any number of key/value pairs. Both the key and the value
can be any JSON value you choose. The map function is run on every document in
the database individually and the emitted key/value pairs are used to construct
an index of your data.


A Simple Example
-----------------

Imagine you have a database with user records and you want a view of those
records using the last name of each user as keys.

{% highlight js %}
function(doc) {
    if (doc.last_name) {
        emit(doc.last_name, doc);
    }
}
{% endhighlight %}

The above map function will produce and index something like the one below.
Because `doc` is used as a value for each entry the entire content of each JSON
document will be accessible as the indexed values.

{% highlight js %}
[
  ...
  { key: "Smith",  value: { last_name: "Smith",  ... } },
  { key: "Kelly",  value: { last_name: "Kelly",  ... } },
  { key: "Clarke", value: { last_name: "Clarke", ... } },
  ...
]
{% endhighlight %}

Notice that the map function checks each document for a `last_name` attribute
before emitting a key/value pair. There may be documents in the database that
are not user records. By performing that check the view excludes any
non-user-record documents from the resulting index.

If you include the [couch.js][] library in a web page you can create
client-side queries to pull data from CouchDB over HTTP.  The function below
will fetch all of the user records from your database by returning the `value`
of each key/value pair emitted by the view above.

[couch.js]: http://github.com/halorgium/couchdb/blob/2c5f780d8284be5e2cb39f7f61acc5ef8d6fb50d/share/www/script/couch.js

{% highlight js %}
function users(db) {
    return db.view('users/last_names').rows.map(dot('value'));
}

// Run the query and output data to the console.
var db = new CouchDB('database-with-users');
console.log(users(db));
{% endhighlight %}

Map functions operate on one document at a time and cannot access data from
other documents. The advantage of this is that the functions can process data
in any order and can run on any piece of a data set independent of the rest of
the set.  CouchDB builds static indexes from the output of view map functions
so that queries against those views will run quickly.  When any documents
change CouchDB can incrementally rebuild the indexes for just those documents
without having to rebuild entire indexes from scratch.

The CouchDB design gets you great performance on large data sets. But it means
that you cannot pass dynamic parameters to your map function when you run a
query. You cannot ask for it to emit only user records with a given last name
unless you want to maintain a special view for that particular last name. In
most cases it is not practical to build separate views for every query that you
might want to run someday. So what you can do is to run a query against the
general purpose view above and request only key/value pairs that match a
particular key.

{% highlight js %}
function find_users_by_last_name(db, last_name) {
    var matches;
    matches = db.view('users/last_names', { key: last_name });
    return matches.rows.map(dot('value'));
}
{% endhighlight %}

This client code creates a query that requests data from the `last_names` view
with a `key` parameter. CouchDB will only send back key/value pairs with keys
that match the `key` parameter. In this case the query will return all user
records with last names matching the `last_name` argument.

In a more advanced case you may want to take the first few letters of a last
name and look up user records that match.

{% highlight js %}
function find_users_whose_last_names_start_with(db, query) {
    var matches;
    matches = db.view('users/last_names',
                      { startkey: query,
                        endkey:   query + "\u9999" });
    return matches.rows.map(dot('value'));
}
{% endhighlight %}

Data returned by a query is always sorted by key. In the case where the keys
are strings the sorting will be lexicographic.  The `startkey` and `endkey`
parameters restrict the results of the query to key/value pairs that fall in
the given range according to CouchDB's sort order.

When the above function is given the query string "Ha", it will fetch documents
with keys sorted after "Ha" lexicographically, e.g. "Hallett", "Hathaway", and
"Hazzold". The `endkey` is created by appending "\u9999" to the `startkey`.
"\u9999" is a unicode character that comes after most other characters in
lexicographic order and that is unlikely to appear in a data set. Effectively
the string "Ha\u9999" sorts after every other string that begins with "Ha", but
before any string that starts with "Hb".

Note that CouchDB uses the [Unicode Collation Algorithm][] to sort strings.
Sorting comes out differently than you may be used to if your are accustomed to
the ASCII way. UCA collation is intended to mimic the order of strings you
would see in a dictionary. For example, two strings that differ only in case
will appear together in sorted order. The lower-case string will appear
immediately before the upper-case string. So if you force your `startkey` to
lower-case and your `endkey` to upper-case you will get case-insensitive
matches. See the [CouchDB wiki][collation] for more details.

[Unicode Collation Algorithm]: http://www.unicode.org/unicode/reports/tr10/
[collation]: http://wiki.apache.org/couchdb/View_collation


Search by Keyword
------------------

Indexing text content can be a hard problem because you need a large index if
you want to query data by arbitrary keywords or substrings.  Fortunately
CouchDB excels at managing large indexes.

Here is a map function that creates an index of all the words that appear in
the text field of every document in a database.

{% highlight js %}
function(doc) {
    var tokens;
    if (doc.text) {
        tokens = doc.text.split(/[^A-Z0-9\-_]+/i).uniq();
        tokens.map(function(token) {
            emit(token, doc);
        }
    }
}
{% endhighlight %}

The code splits text on word boundaries stripping out non-alphanumeric
characters. It runs the resulting list of tokens through a unique filter so
that only one index key is produced for each word in the text of a single
document.

This is an example of a view that emits more than one key/value pair for each
document. The values in each pair are the same for the same document. But a
different key is recorded for each word in the document's text attribute. The
index that would be created by this view for a document with the text "Live
long and prosper" is below.

{% highlight js %}
[
  { key: "Live",    value: { text: "Live long and prosper." } },
  { key: "long",    value: { text: "Live long and prosper." } },
  { key: "and",     value: { text: "Live long and prosper." } },
  { key: "prosper", value: { text: "Live long and prosper." } }
]
{% endhighlight %}

To look up documents that contain a given keyword you just need to create a
query with that keyword as the `key` parameter. But what if you want to look
for documents that contain a list of keywords? You could create index keys for
every combination of words in each document. But that index would grow
exponentially and might get to be unreasonably large. A better way might be to
pick one keyword to perform your query and then to use client code to select
the documents that match all of the keywords out of the results returned by
CouchDB.

{% highlight js %}
function find_documents_by_keywords(db, keywords) {
    var possible_matches;

    // Query documents that include the first keyword.
    possible_matches = db.view('documents/keywords', 
                               { key: keywords[0] });

    // Pull the value attribute out of each returned key/value
    // pair.
    possible_matches = possible_matches.rows.map(dot('value'));

    // Pick out the documents that include all of the given
    // keywords.
    return possible_matches.select(function(m) {
        return keywords.reduce(true, function(match, keyword) {
            return m.text.match(keyword) && match;
        });
    });
}
{% endhighlight %}

When you want more dynamic data processing than you can get with pure-CouchDB
views, some client-side processing can make up the difference nicely. From a
perspective of deploying applications leveraging your users' CPU cycles for
data processing can really help getting your application to scale.


Search by Substring
--------------------

Maybe keyword search isn't good enough. Maybe you need to be able to search for
occurrences of any substring in a data set.

{% highlight js %}
function(doc) {
    var i;
    if (doc.text) {
        for (i = 0; i < doc.text.length; i += 1) {
            emit(doc.text.slice(i), doc);
        }
    }
}
{% endhighlight %}

For each document, this map function emits a key/value pair for every possible
substring that runs to the end of the document's text. The idea is that the
beginning of any substring in the data set can be lined up with the beginning
of one of these keys.  Here is an example of the index created for a document
with the text "Hello, world!":

{% highlight js %}
[
  { key: "Hello, world!", value: { text: "Hello, world!" } },
  { key: "ello, world!",  value: { text: "Hello, world!" } },
  { key: "llo, world!",   value: { text: "Hello, world!" } },
  { key: "lo, world!",    value: { text: "Hello, world!" } },
  { key: "o, world!",     value: { text: "Hello, world!" } },
  { key: ", world!",      value: { text: "Hello, world!" } },
  { key: " world!",       value: { text: "Hello, world!" } },
  { key: "world!",        value: { text: "Hello, world!" } },
  { key: "orld!",         value: { text: "Hello, world!" } },
  { key: "rld!",          value: { text: "Hello, world!" } },
  { key: "ld!",           value: { text: "Hello, world!" } },
  { key: "d!",            value: { text: "Hello, world!" } },
  { key: "!",             value: { text: "Hello, world!" } },
]
{% endhighlight %}

The substring that you want to search for can begin at any character within
some document's text. It may or may not run until the end of that document's
text field. We have an index with the beginning characters for every possible
substring. So we can create a query that asks for a key range that encompasses
both the given substring and a substring that runs all the way to the end of
the document text.

{% highlight js %}
function find_all_by_substring(db, str) {
    return db.view('documents/substrings',
                   { startkey: str,
                     endkey: str + "\u9999" }
                  ).rows.map(dot('value'));
}
{% endhighlight %}

And just as with the keyword search, if you want to search for documents that
match a list of substrings then get the matches for one of the substrings from
CouchDB and use client code to select results that contain all of the rest of
the given substrings.

{% highlight js %}
function find_all_by_substrings(db, strs) {
    var matches;
    matches = db.view('documents/substrings',
                      { startkey: strs[0],
                        endkey: strs[0] + "\u9999" });
    return matches.rows.map(dot('value')).select(function(d) {
        return strs.reduce(function(r, s) {
            return d.text.match(s) && r;
        });
    });
}
{% endhighlight %}

If the text of your documents tends to be very long you can avoid a lot of
really long keys by limiting the lengths of substring keys in your view. In
that case make sure to truncate the key parameters in your queries so that they
are not longer than the index keys.


Appendix: Helper Function Definitions
--------------------------------------

Some of the functions that I used in the examples above are not built into
JavaScript or [couch.js][]. Here are definitions of those functions for
reference.

Given an attribute name, `dot` returns a function that when given an object
returns the value of the specified attribute. This function is used in examples
above to get the `value` attributes of rows fetched by CouchDB queries.

{% highlight js %}
function dot(attr) {
    return function(obj) {
        return obj[attr];
    }
}
{% endhighlight %}

[`map`][map] is an Array method that given a function that takes a single
argument returns a new array formed by applying the given function to every
element of the original array in turn.

[map]: http://en.wikipedia.org/wiki/Map_%28higher-order_function%29

{% highlight js %}
Array.prototype.map = function(func) {
    var i, r = [],
    for (i = 0; i < this.length; i += 1) {
        r[i] = func(this[i]);
    }
    return r;
};
{% endhighlight %}

[`reduce`][reduce] is an Array method that given an initial value and a
function that takes two arguments returns a single value produced by applying
the given function to every element of the array in turn with the value from
the previous function invocation and returning the last result.

[reduce]: http://en.wikipedia.org/wiki/Reduce_%28higher-order_function%29

{% highlight js %}
Array.prototype.reduce = function(val, func) {
    var i;
    for (i = 0; i < this.length; i += 1) {
        val = func(val, this[i]);
    }
    return val;
}
{% endhighlight %}

`select` is an Array method that given a test function returns a new array made
up of only elements in the original array that pass the test.

{% highlight js %}
Array.prototype.select = function(test) {
    return this.reduce([], function(r, e) {
        if (test(e)) {
            return r.concat([e]);
        } else {
            return r;
        }
    });
};
{% endhighlight %}

`uniq` is an Array method that returns a new array with any duplicate values
from the original array removed.

{% highlight js %}
Array.prototype.uniq = function() {
    return this.reduce([], function(list, e) {
        if (list.indexOf(e) < 0) {
            return list.concat([e]);
        } else {
            return list;
        }
    });
}
{% endhighlight %}
