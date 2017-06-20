---
layout: post
title: "What is Poodle"
author: Jesse Hallett
date: 2017-06-20
comments: true
---

This is a description of my passion project. I plan to publish more detail and motivation when I get to a minimum viable product.

I want to make social collaboration software without walls.
A company can have its private discussions and documents -
but people in a company should be able to include clients or contractors in discussions seamlessly.
It should not be necessary to require people to join a private account on
service X just to have a conversation.

The idea is to make a decentralized protocol -
there is no central server, and no one company that controls everything.
This has been attempted before by Identi.ca, Diaspora, Google Wave, and others.
I thought that a decentralized protocol could have more success if it takes a different approach: reinvent as little as possible, and build on top of an existing protocol with a large user base.
I'm working on a reference client (called [Poodle][]) that implements a new protocol that builds on email.

[Poodle]: https://github.com/PoodleApp/poodle-electron

Email is one of the few decentralized social protocols that has broad adoption
([2.6 billion users][email statistics]);
and it has stood the test of time.
Email is not perfect - but over the years email systems have evolved to address many subtle problems;
and we have deployed a great deal of email infrastructure and supporting software.
A protocol that builds on email instead of attempting to replace it will have a massive head start thanks to all of that work.

[email statistics]: http://www.radicati.com/wp/wp-content/uploads/2015/02/Email-Statistics-Report-2015-2019-Executive-Summary.pdf

<!-- more -->

There is a deeply-set mindset that email messages are text or HTML,
and that one message corresponds to one reply.
This is the same way people thought about web pages in the '90s.
Then AJAX came along and changed everything by decoupling HTTP requests from page views.
That was the big idea that led to [Web 2.0][].
I want to apply a similar idea:
decouple email messages from conversation replies,
and use email to transport structured JSON data representing activities.
A basic activity type would be "post a message" or "post a reply".
But there are less obvious activity types,
such as "make an edit to a message that I sent earlier",
or "upvote that other message".
Those latter types affect the way that participants see a discussion,
but are not presented the same way that replies are.
I think that this idea can lead to many new applications that operate over
email in ways that we never imagined.

[Web 2.0]: http://www.cbsnews.com/news/what-is-web-20/

An important feature is that I do not have to get people to switch to a new system _en masse_.
These new-style exchanges degrade gracefully when viewed in a traditional email client.
If someone edits one of their messages after sending it,
Poodle users see the edited version with a small note that says "edited a few minutes ago".
Users on traditional email clients see the edit as a follow-up message with the new content.
Where Poodle users see +1 counts,
traditional email users see messages that just say "+1"
(or whatever text the sender has selected for their fallback "like" message).
This works because email supports multiple data parts,
including fallback presentation for clients that do not understand a new format.
Poodle messages contain a JSON part intended to be consumed by Poodle
(or other interoperable clients),
and an HTML view of the same content for traditional clients.

Poodle supports interaction modes beyond the traditional "email exchanges are
discussions" point of view.
Poodle splits out several activity types that can serve as the starting point of an interaction -
for example there is a "share a document" option".
The document might be HTML edited directly in the client,
or an uploaded file such as a spreadsheet, presentation, image, or video.
Anyone who the document is shared with can edit the document.
What really happens is that their client sends out an "edit" activity to collaborators;
but what everyone sees is that the document in their client updates with the new changes.
(And anyone can browse previous revisions of a document at any time,
because those revisions are really just email messages on their IMAP server.)
Once again, people using traditional clients see document edits as follow-up messages
with the new content in its entirety.

I have a small slide deck of screen shots from an early iteration of Poodle:
[http://sitr.us/talks/poodle/](http://sitr.us/talks/poodle/)

Keep in mind that all of the features that you see work without any new servers.
This is all just email.
The only thing that is new is a special email client (which runs locally via a downloaded app).
And everything gracefully degrades when interacting with people with regular email clients.

Going slide-by-slide:

2. Participants can edit their own post after-the-fact; each activity has +1 counts.

3. An interaction might be presented as a collaborative document instead of as a thread. In this case there are calls-to-action to edit, or link to the document. (In this example the document content is markdown; but this concept could work for any type of file: images, videos, slide decks, whatever.)

4. Linking to email messages is a much under-used feature in my opinion. There is actually already an RFC that specifies how to construct a globally-unique URI for any email message.

5. This slide shows an early iteration of the process of linking to a document from another activity. Combining collaborative documents with linking allows for a decentralized wiki that actually lives in copies in the participants' email accounts.

6. I was experimenting with features to make email more usable generally. I tried to design Poodle to make it really obvious who sees what in any exchange. Poodle uses a reply-to-all form as the default reply option, and the user must go through extra steps to reply to just one person, or to a subset of the people already participating in a discussion.

7. If someone does reply without including everyone, you get this "private aside" feature. (This works just by examining To:, From:, and Cc: fields in email messages in the discussion.) The private aside acts like a self-contained sub-discussion, interleaved with the original discussion. My hope is that this kind of feature can help to avoid embarrassing information leaks.

8. Private aside messages are interleaved time-wise with the top-level discussion. And each private aside has its own private reply form after the last message in the aside.

Somehow I missed including a slide showing another feature that I think is useful:
when someone includes a new person in the recipient list in a reply,
there is a card that appears in the discussion view that says "so-and-so joined the discussion".

I think those features work well for small discussions with a fixed set of participants.
On the roadmap is scaling up via hosted groups.
Each group has its own email address -
to start an interaction with the group you send to the group's address
(e.g. backyard-goats@raddiscussions.net).
People who join the group later have access to existing discussions and documents via archives on the group server.
This is basically just the concept of a mailing list,
but with some added usability features.
The combination of social collaboration features and groups produces something
like subreddits, or Facebook groups, or Jive communities.
Groups support the philosophy of decentralization:
anyone can start up their own group servers and have complete control over them;
anyone can bring people from outside the group into a group interaction by including them in the recipient list;
an interaction can be shared with multiple groups simultaneously;
and so on.
