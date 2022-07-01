# Rapid Insertion

In late 2018 we discovered that
one of our WWO files had 90 pages
in which the encoder had not entered any indication
of the line breaks — not even a line feed,
let alone a TEI `<lb>` element.

In order to quickly fix this, we developed a
computer-assisted 2-person editing process.
We determined (from the pages that did have `<lb>`s encoded)
that, on average, each line in this text had 8.446
words.

We then wrote a program (available here) that
when run inserted a linefeed, the requisite number
of spaces, & an `<lb>`, and then popped the
cursor forward 8 words. This last bit was essential
— it means that as soon as this command was
entered, the cursor (and the editors eyes)
were immediately close to, or perhaps exactly
on, the right spot for the next `<lb>` insertion.

We then “bound” this program to a particular key.
This meant that typing this one key executed the
command.
(I chose the key
‘/’, but which key is not really important — in
Emacs any key can be bound to any command.)

We then had two people sit down with the text: one
reading our (copy of) the source, and one at the
keyboard. The reader simply read the first word of
each line (or the first few if context was needed,
e.g. if it was a very common word like “the”);
the keyboarder then moved the cursor to the
correct position if it wasn’t there already,
and typed the ‘/’ key.

We quickly discovered that the encoder had also
silently elided soft hyphens, and thus developed a
second routine (which I bound to ‘-’) which
inserted the character we use for soft hyphen, then
a newline, then the requisite number of spaces, & the
`<lb>`, and then popped the cursor forward 8 words.

See [our blog post](https://wwp.northeastern.edu/blog/?p=1109) about this
topic.

### Addendum

A similar case arose in June 2022, and this same solution worked
beautifully. Only this time (due to the pandemic) it was done over a
video conference call with screen sharing. We inserted 1263 `<lb>`
elements in roughly 1.5 hours, for ~842 `<lb>`s per hour (or an
average of 1 `<lb>` every ~4¼ s), and corrected several other errors
along the way.

