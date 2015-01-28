% Flow: <br> type-checked JavaScript
% Jesse Hallett
% January 28, 2015


~~~~ {.javascript}
/* @flow */
function foo(x) {
  return x * 10;
}
foo('Hello, world!');
~~~~~~~~~~~~~~~~~~~~~~

. . .

    $ flow

    hello.js:5:5,19: string
    This type is incompatible with
      hello.js:3:10,15: number
