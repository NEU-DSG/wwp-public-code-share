xquery version "3.1";

  module namespace wft="http://www.wwp.northeastern.edu/ns/fulltext";
  declare boundary-space preserve;
(:  NAMESPACES  :)
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
  declare namespace werr="http://www.wwp.northeastern.edu/ns/err";

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
 : @version 0.1
 :
 :  2019-02-01: Created this library for use by the "fulltext2table" XQueries, 
 :    both at v.2.0.
 :)


(:  FUNCTIONS  :)
  
  (: Given some WWP-encoded XML, move notes from the <wwp:hyperDiv> to their anchors. 
    Care is taken not to place a note in the middle of a word. :)
  declare function wft:anchor-notes($xml as node()) {
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
