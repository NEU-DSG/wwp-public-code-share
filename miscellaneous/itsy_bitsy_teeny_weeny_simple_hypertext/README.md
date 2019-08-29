# IBTWSH
## Itsy Bitsy Teeny Weeny Simple Hypertext

This is a TEI ODD implementation of John Cowan’s [Itsy Bitsy Teeny Weeny Simple Hypertext DTD, draft 5](http://vrici.lojban.org/~cowan/XML/ibtwsh.dtd). It was written in 2009 as a proof-of-concept in writing a completely non-TEI language in TEI ODD. As the concept was proven, it has not been updated since. Thus there are quite a few ancient practices represented herein. Furthermore, there are several problems with the schema itself which have never been addressed.

John has since created a version 6 of this language, and provides schemas in various languages. So this is the place to go if you are interested in an example of using ODD to create a free-standing markup language; if you are actually interested in the Itsy Bitsy Teeny Weeny Simple Hypertext language, search for it on [John’s page](http://vrici.lojban.org/~cowan/).

The most egregious problem is that the original draft includes an element named <XML>, which is by definition not well-formed XML. (XML names may not start with a string matching `[Xx][Mm][Ll]`.)
