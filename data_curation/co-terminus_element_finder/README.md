# co-terminus element finder

A pair of elements are “co-terminus” if they both start and end in the
same place. This routine finds instances of truly co-terminus elements
(called “completely co-terminus”) and also instances that are not
quite truly co-terminus, but close (called “almost completely
co-terminus” and “nearly co-terminus”).

When determining whether elements are co-terminus or not, any element
or text nodes are considered, but comments and proccessing
instructions are ignored.

## comletely co-terminus

The two elements have exactly the same textual content.
E.g.,
~~~xml
  <author><persName key="sbauman.emt">Syd Bauman</persName></author>
~~~
In the following, from the WWP’s bacon.sermonelec.xml, the `<docRole>`
and `<persName>` elements are completely co-terminus.
~~~xml
  <titlePart rend="face(roman)align(center)pre(¶)" type="main"><hi rend="case(allcaps)">Sermons</hi><lb/><hi rend="face(blackletter)">of</hi> <docRole type="author"><persName rend="slant(italic)">Barnardine Ochyne</persName></docRole>,</titlePart>
~~~

## almost completely co-terminus

The two elements have the same textual content except for whitespace.
E.g.,
~~~xml
  <author> <persName key="sbauman.emt">Syd Bauman</persName> </author>
~~~
In the following, from the WWP’s wollstonecraft.sweden.xml, the two
elements are almost completely co-terminus.
~~~xml
      <closer>
         <salute rend="align(right)indent(2)">Adieu!</salute>
      </closer>
~~~

## nearly co-terminus

If you were to delete any of a set of punction strings from the end of
the parent element, then the two elements would be almost completely
or completely co-terminus.
E.g.,
~~~xml
  <author> <persName key="sbauman.emt">Syd Bauman</persName> ! </author>
~~~
The list of punctuation strings is hard-coded as
- “.”
- “:”
- “,”
- “―”
- “――”
- “—”
- “,.”
- “.,”
- “ , .”
- “ . ,”
