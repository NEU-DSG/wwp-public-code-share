xquery version "3.0";

module namespace ctab="http://www.wwp.northeastern.edu/ns/count-sets/functions";
(:  NAMESPACES  :)
  declare namespace map="http://www.w3.org/2005/xpath-functions/map";

(:~
 : A library of XQuery functions for manipulating the tab-delimited text output of 
 : the counting robot (counting-robot.xq), using naive set theory.
 :
 : The main functions are:
 :
 :   * ctab:get-union-of-reports( ($filenameA, $filenameB, $ETC) )
 :     - the union of reports A through N in a sequence (including adding up the counts)
 :   * ctab:get-union-of-rows( ($rowA1, $rowB1, $ETC) )
 :     - the union of all rows in a sequence (including adding up the counts)
 :
 :   * ctab:get-intersection-of-reports( ($filenameA, $filenameB, $ETC) )
 :     - the intersection of reports A through N, or, only the data values which 
 :        occur once per report (including adding up the counts)
 :
 :   * ctab:get-set-difference-of-reports($filenameA, $filenameB)
 :     - all data values in report(s) A where there isn't a corresponding value in 
 :        report(s) B
 :     - both A and B can be a sequence of filenames rather than a single string; 
 :        the union of those sequences will be applied automatically
 :   * ctab:get-set-difference-of-rows( ($rowA1, $rowA2, $ETC), ($rowB1, $rowB2, $ETC) )
 :     - all data values in the sequence of rows A where there isn't a corresponding 
 :        value in sequence of rows B
 :
 : @author Ashley M. Clark, Northeastern University Women Writers Project
 : @see https://github.com/NEU-DSG/wwp-public-code-share/tree/master/counting_robot
 : @version 1.5.2
 :
 :  2020-08-28: v1.5.2. Ensured that ctab:get-union-of-reports() and 
 :    ctab:get-union-of-rows() can handle empty sequence parameters. Thanks for reporting,
 :    Laura Johnson!
 :  2020-04-21: v1.5.1. Added ctab:escape-for-matching(), which makes functions such as
 :    ctab:create-row-match-pattern() more robust. Ensured ctab:get-union-of-rows() can
 :    handle reports with more than two columns, by using part of the first matching row.
 :    (The reports must still have a number in column 1 and a distinct value in column 2.)
 :  2020-04-01: v1.5.0. Added ctab:report-to-map().
 :  2020-03-03: v1.4.1. Changed ctab:get-counts() such that the $query parameter can be 
 :    an empty sequence. Moved the module namespace declaration above the header, for 
 :    convenience when copying the URI.
 :  2019-09-04: v1.4. Added MIT license. Removed unused namespace declaration for output 
 :    serialization. Slight reformatting.
 :  2019-04-25: v1.3. Updated GitHub link.
 :  2018-12-20: Added link to GitHub.
 :  2018-08-01: v1.2. Added ctab:get-counts(), three function versions of 
 :    counting-robot.xq. Also added ctab:get-sortable-string() to support 
 :    ctab:get-counts().
 :  2017-07-25: v1.1. Made ctab:join-rows() permissive of an empty sequence of rows 
 :    (a blank report).
 :  2017-06-30: v1.0. Added ctab:get-intersection-of-reports(), 
 :    ctab:create-row-match-pattern(), and this header.
 :  2017-05-05: Created.
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

(:  VARIABLES  :)
  declare variable $ctab:tabChar      := '&#9;';
  declare variable $ctab:newlineChar  := '&#13;';
  declare variable $ctab:nonsortRegex := '^(the|an|a|la|le|de|del|el|lo|las|los) ';


(:  FUNCTIONS  :)

  (:~
    Given a sequence of values, return the number of times each distinct value 
    occurs. The result is a tab-delimited report. By default, the rows of the report 
    are sorted by count, then alphabetically by value (with any nonsorting articles 
    removed). 
   :)
  declare function ctab:get-counts($query as item()*) {
    ctab:get-counts($query, true())
  };
  
  (:~
    Given a sequence of values, return the number of times each distinct value 
    occurs. The result is a tab-delimited report, sorted either by count, or 
    alphabetically by value. By default, any leading articles are removed from values. 
   :)
  declare function ctab:get-counts($query as item()*, $sort-by-count as xs:boolean) {
    ctab:get-counts($query, $sort-by-count, true())
  };
  
  (:~
    Given a sequence of values, return the number of times each distinct value 
    occurs. The result is a tab-delimited report, sorted either by count, or 
    alphabetically by value. By default, any leading articles are removed from values, 
    which presumes that the value is a string of text. The $remove-unsortable-articles 
    parameter allows sorting with leading articles included. 
   :)
  declare function ctab:get-counts($query as item()*, $sort-by-count as xs:boolean, 
     $remove-unsortable-articles as xs:boolean) {
    let $distinctValues := distinct-values($query)
    let $listOfCounts :=  for $value in $distinctValues
                          let $count := count($query[. eq $value])
                          let $sortVal := 
                            if ( $remove-unsortable-articles and $value castable as xs:string ) then 
                              ctab:get-sortable-string(xs:string($value))
                            else $value
                          order by
                            if ( $sort-by-count ) then () else $sortVal,
                            $count descending, 
                            $sortVal
                          return 
                            (: Tab-delimited data within rows. :)
                            concat($count, $ctab:tabChar, $value)
    return 
      (: Separate each row with a newline. :)
      ctab:join-rows($listOfCounts)
  };
  
  
  (:~
    Given a number of string values, create a regular expression pattern to match 
    rows which contain those cell values. Reserved characters in the strings will be
    escaped.
   :)
  declare function ctab:create-row-match-pattern($values as xs:string+) as xs:string {
    let $regexValues := ctab:escape-for-matching($values)
    let $group := string-join($regexValues, '|')
    return concat('\t(',$group,')(\t.*)?$')
  };
  
  (:~
    Given any number of string values, format each so that it can be used as the 
    pattern in a regular expression. Reserved characters are escaped.
   :)
  declare function ctab:escape-for-matching($values as xs:string*) 
     as xs:string* {
    for $str in $values
    return replace($str, '([\$\^()\[\]\.\\|*?+{}])', '\\$1')
  };
  
  (:~
    From a string representing a tab-delimited row of data, get the 'cell' data at a 
    given column number. 
   :)
  declare function ctab:get-cell($row as xs:string, $column as xs:integer) as item()? {
    let $cells := tokenize($row, $ctab:tabChar)
    return $cells[$column]
  };
  
  (:~
    Retrieve a tab-delimited text file and return its rows of data, split along 
    newlines. 
   :)
  declare function ctab:get-report-by-rows($filepath as xs:string) as xs:string* {
    if ( unparsed-text-available($filepath) ) then
      for $line in unparsed-text-lines($filepath)
      return
        (: Only output lines that include a tab. :)
        if ( matches($line, '\t') ) then
          $line
        else ()
    else () (: error :)
  };
  
  (:~
    Return only the rows of data for which values appear in both fileset A and 
    fileset B. The counts are added up for each of these values.  
   :)
  declare function ctab:get-intersection-of-reports($filenames as xs:string+) as xs:string* {
    let $countReports := count($filenames)
    let $allRows :=
      for $filename in $filenames
      return ctab:get-report-by-rows($filename)
    let $allValues :=
      for $row in $allRows
      return ctab:get-cell($row, 2)
    let $distinctValues := distinct-values($allValues)
    let $intersectValues :=
      for $value in $distinctValues
      return
        (: We're only interested in the cell values which occur once per report. :)
        if ( count(index-of($allValues, $value)) eq $countReports ) then
          $value
        else ()
    let $regex := ctab:create-row-match-pattern($intersectValues)
    let $intersectRows := $allRows[matches(., $regex)]
    return ctab:get-union-of-rows($intersectRows)
  };
  
  (:~
    Return rows of data from fileset A only if their corresponding values don't 
    appear in fileset B. If more than one filename is provided for a set, the union of 
    the files in that set is applied first. 
   :)
  declare function ctab:get-set-difference-of-reports($filenames as xs:string+, 
     $filenames-for-excluded-data as xs:string+) as xs:string* {
    let $rows := 
      if ( count($filenames) gt 1 ) then
        ctab:get-union-of-reports($filenames)
      else ctab:get-report-by-rows($filenames)
    let $rowsExcluded :=
      if ( count($filenames-for-excluded-data) gt 1 ) then
        ctab:get-union-of-reports($filenames-for-excluded-data)
      else ctab:get-report-by-rows($filenames-for-excluded-data)
    return
      ctab:get-set-difference-of-rows($rows, $rowsExcluded)
  };
  
  (:~
    Given two sequences of tab-delimited strings, return rows from sequence A only 
    if their corresponding values don't appear in sequence B. The union of rows is 
    applied first, for each sequence. 
   :)
  declare function ctab:get-set-difference-of-rows($tabbed-rows as xs:string+, 
     $rows-with-excluded-data as xs:string+) as xs:string* {
    let $rowsWithTabs := ctab:get-union-of-rows($tabbed-rows)
    let $valuesExcluded :=
      let $rowsExcluded := ctab:get-union-of-rows($rows-with-excluded-data)
      return
        for $row in $rowsExcluded
        return ctab:get-cell($row, 2)
    let $regex := ctab:create-row-match-pattern($valuesExcluded)
    return
      $rowsWithTabs[not(matches(.,$regex))]
  };
  
  (:~
    Given a string, create a version for alphabetical sorting. Spaces are 
    normalized, characters are lower-cased, and non-sorting articles from 
    $ctab:nonsortRegex are removed. 
   :)
  declare function ctab:get-sortable-string($str as xs:string) {
    replace(lower-case(normalize-space($str)), $ctab:nonsortRegex, '')
  };
  
  (:~
    Combine the counts for all values in N tab-delimited reports. 
   :)
  declare function ctab:get-union-of-reports($filenames as xs:string*) as xs:string* {
    let $dataRows :=
      for $filename in $filenames
      return ctab:get-report-by-rows($filename)
    return ctab:get-union-of-rows($dataRows)
  };
  
  (:~
    Given a sequence of tab-delimited strings, combine the counts for all values. Rows 
    must contain an integer in column 1 and a distinct string in column 2.
    
    If there are more than two columns, this function will obtain the remainder from the 
    first row which matches the distinct value in question.
   :)
  declare function ctab:get-union-of-rows($tabbed-rows as xs:string*) as xs:string* {
    let $rowsWithTabs := $tabbed-rows[matches(., '\t')]
    let $allValues := 
      for $row in $rowsWithTabs
      return ctab:get-cell($row, 2)
    let $allDistinct := distinct-values($allValues)
    return
      for $value in $allDistinct
      let $regex := concat($ctab:tabChar,ctab:escape-for-matching($value),'(\t.*)?$')
      let $matches := $rowsWithTabs[matches(., $regex)]
      let $counts := 
        for $match in $matches
        let $count := ctab:get-cell($match, 1)
        return 
          if ( $count castable as xs:integer ) then 
            xs:integer( $count )
          else () (: error :)
      let $sum := if ( count( $counts ) ge 2 ) then 
                    sum( $counts )
                  else $counts
      order by $sum descending, $value
      return concat($sum, $ctab:tabChar, substring-after($matches[1], $ctab:tabChar))
  };
  
  (:~
    Turn a sequence of strings into a single string by inserting newlines. 
   :)
  declare function ctab:join-rows($rows as xs:string*) as xs:string {
    if ( count($rows) gt 0 ) then
      string-join($rows, $ctab:newlineChar)
    else ''
  };
  
  (:~
    Convert a counting robot report into a map data structure.
   :)
  declare function ctab:report-to-map($report as xs:string) as map(xs:string, xs:integer) {
    let $counts :=
      for $line in tokenize($report, $ctab:newlineChar)
      let $count := ctab:get-cell($line, 1) cast as xs:integer
      return map:entry(ctab:get-cell($line, 2), $count)
    return map:merge($counts)
  };
