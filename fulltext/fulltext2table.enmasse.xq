xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";

  declare context item external;
  
(: Use tabs to separate cells within rows. :)
declare function local:make-cells-in-row($sequence as xs:string*) {
  string-join($sequence, '&#9;')
};
(: Separate each row with a newline. :)
declare function local:make-rows-in-table($sequence as xs:string*) {
  string-join($sequence, '&#13;')
};

let $headerRow := ('filename', 'tr #', 'author pid', 'pub date', 'full text')
let $allRows := 
  (
    local:make-cells-in-row($headerRow),
    
    let $file := tokenize(./base-uri(),'/')[last()]
    let $header := //wwp:teiHeader
    let $idno := $header//wwp:publicationStmt/wwp:idno[@type eq 'WWP']/data(.)
    let $author := $header//wwp:titleStmt/wwp:author[1]/wwp:persName/@ref/substring-after(data(.),'p:')
    let $pubDate := 
      let $date := $header//wwp:sourceDesc//wwp:date
      return 
        if ( $date[@from][@to] ) then
          concat( $date/@from/data(.), '-', $date/@to/data(.) )
        else $date/@when/data(.)
    (: Change $ELEMENTS to reflect the elements for which you want full-text representations. :)
    let $ELEMENTS := //wwp:text
    let $fulltext := 
      let $wordSeq := for $element in $ELEMENTS
                      return $element/normalize-space(.)
      return normalize-space(string-join(($wordSeq),' '))
    let $dataSeq := ( $file, $idno, $author, $pubDate, $fulltext )
    return 
      if ( $fulltext ne '' ) then 
        local:make-cells-in-row($dataSeq)
      else ()
  )
return local:make-rows-in-table($allRows)
