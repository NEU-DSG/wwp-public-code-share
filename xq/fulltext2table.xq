xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";

  declare variable $ft-wwo := collection('./fulltext-wwo?select=*.xml');
  
(: Use tabs to separate cells within rows. :)
declare function local:make-cells-in-row($sequence as xs:string*) {
  string-join($sequence, '&#9;')
};
(: Separate each row with a newline. :)
declare function local:make-rows-in-table($sequence as xs:string*) {
  string-join($sequence, '&#13;')
};

let $headerRow := ('tr #', 'author pid', 'pub date', 'full text')
let $allRows := 
  (
    local:make-cells-in-row($headerRow),
    
    for $text in $ft-wwo/wwp:TEI
    let $header := $text//wwp:teiHeader
    let $idno := $header//wwp:publicationStmt/wwp:idno[@type eq 'WWP']/data(.)
    let $author := $header//wwp:titleStmt/wwp:author[1]/wwp:persName/@ref/substring-after(data(.),'p:')
    let $pubDate := 
      let $date := $header//wwp:sourceDesc//wwp:date
      return 
        if ( $date[@from][@to] ) then
          concat( $date/@from/data(.), '-', $date/@to/data(.) )
        else $date/@when/data(.)
    (: Change $ELEMENTS to reflect the elements for which you want full-text representations. :)
    let $ELEMENTS := $text/wwp:text
    let $fulltext := normalize-space(string-join(($ELEMENTS),' '))
    let $dataSeq := ( $idno, $author, $pubDate, $fulltext )
    return local:make-cells-in-row($dataSeq)
  )
return local:make-rows-in-table($allRows)
