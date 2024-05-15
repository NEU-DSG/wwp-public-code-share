xquery version "3.1";

(:~
  A starter script for creating a tab-separated value (TSV) table using XPath and 
  XQuery.
  
  @return tab-delimited text
  
  @author Ash Clark, Northeastern University Women Writers Project
  @see https://github.com/NEU-DSG/wwp-public-code-share/tree/main/counting_robot
  @version 0.1
   
   2016-01-13: Created this XQuery by modifying counting-robot.xq .
  
  MIT License
  
  Copyright (c) 2024 Northeastern University Women Writers Project
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
 :)

(:  NAMESPACES  :)
  declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  
(:  OPTIONS  :)
  declare option output:item-separator "";
  declare option output:method "text";


(:  VARIABLES - QUERYING  :)
  (: Create variables referencing the files or folders you wish to query. :)
    (:  To get one file:       doc('FILEPATH/FILENAME')                   :)
    (:  To get one directory:  collection('FILEPATH/?select=*.xml')       :)
    (:  To get more than one:  ( DOC | DOC | DIR )                        :)
  declare variable $DESCRIPTIVE_NAME := 
    collection('file:///Users/aclark/Documents/WWP/textbase/distribution/?select=*.xml');
  
  (:
    Using the variable(s) above, you can change $get-rows to filter your XML down to 
    whatever you want to produce a table about.
    
    For example, this:
      $myFolder/*
    would produce one row for every file in $myFolder.
    
    As another example,
      $myFolder//persName[@ref]
    would produce one row for every <persName> which has a "ref" attribute on it.
   :)
  declare variable $get-rows := $DESCRIPTIVE_NAME/*;
  
  (:
    The $row-constructor is a mapping of column headings (e.g. "Cell 1") to the 
    XPath or XQuery that will let you fill in a cell for a given row.
    
    Here is a template cell entry:
      "HEADING LABEL": function ($row) {
          $row/XPATH
        }
    
    Make sure to separate each entry with a comma!
   :)
  declare variable $row-constructor := map {
      "Filename": function ($row) {
          tokenize($row/base-uri(), '/')[last()]
        }
      ,
      "Document title": function ($row) {
          $row//titleStmt/title/normalize-space()
        }
    };
  
  (:
    Copy each column heading here, in the order you want for your table.
   :)
  declare variable $column-labels-in-order := 
    ( "Filename", "Document title" );


(:
    FUNCTIONS
    
    If you have XPaths that you're copy-pasting over and over again, consider making 
    them into functions and pasting them below!
    
    For example:
       declare function local:say-hello($name) {
         concat("Hello, ",$name,"!")
       };
 :)
  
  
(:
  HEY! LISTEN:  The code below powers your report-making robot. For most queries,
                you won't need to change anything after this point.
 :)
  
  (: This function strips out leading articles from a string value for sorting. 
    It also lower-cases the string, since capital letters will have an effect on 
    sort order. :)
  declare function local:get-sortable-string($str as xs:string) {
    let $normalizedStr := lower-case(normalize-space($str))
    return replace($normalizedStr, '^(the|an|a|la|le|de|del|el|lo|las|los) ','')
  };


(:
    THE TABULATING ROBOT
 :)

let $headerRow := string-join($column-labels-in-order, '&#9;')
let $dataRows :=
  (: For each item in $get-rows, construct a table row. :)
  for $row in $get-rows
  let $cells :=
    let $notFoundError := "Could not find entry in $row-constructor"
    for $column in $column-labels-in-order
    let $value :=
      (: Make sure that this column has an entry in $row-constructor. :)
      if ( not(map:contains($row-constructor, $column)) ) then
        $notFoundError
      else $row-constructor?($column)($row)
    return
      (: If $value didn't return a value, use an empty string to create an empty 
        cell. :)
      if ( empty($value) ) then ''
      (: If $value contains newlines or tab characters, replace each one with a 
        space character. :)
      else if ( matches($value, '[\n\t]') ) then
        replace($value, '[\n\t]', " ")
      (: Otherwise, simply return $value as the contents of the cell. :)
      else $value
  return
    (: Separate cells with a tab character. :)
    string-join($cells, '&#9;')
(: Gather the heading row in with the data rows. :)
let $allRows := 
  ( $headerRow,
    $dataRows )
return
  (: Separate each row with a newline. :)
  string-join($allRows, '&#13;')
