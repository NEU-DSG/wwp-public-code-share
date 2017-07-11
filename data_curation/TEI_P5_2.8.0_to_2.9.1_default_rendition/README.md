# render → selector

Some time ago the TEI-C created a new mechanism for indicating default rendition. It (the new <tt>@selector</tt> mechanism) became available in 2.9.1, and the old (<tt>@render</tt>) mechanism was withdrawn as of the _Telstar_ release (version 3.2.0 of 2017-07-10).

Here are two routines for converting from the old to the new. There is no need to have two of them, the reason for separation is purely pedagogical. The <tt>simple</tt> stylesheet exists to show how easy this conversion can be in the simple case. For a simple TEI file that has a single <tt>&lt;TEI></tt> element and only has default renditions for elements in the TEI namespace this is _really easy_. It only takes 2 templates (in addition to the identity transform): 1 to add <tt>@selector</tt> to <tt>&lt;rendition></tt> and another to delete <tt>namespace</tt>.

Doing this for the general case, in which there may be multiple <tt>&lt;TEI></tt> elements, each with multiple <tt>&lt;namespace></tt> elements (from various namespaces), which namespaces may or may not also be in scope turns out to be _very hard_ (IMHO), and even then I had to concede the point that there may be a prefix definition used somewhere in the file that we can’t find.

So I have left the simple version here for those who want to puzzle through what it does and how it does it. I have left the more complicated version here for general use, and for XSLT programmers to puzzle through and improve. 

## Warnings for Simple Version

1. Deletes <tt>&lt;namespace></tt> without checking to see if there is useful information in there or not. The more complex version is smarter about this. If you do not have any prose, but just counts and counts-with-ID in your <tt>&lt;namespace></tt>, you can easily re-generate it using [Generate_tagsDecl_P5](https://wiki.tei-c.org/index.php/Generate_tagsDecl_P5.xslt). If you actually have useful content in any of your <tt>&lt;tagUsage></tt> elements, **do not** use the simple version. 

2. Deletes any existing <tt>@selector</tt> attributes, so **do not** run it on files that already use the new mechanism.

3. Does not take into account that there may be whitespace around the value of an <tt>@xml:id</tt> or <tt>@gi</tt>.
