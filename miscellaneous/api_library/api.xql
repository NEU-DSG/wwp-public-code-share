xquery version "3.1";

module namespace wpi="http://www.wwp.northeastern.edu/ns/api/functions";
(:  NAMESPACES  :)
  declare namespace http="http://expath.org/ns/http-client";
  declare namespace map="http://www.w3.org/2005/xpath-functions/map";
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare namespace rest="http://exquery.org/ns/restxq";

(:~
  A library of functions to simplify the development of an XQuery API.
  
  @author Ashley M. Clark, Northeastern University Women Writers Project
  @version 1.5.1
  @see https://github.com/NEU-DSG/wwp-public-code-share/tree/main/miscellaneous/api_library
  
  Changelog:
    2020-10-02, v1.5.1: Updated GitHub link to use the new default branch "main".
      Uncommented namespace declaration; this library now won't work in eXist v2.2.
    2020-09-29, v1.5.0: Added $wpi:sortRegexCharacterRemoval, 
      $wpi:sortRegexWhitespaceReplacement, wpi:not-ignorable-string(), and
      wpi:regularize-nonsortable-characters(). Renamed $wpi:nonsortingRegex to 
      $wpi:sortRegexNonsortingArticleRemoval. Changed wpi:get-sortable-string() to 
      accept zero or one string.
    2020-03-25, v1.4.1: Moved this XQuery from Subversion to the WWP Public Code 
      Share, and changed the link above accordingly. Added MIT license and 
      wpi:get-sortable-string#2.
    2019-12-17, v1.4: Added wpi:filter-set().
    2019-10-04, v1.3: Added a few non-sorting articles to wpi:get-sortable-string().
      Added xqDoc descriptions of functions.
    2018-12-03, v1.2: Declared previously-undeclared namespaces (e.g. "http"). The 
      declaration for "map" is commented out, since eXist has the prefix bound to a 
      different namespace. Changed the eXist-specific map:new() to XQuery 3.1's 
      map:merge().
    2018-05-29: Added the access control header as a global variable. Restricted
      types on function parameters. Updated wpi:get-sortable-string() with 
      additional words not to sort on.
    2016-08-16: Created this file using functions and logic from the Cultures of 
      Reception XQuery library.
  
  MIT License
  
  Copyright (c) 2020 Northeastern University Women Writers Project
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions
 
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

(:
  VARIABLES
 :)
  
  declare variable $wpi:accessHeader :=
    <http:header name="Access-Control-Allow-Origin" value="*"/>;
  declare variable $wpi:sortRegexCharacterRemoval :=
    concat("(['",'"',"“”?!*\[\]()☞☜¶†‡£☾⊙☉§{}¦_\\]|&amp;(c\.?)?)");
  declare variable $wpi:sortRegexNonsortingArticleRemoval :=
    "^((the|an|a|la|le|el|lo|las|les|los|de|del|de la) |l')";
  declare variable $wpi:sortRegexWhitespaceReplacement :=
    "([\s;:\.,␣/…–—―·•]|-{2,})+";


(:
  FUNCTIONS
 :)
  
  (:~
    Using the EXPath HTTP Client, construct a response to an HTTP request.
    
    @param statusCode a string representing a three-digit HTTP status code
    @return an XML description of the HTTP response
   :)
  declare function wpi:build-response($statusCode as xs:string) as item() {
    wpi:build-response($statusCode, (), ())
  };
  
  (:~
    Using the EXPath HTTP Client, construct a response to an HTTP request.
    
    @param statusCode a string representing a three-digit HTTP status code
    @param headerParts zero or more HTTP headers, in the EXPath HTTP XML format
    @return an XML description of the HTTP response
   :)
  declare function wpi:build-response($statusCode as xs:string, 
     $headerParts as node()*) as item() {
    wpi:build-response($statusCode, $headerParts, ())
  };
  
  (:~
    Using the EXPath HTTP Client, construct a response to an HTTP request.
    
    @param statusCode a string representing a three-digit HTTP status code
    @param headerParts zero or more HTTP headers, in the EXPath HTTP XML format
    @param output any outputs to be returned in the response
    @return a sequence of items for the HTTP response
   :)
  declare function wpi:build-response($statusCode as xs:string, $headerParts as node()*, 
     $output as item()*) as item()* {
    let $header :=
      <rest:response>
        <http:response status="{$statusCode}">
          { $headerParts }
        </http:response>
      </rest:response>
    return ( $header, $output )
  };
  
  (:~
    Construct a URL using a base URI and any given query parameters.
    
    @param linkBase a string representing the URI to be used before any additional 
      query parameters.
    @param queryParams key-value pairs to use when constructing the URL
    @return a URL in string form
   :)
  declare function wpi:get-query-url($linkBase as xs:string, $queryParams as 
     map(xs:string, item()*)) as xs:string {
    let $paramBits :=
      for $key in map:keys($queryParams)
      let $seq := map:get($queryParams,$key)
      return 
        for $value in $seq
        return concat($key,'=',$value)
    let $queryStr :=  if ( count($paramBits) ge 1 ) then 
                        concat('?',string-join($paramBits,'&amp;'))
                      else ''
    return concat($linkBase, $queryStr)
  };
  
  (:~
    Given a string, create a version for alphabetical sorting by lower-casing the 
    characters and removing articles at the beginning of the string. This version
    uses $wpi:sortRegexNonsortingArticleRemoval to identify parts of the string which should be 
    removed.
    
    @param str the string
    @return a version of the string suitable for alphabetical sorting
   :)
  declare function wpi:get-sortable-string($str as xs:string?) as xs:string? {
    wpi:get-sortable-string($str, $wpi:sortRegexNonsortingArticleRemoval)
  };
  
  (:~
    Given a string, create a version for alphabetical sorting by lower-casing the 
    characters and removing parts of the string that match the non-sorting regular
    expression.
    
    @param str the string
    @param nonsorting-regex an optional, case-insensitive regular expression. Any 
      matches within $str will be removed.
    @return a version of the string suitable for alphabetical sorting
   :)
  declare function wpi:get-sortable-string($str as xs:string?, $nonsorting-regex as 
     xs:string?) as xs:string? {
    let $lowercased := lower-case($str)
    return
      if ( exists($nonsorting-regex) and normalize-space($nonsorting-regex) ne '' ) then
        replace($lowercased, $nonsorting-regex, '')
      else $lowercased
  };
  
  (:~
    Filter a sequence of items according to requested parameter values. This 
    function uses an application-specific map to determine which request parameter 
    types are filterable, and how to filter the sequence for all requested values 
    for that type.
    
    @param superset a sequence of zero or more results
    @param parameter-map a map containing request parameter keys and values (ideally, 
      the application should have already cleaned and vetted the request values)
    @param filtering-configuration a map where the key is a valid parameter name, 
      and the value is a function which takes a single item and a sequence of 
      parameter values. The function should return a boolean value: true if the item 
      matches the parameter value; and false if the item should be filtered out of 
      $superset. For example:
      `map { "author": function($string, $name) { contains($string, $name) } }`
    @return the requested subset of the items in $superset
   :)
  declare function wpi:filter-set($superset as item()*, $parameter-map as 
     map(xs:string,item()*), $filtering-configuration as map(xs:string, 
     function(item(), xs:string) as xs:boolean)) as item()* {
    (: Get the valid filter types from $filtering-configuration. :)
    let $filters := 
      map:keys($filtering-configuration)[not(empty($parameter-map?(.)))]
    return
      (: End processing if there are no filters or no items in $superset. :)
      if ( count($filters) eq 0 ) then $superset
      else if ( count($superset) eq 0 ) then ()
      (: Process the first valid filter type. :)
      else
        let $currentKey := $filters[1]
        let $paramValues := $parameter-map?($currentKey)
        (: Treat this filter's values as a sequence. :)
        let $valueSeq :=
          typeswitch ($paramValues)
            case array(item()*) return $paramValues?*
            default return $paramValues
        (: Identify members of $superset which match all values for this filter. :)
        let $subset :=
          $superset
          [ every $value in $valueSeq
            satisfies $filtering-configuration?($currentKey)(., $value) ]
        (: Replace the values for this filter with an empty sequence. :)
        let $newParams := map:put($parameter-map, $currentKey, ())
        return
          (: Call this function again with the modified parameter map. :)
          wpi:filter-set($subset, $newParams, $filtering-configuration)
  };
  
  (:~
    Create an HTTP 'Link' header, formatted according to RFC 5988. For use with the 
    EXPath HTTP client.
    
    @param limit the maximum number of results per page
    @param currentPage a number representing the requested "page" of results
    @param totalPages how many pages there are for this query in total, using $limit
    @param linkBase a string representing the URI to be used before any additional 
      query parameters.
    @param queryParams key-value pairs to use when constructing the URL
    @return an XML serialization of an HTTP Link header
   :)
  declare function wpi:make-link-header($limit as xs:integer, $currentPage as xs:integer, 
     $totalPages as xs:integer, $linkBase as xs:string, 
     $queryParams as map(xs:string, item()*)) as node()? {
    let $limitParam := map:entry('limit', $limit)
    let $paramSeq := if ( empty($queryParams) ) then ($limitParam)
                     else ($queryParams, $limitParam)
    let $first := if ( $currentPage gt 1 ) then
                   let $page := map:entry('page', '1')
                   let $paramSeqPlusPage := ($paramSeq, $page)
                   let $url := wpi:get-query-url($linkBase, map:merge($paramSeqPlusPage))
                   return concat('<',$url,'>; rel="first"')
                 else ()
    let $next := if ( $currentPage lt $totalPages ) then
                   let $page := map:entry('page', $currentPage + 1)
                   let $paramSeqPlusPage := ($paramSeq, $page)
                   let $url := wpi:get-query-url($linkBase, map:merge($paramSeqPlusPage))
                   return concat('<',$url,'>; rel="next"')
                 else ()
    let $last := if ( $currentPage ne $totalPages ) then
                   let $page := map:entry('page', $totalPages)
                   let $paramSeqPlusPage := ($paramSeq, $page)
                   let $url := wpi:get-query-url($linkBase, map:merge($paramSeqPlusPage))
                   return concat('<',$url,'>; rel="last"')
                 else ()
    let $linksVal := ( $first, $next, $last )
    return 
      if ( not(empty($linksVal)) ) then 
        <http:header name="Link" value="{string-join($linksVal,', ')}"/>
      else ()
  };
  
  (:~
    Test some input to make sure that it is a string, and that it contains 
    characters that aren't spaces. This is useful for avoiding unnecessary 
    processing when parameters are allowed to be empty.
    
    @param str  zero or one string for testing
    @return false if the input *is* an empty sequence or an ignorable string 
   :)
  declare function wpi:not-ignorable-string($str as xs:string?) as xs:boolean {
    exists($str) and normalize-space($str) ne ''
  };
  
  (:~
    Given a sequence, return a subset determined by the number of results and the 
    page requested.
    
    @param set a sequence of zero or more results
    @param page a number representing the requested "page" of results
    @param limit the maximum number of results per page
    @return a subset of $set
   :)
  declare function wpi:reduce-to-subset($set as item()*, $page as xs:integer, $limit as 
     xs:integer) as item()* {
    let $intPage := if ( $limit eq 0 ) then 0 else $page
    let $totalRecords := count($set)
    let $subSet := 
      if ( $limit eq 0 ) then ()
      else if ( $limit gt 0 ) then
        let $range := if ( $intPage gt 0 ) then 
                        (($intPage - 1) * $limit) + 1
                      else 1
        return subsequence($set,$range,$limit)
      else $set
    return $subSet
  };
  
  (:~
    Given a string, perform some regularization tasks toward creating a sortable 
    string. First, a regular expression is used to replace unwanted characters or 
    patterns with nothing. Then, another regular expression is used to replace other 
    patterns with whitespace. Whitespace is normalized, and finally, instances of 
    the string " & " are replaced with " and ". This function is useful to apply 
    before wpi:get-sortable-string(), which lowercases all letters and removes 
    leading articles.
    
    This version of the function is a convenience function for the three-argument 
    version:
      `wpi:regularize-nonsortable-characters($str, $wpi:sortRegexCharacterRemoval, 
                                             $wpi:sortRegexWhitespaceReplacement)`
    
    @param str a string to be regularized
    @return a regularized string
   :)
  declare function wpi:regularize-nonsortable-characters($str as xs:string?) 
     as xs:string? {
    wpi:regularize-nonsortable-characters($str, $wpi:sortRegexCharacterRemoval)
  };
  
  (:~
    Given a string, perform some regularization tasks toward creating a sortable 
    string. First, a regular expression is used to replace unwanted characters or 
    patterns with nothing. Then, another regular expression is used to replace other 
    patterns with whitespace. Whitespace is normalized, and finally, instances of 
    the string " & " are replaced with " and ". This function is useful to apply 
    before wpi:get-sortable-string(), which lowercases all letters and removes 
    leading articles.
    
    This version of the function is a convenience function for the three-argument 
    version:
      `wpi:regularize-nonsortable-characters($str, $removable-character-regex, 
                                             $wpi:sortRegexWhitespaceReplacement)`
    The parameter $removable-character-regex is optional. If an empty sequence or a 
    zero-length string is provided, no replacement will take place.
    
    @param str a string to be regularized
    @param removable-character-regex an optional regular expression to match 
      patterns which should be removed from the string
    @return a regularized string
   :)
  declare function wpi:regularize-nonsortable-characters($str as xs:string?, 
     $removable-character-regex as xs:string?) as xs:string? {
    wpi:regularize-nonsortable-characters($str, $removable-character-regex, 
      $wpi:sortRegexWhitespaceReplacement)
  };
  
  (:~
    Given a string, perform some regularization tasks toward creating a sortable 
    string. First, a regular expression is used to replace unwanted characters or 
    patterns with nothing. Then, another regular expression is used to replace other 
    patterns with whitespace. Whitespace is normalized, and finally, instances of 
    the string " & " are replaced with " and ". This function is useful to apply 
    before wpi:get-sortable-string(), which lowercases all letters and removes 
    leading articles.
    
    In this version of the function, all regular expressions are optional. If an 
    empty sequence or a zero-length string is provided, no replacement will take 
    place.
    
    @param str a string to be regularized
    @param removable-character-regex an optional regular expression to match 
      patterns which should be removed from the string
    @param characters-to-replace-with-space-regex an optional regular expression to 
      match patterns that should be replaced with a single space
    @return a regularized string
   :)
  declare function wpi:regularize-nonsortable-characters($str as xs:string?, 
     $removable-character-regex as xs:string?, 
     $characters-to-replace-with-space-regex as xs:string?) as xs:string? {
    let $charCleaned :=
      if ( wpi:not-ignorable-string($removable-character-regex) ) then
        replace($str, $removable-character-regex, '')
      else $str
    let $wordSplit :=
      if ( wpi:not-ignorable-string($characters-to-replace-with-space-regex) ) then
        replace($charCleaned, $characters-to-replace-with-space-regex, ' ')
      else $charCleaned
    return
      replace(normalize-space($wordSplit), ' &amp; ', ' and ')
  };

