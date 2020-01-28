xquery version "3.1";

module namespace wft="http://www.wwp.northeastern.edu/ns/fulltext";

  declare boundary-space preserve;
(:  NAMESPACES  :)
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";

(:~
 : An XQuery library for functions useful for (but nonessential to) creating plain 
 : text out of XML.
 :
 : This library makes use of XQuery Update syntax, and so cannot be run with Saxon 
 : HE or PE. (It *can* be run with Saxon EE, as long as it is configured to use the 
 : XQuery Update and "Linked Tree" model options.)
 :
 : @author Ashley M. Clark, Northeastern University Women Writers Project
 : @see https://github.com/NEU-DSG/wwp-public-code-share/tree/master/fulltext
 : @version 0.2
 :
 : Changelog:
 :  2020-01-28: v0.3. Made wft:move-anchors() accept empty sequences.
 :  2019-07-26: v0.2. Added MIT license. Removed "werr" namespace declaration.
 :  2019-02-01: Created this library for use by the "fulltext2table" XQueries, 
 :    both at v.2.0.
 :
 : MIT License
 :
 : Copyright (c) 2019 Northeastern University Women Writers Project
 :
 : Permission is hereby granted, free of charge, to any person obtaining a copy
 : of this software and associated documentation files (the "Software"), to deal
 : in the Software without restriction, including without limitation the rights
 : to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 : copies of the Software, and to permit persons to whom the Software is
 : furnished to do so, subject to the following conditions:
 :
 : The above copyright notice and this permission notice shall be included in all
 : copies or substantial portions of the Software.
 :
 : THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 : IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 : FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 : AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 : LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 : OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 : SOFTWARE.
 :)


(:  FUNCTIONS  :)
  
  (: Given some WWP-encoded XML, move notes from the <wwp:hyperDiv> to their anchors. 
    Care is taken not to place a note in the middle of a word. :)
  declare function wft:anchor-notes($xml as node()?) {
    (: Create a new, deep-copy of the given XML. This function won't write over the 
      original tree. :)
    copy $modXml := $xml
    modify 
      (: Create XQ Update instructions for each <note> that wasn't already moved by 
        fulltext.xsl . :)
      for $unmovedNote in $modXml//wwp:hyperDiv/wwp:notes/wwp:note[@xml:id][node()]
      let $modNote :=
        element wwp:note {
          $unmovedNote/@*
        }
      (: Identify the "anchor" where the current note should appear. :)
      let $noteRef := '#' || $unmovedNote/@xml:id
      let $anchor := $modXml//*[@corresp eq $noteRef]
      (: Identify the first text node after the anchor that also contains whitespace. :)
      let $targetTextNode :=
        ( $anchor/following::text()[matches(.,'\s')] )[1]
      (: Split the target text node so words enclose the note. :)
      let $textWithNote :=
        let $tokenStr := tokenize($targetTextNode, '\s+')
        return
          (
            $tokenStr[1], " ",
            $unmovedNote, " ",
            string-join(tail($tokenStr), " ")
          )
      return
        (: Only move the <note> if a text node was identified to "contain" it. :)
        if ( exists($targetTextNode) ) then
        (
          replace node $unmovedNote with $modNote,
          replace node $targetTextNode with $textWithNote
        )
        else ()
    (: Return the modified copy, with <wwp:note>s moved. :)
    return $modXml
  };
