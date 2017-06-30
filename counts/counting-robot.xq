xquery version "3.0";

(:~
 : A starter script for counting values and phenomena in XML using XPath and XQuery.
 :
 : @return tab-delimited text
 :
 : @author Ashley M. Clark, Northeastern University Women Writers Project
 : @version 1.0
 :
 :  2017-06-30: v1.0. Added this header and changelog.
 :  2017-04-28: Moved script from Gist to wwp-public-code-share git repository.
 :  2017-04-13: Added default element namespace declaration.
 :  2016-05-24: Added $sortWithArticles toggle.
 :  2016-02-23: Added $sortByCount toggle.
 :  2016-01-13: Created.
 :)

(: NAMESPACES :)
declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
(: OPTIONS :)
declare option output:item-separator "";
declare option output:method "text";

(: VARIABLES - SORTING :)
  (: Change $sortByCount to false() in order to sort by result value. :)
  declare variable $sortByCount := true();
  
  (: Change $sortWithArticles to true() in order to sort results with any 
    leading articles. This will not affect your results, just the order in 
    which they display. :)
  declare variable $sortWithArticles := false();

(: VARIABLES - QUERYING :)
  (: Create variables referencing the files or folders you wish to query. :)
    (:  To get one file:       doc('FILEPATH/FILENAME')                   :)
    (:  To get one directory:  collection('FILEPATH/?select=*.xml')       :)
    (:  To get more than one:  ( DOC | DOC | DIR )                        :)
  declare variable $DESCRIPTIVE_NAME := collection('file:///Users/ashleyclark/WWP/textbase/distribution/?select=*.xml');
  
  (: Change this to your XPath query. (Or your XQuery!) :)
    (:  For example: $VARIABLE/XPATH                    :)
  declare variable $query := $DESCRIPTIVE_NAME//text//title;


(: FUNCTIONS :)
(: ...documentation coming soon... :)

  (:
   : HEY! LISTEN: The code below powers your report-making robot. For most 
   : queries, you won't need to change anything after this point. 
   :)

(: This function strips out leading articles from a string value for sorting. 
  It also lower-cases the string, since capital letters will have an effect on 
  sort order. :)
declare function local:get-sortable-string($str as xs:string) {
  replace(lower-case(normalize-space($str)), '^(the|an|a|la|le|el|lo|las|los) ','')
};

(: THE COUNTING ROBOT :)
let $distinctValues := distinct-values($query)
let $listOfCounts :=  for $value in $distinctValues
                      let $count := count($query[. eq $value])
                      let $sortVal := if ( not($sortWithArticles) and $value castable as xs:string ) then 
                                        local:get-sortable-string($value)
                                      else $value
                      order by
                        if ( $sortByCount ) then () else $sortVal,
                        $count descending, 
                        $sortVal
                      return 
                        (: Tab-delimited data within rows. :)
                        concat($count, '&#9;', $value)
return 
  (: Separate each row with a newline. :)
  string-join($listOfCounts,'&#13;')
