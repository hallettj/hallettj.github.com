---
layout: post
title: "Kinesis Advantage with DSA keycaps"
date: 2014-05-19
comments: true
---

{% img https://lh4.googleusercontent.com/MPfjOyaNmMKZRL36XEekqRiaeoHcUFLQLN-Kx62XKbgN=w1024-h576-no%}

I now have a Kinesis Advantage keyboard for use at work.
I have been feeling some wrist strain recently;
and some of my coworkers were encouraging me to try one.
So I borrowed a Kinesis for a week, and found that I really liked it.
The contoured shape makes reaching for keys comfortable;
I find the column layout to be nicer than the usual staggered key arrangement;
and between the thumb-key clusters and the arrow keys,
there are a lot of options for mapping modifier keys that are in easy reach.

{% imgcap /images/kinesis-dsa/IMG_20140515_175553491_HDR.jpg Kinesis Advantage, before modification %}

But I really like the PBT keycaps on my [Leopold][].
I would not enjoy going back to plain, old ABS.
I also don't want my keyboard to be just like every other Kinesis.
So I decided to get replacement keycaps.

[Leopold]: http://imgur.com/a/XZ2hG

I did some research on buying PBT keycaps with the same profiles as the stock Kinesis keys.
I assumed that I would end up getting blank keycaps -
putting together a set with legends appropriate for a Kinesis seemed like it would be a painful undertaking,
since there don't seem to be any sets made specifically for the Kinesis.

Most keyboards - including the Kinesis Advantage - use what is called a DCS profile,
where the keys in each row have different heights and angles.
(That does not include laptop keyboards,
or island-style keyboards such as the ones that Apple sells.
Those are in their own categories.)
{% imgcap left /images/kinesis-dsa/angle3.jpg DCS family: medium profile, cylindrical top, sculptured. <br> Image from Signature Plastics. %}
Input Nirvana on Geekhack has a post with [a list of all necessary keycap sizes and profiles][blank-caps]
to reproduce the arrangement on a stock Kinesis.
It is possible to order these individually from Signature Plastics;
but their inventory for _à la carte_ orders varies depending on what they have left over
from production of large batches.
When I checked, SP did not have any row 5 PBT keycaps available.
I got the impression that building a custom DCS set would be somewhat difficult.

[blank-caps]: http://geekhack.org/index.php?topic=29875.0

Then I saw prdlm2009 on Deskthority suggest that [DSA profile keycaps work well on a Kinesis][dsa-on-kinesis].
DSA is a uniform profile -
every key has the same height and angle.
It makes everything much simpler when dealing with unusual keyboard layouts,
or unusual keyboards.
{% imgcap right /images/kinesis-dsa/angle2.jpg DSA family medium profile, spherical top, non-sculptured. <br> Image from Signature Plastics. %}
DSA also features spherical tops.
If you look at the keys on a typical keyboard, you can see that the top curves up on the left and right sides -
as though someone had shaped them around a cylinder.
The tops of DSA keys are spherical; as though shaped around a large marble.
So the keys cup the fingertips from all sides.

[dsa-on-kinesis]: http://deskthority.net/photos-videos-f8/kinesis-advantage-with-spherical-keycaps-dsa-family-for-sp-t4842.html

Signature Plastics sells a variety of nice, blank DSA keycap sets.
I did not order the optimal combination of keycap sets;
but now I have a better idea of what that combination is.
The key count on an Advantage is:

* 56 – 1x keys (optionally including two homing keys)
* 8 – 1.25x keys
* 4 – 2x keys

1x, 2x, etc. refers to the lengths of the keys.

One can get everything except the 1.25x keys with one [ErgoDox Base set][dsa-blank-set]
and two [Numpad sets][numpad-set].
The Numpad sets seem to be the cheapest way to get all 4 2x keycaps, along with additional 1x caps.
The only set that includes 1.25x caps is the Standard Modifier set,
which includes 7 of them.
(So close!)
I recommend ordering the 1.25x keycaps individually from the [blank keycap inventory][].

[dsa-blank-set]: http://keyshop.pimpmykeyboard.com/products/full-keysets/dsa-blank-numpad-sets-1
[numpad-set]: http://keyshop.pimpmykeyboard.com/products/full-keysets/dsa-blank-numpad-sets
[blank keycap inventory]: http://www.keycapsdirect.com/key-capsinventory.php

{% imgcap /images/kinesis-dsa/IMG_20140515_180022543_HDR.jpg stock Kinesis keycaps (left), DSA keycaps (right) %}

The keycaps from SP are much thicker than the stock keycaps.
And they are made from PBT plastic, which is denser than the more common keycap material, ABS.
What I like most about PBT caps is their texture.
The tops of the keys are usually slightly rough, somewhat pebbly.
It gives a little bit of grippiness,
and feels soothing on my fingers compared to featureless, flat plastic.
I also think that the sound of PBT keys being pressed is nicer.
It is slightly quieter, with a somewhat deeper tone.

{% imgcap /images/kinesis-dsa/IMG_20140515_182527431_HDR.jpg All of the stock keycaps have been removed, revealing Cherry MX Brown switches. %}

The Kinesis Advantage comes with either [Cherry MX Brown][brown] or [Cherry MX Red][red] switches.

[brown]: http://deskthority.net/wiki/Cherry_MX_Brown
[red]: http://deskthority.net/wiki/Cherry_MX_Red

For anyone wondering how to remove keycaps from a keyboard with Cherry MX switches, here is a [video][removal].
What the video does not mention is that it is a good idea to wiggle the keycap puller while pulling up on the keycap.
That helps to avoid pulling with too much force, which could break a switch.

[removal]: https://www.youtube.com/watch?v=FlUYCAZNNOw

I have another keyboard that also has Cherry MX Brown switches,
and I really liked the change in key feel after installing o-rings.
O-rings make typing a little quieter,
and add some springiness to the bottom of the key travel.
A tradeoff is that they reduce the length of key travel a bit.

{% imgcap /images/kinesis-dsa/IMG_20140515_182759811.jpg installing o-rings in the new keycaps %}

I used [40A-R o-rings from WASD][o-rings], which are relatively thick and soft.
But when I tried these out with the DSA keycaps I could not discern any difference
between a key with an o-ring and one without.

Comparing the underside of a DSA keycap to a typical DCS keycap reveals the issue:

[o-rings]: http://www.wasdkeyboards.com/index.php/cherry-mx-rubber-o-ring-switch-dampeners-125pcs.html#ad-image-0

{% imgcap /images/kinesis-dsa/IMG_20140515_180233205.jpg blank DSA keycaps from SP (top), keycaps from a Leopold FC660M (bottom) %}

DCS keycaps have cross-shaped supports under the cap,
which contact the top of the switch housing when the key is fully depressed.
O-rings sit between those supports and the switch housing,
absorbing some force from contact.
But the DSA keycaps lack those supports.
That means that the switch can reach the bottom of its travel
before the underside of the keycap contacts the switch housing.

I found that doubling up o-rings pushed the rubber high enough to be effective.
But I was concerned that two o-rings shorted key travel too much
and introduced too much squishiness.
In the end I left the o-rings out entirely.
I may take another shot using either thinner, firmer o-rings,
or with small washers in place of a second o-ring.

{% imgcap /images/kinesis-dsa/IMG_20140515_183902311.jpg two o-rings installed in one keycap %}

When I ordered my keycaps I got one ErgoDox Base set and one ErgoDox Modifier set.
I did not do enough checking - I assumed that the 1.5x keys in the Modifier set
would fit in the Kinesis.
But it turns out that the keys in the leftmost and rightmost columns of the Kinesis
take 1.25x keycaps.
The larger keycaps do not fit.

{% imgcap /images/kinesis-dsa/IMG_20140515_190504044_HDR.jpg Whoops!  That was supposed to be a 1.25x key, not a 1.5x. %}

I have ordered some appropriately sized keycaps.
In the meantime, I am using 1x keycaps in the 1.25x positions.

{% imgcap /images/kinesis-dsa/IMG_20140515_190751151_HDR.jpg stock 1.25x Tab key next to its intended, blank replacement %}

Even though the DSA keycaps are not the same shape as the stock caps,
they fit quite well on the Kinesis.
There are just two slightly problematic spots.
The photo below shows the one key that comes into contact with the edge of the keyboard case when it is not depressed.
Thankfully the operation of the key does not seem to be affected.

{% imgcap /images/kinesis-dsa/IMG_20140515_190931944.jpg The fit is tight in this corner. %}

Due to small differences in switch positioning,
the key in the same position in the other well has a little bit of clearance.

The other problem is that two of my 2x keys overlap very slightly.
When I press the one on the right there is sometimes an extra *click*
as it pushes past its neighbor.

{% imgcap /images/kinesis-dsa/IMG_20140515_194515105.jpg There is not quite enough space between these two keys. %}

I am thinking of sanding down the corners of these keys a little bit to fix the problem.

This is another case where there is no problem with the keys in the same positions on the other side of the board.
It seems that the switches in the left thumb cluster just happen to be
a little too close together on my board.

{% imgcap /images/kinesis-dsa/IMG_20140515_194232464_HDR.jpg All done! %}

Since I had to use 1u keycaps for the leftmost and rightmost columns,
I ended up not having enough keycaps to replace the two keycaps in the top of each thumb cluster.
But I think that having tall keycaps there makes them easier to press -
those positions are a bit difficult to reach otherwise.
So I may just keep the stock caps on those keys.
Or I might try to get tall, DCS profile, PBT caps for those positions.

{% imgcap /images/kinesis-dsa/IMG_20140515_194415103_HDR.jpg closeup of one of the wells to show key spacing %}

The other positions where I think that DSA does not work really well are the four keys in the bottom row of each well.
I curl my fingers down to reach those;
and I tend to either hit the edges of the keys,
or to press them with my fingernail instead of with my finger.
The stock keycaps for those positions are angled toward the center of the well,
making it easier to reach the tops of the keys.

Those points aside,
I am very pleased with how these new keycaps worked out!
The DSA profile is quite comfortable.
I love the texture of the PBT keycaps.
And they make a more pleasant sound than the thinner ABS caps that came with the board.

{% imgcap /images/kinesis-dsa/IMG_20140518_185154.jpg shoe for science! %}
