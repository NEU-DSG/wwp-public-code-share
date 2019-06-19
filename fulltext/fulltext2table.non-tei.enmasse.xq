xquery version "3.1";

(:~
 : A script to strip out the text from a TEI document, while retaining some metadata 
 : from the header. This version of fulltext2table.xq can be used to generate one 
 : table per TEI document, using an 'XML with XQuery' transformation to dynamically 
 : change the context node.
 :
 : The $ELEMENTS variable gives control over which TEI elements should be output via 
 : XPath. To use morphadorned XML, change $is-morphadorned to true().
 :
 : @return tab-delimited text
 :
 : @author Ashley M. Clark and Sarah Connell, Northeastern University Women Writers Project
 : @see https://github.com/NEU-DSG/wwp-public-code-share/tree/master/fulltext
 : @version 1.0
 :

 :  2019-06-19: v1.0. Created from fulltext2table.enmasse.xq.
 :)

(:  NAMESPACES  :)
(: declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";:)
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare namespace werr="http://www.wwp.northeastern.edu/ns/err";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
(:  OPTIONS  :)
  declare option output:method "text";

  declare context item external;

(:  VARIABLES  :)
  (: Set $return-only-words to 'true()' to remove the header row and file metadata 
    entirely. Only that file's words are returned. :)
  declare variable $return-only-words as xs:boolean external := true();
    
    
(:  FUNCTIONS  :)
  
  
  (: Get the normalized text content of an element. :)
  declare function local:get-text($element as node()) as xs:string {
    replace($element, '\s+', ' ')
  };
  
  (: Use tabs to separate cells within rows. :)
  declare function local:make-cells-in-row($sequence as xs:string*) {
    string-join($sequence, '&#9;')
  };
  (: Separate each row with a newline. :)
  declare function local:make-rows-in-table($sequence as xs:string*) {
    string-join($sequence, '&#13;')
  };
  
  (: Remove certain named elements from within an XML fragment. :)
  declare function local:omit-descendants($node as node(), $element-names as xs:string*) as node()? {
    if ( empty($element-names) ) then $node
    else if ( $node[self::text()] ) then text { $node }
    else if ( $node[self::*]/local-name() = $element-names ) then ()
    else
      element { $node/name() } {
        $node/@*,
        for $child in $node/node()
        return local:omit-descendants($child, $element-names)
      }
  };

(:Add a space after certain named elements:)
    declare function local:add-spaces($node as node(), $element-names as xs:string*) as node()* {
     if ( empty($element-names) ) then $node
    else if ( $node[self::text()] ) then text { $node }
    else
      (element { $node/name() } {
        $node/@*,
        for $child in $node/node()
        return local:add-spaces($child, $element-names)}, 
        if ( $node[self::*]/local-name() = $element-names ) then text{" "}
        else ()
        )
    };

(:  MAIN QUERY  :)

let $file := tokenize(/base-uri(),'/')[last()]
let $headerRow := ('full text')
let $allRows := 
  (
    if ( $return-only-words ) then ()
    else local:make-cells-in-row($headerRow)
    ,
    let $Doc := /*
    
  (: Change $ELEMENTS to reflect the elements for which you want full-text 
      representations. :)
    let $ELEMENTS := $Doc
  (: Below, add the names of elements that you wish to add a space after from within $ELEMENTS.
      For example, 
        ('page')
  :)
    let $ELEMENTS2SPACE := ('page')
      (: Below, add the names of elements that you wish to remove from within $ELEMENTS.
      For example, 
        ('castList', 'elision', 'figDesc', 'label', 'speaker')
  :)
    let $ELEMENTS2OMIT := ()
    let $fulltext := 
      let $wordSeq := for $element in $ELEMENTS
                      let $spaced := local:add-spaces($element, $ELEMENTS2SPACE)
                      let $abridged := local:omit-descendants($spaced, $ELEMENTS2OMIT)
                      return 
                        local:get-text($abridged)
      let $wordSeparator := ' '
      return normalize-space(string-join(($wordSeq), $wordSeparator))
    (: The variable $optionalMetadata will be empty if $return-only-words is 'true()'. :)
    let $dataSeq := ( $fulltext )
    order by $file
    return 
      if ( $fulltext ne '' ) then 
        local:make-cells-in-row($dataSeq)
      else ()
  )
return local:make-rows-in-table($allRows)
