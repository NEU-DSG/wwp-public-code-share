xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
declare namespace oxy="http://www.oxygenxml.com/ns/report";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";

(: Sorting options :)
declare variable $sortByCount := true();

(: Change this to the match the right filepath. :)
declare variable $document := doc('file:///Users/ashleyclark/WWP/dev/reception/distribution/periodicals.xml');
declare variable $collection := collection('file:///Users/ashleyclark/WWP/dev/reception/on_deck/?select=*.xml');

(: Change this to your XPath query. :)
declare variable $query := $collection//tei:keywords/tei:term;

(: The code below powers your report-making robot. :)
let $distinctValues := distinct-values($query)
let $listOfCounts :=  for $value in $distinctValues
                      let $count := count($query[. eq $value])
                      order by
                        if ( $sortByCount ) then () else $value,
                        $count descending, 
                        $value
                      return 
                        (: Tab-delimited data within rows. :)
                        concat($count, '&#9;', $value)
return 
  (: Separate each row with a newline. :)
  string-join($listOfCounts,'&#13;')
