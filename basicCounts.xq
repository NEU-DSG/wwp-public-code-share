xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";

(: Change this to the match the right filepath. :)
declare variable $collection := collection('file:///Users/ashleyclark/WWP/dev/reception/on_deck/?select=*.xml');
(: Change this to your XPath query. :)
declare variable $query := $collection//tei:keywords/tei:term;

let $distinctValues := distinct-values($query)
let $listOfCounts :=  for $value in $distinctValues
                      let $count := count($query[. eq $value])
                      (:order by $count descending, $value:)
                      order by $value
                      return 
                        (: Tab-delimited data within rows. :)
                        concat($value, '&#9;', $count)
return 
  (: Separate each row with a newline. :)
  string-join($listOfCounts,'&#13;')
