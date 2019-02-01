xquery version "3.1";

  module namespace wft="http://www.wwp.northeastern.edu/ns/fulltext";
  declare boundary-space preserve;
(:  NAMESPACES  :)
  (:declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";:)
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
  declare namespace werr="http://www.wwp.northeastern.edu/ns/err";

(:~
    
  :)
 
(:  VARIABLES  :)
  

(:  FUNCTIONS  :)
  declare function wft:anchor-notes($xml as node()) {
    copy $modXml := $xml
    modify 
      for $unmovedNote in $modXml//wwp:hyperDiv/wwp:notes/wwp:note[@xml:id][node()]
      let $modNote :=
        element wwp:note {
          $unmovedNote/@*
        }
      let $noteRef := '#' || $unmovedNote/@xml:id
      let $anchor := $modXml//*[@corresp eq $noteRef]
      let $targetTextNode :=
        ( $anchor/following::text()[matches(.,'\s')] )[1]
      let $textWithNote :=
        let $tokenStr := tokenize($targetTextNode, '\s+')
        return
          (
            $tokenStr[1], " ",
            $unmovedNote, " ",
            string-join(tail($tokenStr), " ")
          )
      return
        if ( exists($targetTextNode) ) then
        (
          replace node $unmovedNote with $modNote,
          replace node $targetTextNode with $textWithNote
        )
        else ()
    return $modXml
  };
