xquery version "3.1";

(:~
 : A script to strip out the text from a TEI document, while retaining some metadata 
 : from the header. While intended for use with TEI created by the Women Writers 
 : Project, it can be used on other documents with a little tweaking.
 :
 : The $ELEMENTS variable gives control over which TEI elements should be output via 
 : XPath. To use morphadorned XML, change $is-morphadorned to true().
 :
 : @return tab-delimited text
 :
 : @author Ashley M. Clark, Northeastern University Women Writers Project
 : @see https://github.com/NEU-DSG/wwp-public-code-share/tree/master/fulltext
 : @version 2.0
 :
 :  2019-02-01: v.2.0. Updated to XQuery version 3.1, which allows modules
 :              (libraries) to be dynamically loaded. Added the external variable 
 :              $move-notes-to-anchors, which moves <wwp:note>s from the <hyperDiv> 
 :              to their anchor in the text itself. For backwards compatibility with 
 :              older versions of this script, this new option is off by default. 
 :              The process requires XQuery Update to be enabled by the XQuery 
 :              processor. To make use of the new option, use Saxon EE with XQuery 
 :              Update and "Linked Tree" model turned on. Modified the indentation
 :              of the script for readability.
 :  2018-12-20: v.1.4. Added link to GitHub.
 :  2018-12-01: Allow for outermost element of input document to be
 :              <teiCorpus> in addition to <TEI>. Thus the sequence of
 :              elements in $text may contain both <TEI> and
 :              <teiCorpus>, and to look for the non-metadata bits
 :              themselves we want to look for all <text> desendants,
 :              not just child of outermost element. However, we don't
 :              want to count a <text> more than once, so avoid nested
 :              <text> elements by ignoring those that are within a
 :              <group>. (Since <group> is definitionally a descendant
 :              of <text>, all those will aready be collected by
 :              catching the <text> that is the ancestor of the
 :              <group>.)
 :  2018-11-29: Bug fix (by SB on phone w/ AC): fix assignment of
 :              $header (to the <teiHeader> child of the outermost
 :              element, recorded in $text, rather than to the
 :              non-existant <teiHeader> child of the <TEI> child of
 :              the element recorded in $text).
 :  2018-06-21: v.1.3. Added the external variable $preserve-space, which determines 
 :              whether whitespace is respected in the input XML document (the 
 :              default), or if steps are taken to normalize whitespace and add 
 :              whitespace where it is implied (e.g. <lb>).
 :  2018-05-04: v.1.2. With Sarah Connell, added the external variable 
 :              $return-only-words for use when the header row and file metadata are 
 :              unnecessary. Added a default namespace and deleted "wwp:" prefixed 
 :              XPaths. Switched the Morphadorner variables from camel-cased words 
 :              to hyphen-separated. Fixed bug which eats text nodes that are all 
 :              whitespace. The bug occurs when $ELEMENTS2OMIT is used with Saxon 
 :              9.7+ (Oxygen XML Editor 19.0+).
 :  2017-08-03: Added function omit-descendants() to remove given named elements 
 :              from output.
 :  2017-08-01: Removed duplicate results when morphadorned XML includes split 
 :              tokens. Only unbroken tokens and the first split tokens are 
 :              processed  (`//w[not(@part) or @part[data(.) = ('N', 'I')]`).
 :  2017-07-12: v1.1. Added Morphadorner control, this header, and this changelog.
 :  2017-06-09: Fixed XPaths used to derive documents' publication date and author.
 :              Thanks to Thanasis for finding these bugs!
 :  2017-04-28: Moved script from amclark42/xdb-app-central to the
 :              NEU-DSG/wwp-public-code-share GitHub repository.
 :  2016-12-13: v1.0. Created.
 :)

(:  NAMESPACES  :)
  declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare namespace werr="http://www.wwp.northeastern.edu/ns/err";
  declare namespace wft="http://www.wwp.northeastern.edu/ns/fulltext";
(:  OPTIONS  :)
  declare option output:method "text";


(:  VARIABLES  :)
  declare variable $ft-wwo := collection('../../fulltext-wwo?select=*.xml');
  declare variable $use-docs external := $ft-wwo;
  (: Set $return-only-words to 'true()' to remove the header row and file metadata 
    entirely. Only that file's words are returned. :)
  declare variable $return-only-words as xs:boolean external := false();
  (: The "preserve-space" parameter determines whether whitespace is introduced 
    around elements that normally imply whitespace, such as <lb>. The default is to 
    preserve whitespace as it appears in the input XML. :)
  declare variable $preserve-space as xs:boolean external := true();
  (:  :)
  declare variable $move-notes-to-anchors as xs:boolean external := false();
  (:  :)
  declare variable $fulltext-library-filepath as xs:string external := 'fulltext-library.xql';
  
  (: Morphadorner-specific control :)
  declare variable $is-morphadorned as xs:boolean external := false();
  declare variable $morphadorner-text-type as xs:string external := 'reg';
  declare variable $valid-morphadorner-types := ('lem', 'pos', 'reg', 'spe', 'text');


(:  FUNCTIONS  :)
  (: Wrapper function to call wfn:anchor-notes() dynamically. This will only occur 
    if $move-notes-to-anchors is toggled on. :)
  declare function local:anchor-notes($xml as node()) {
    let $libNs := 'http://www.wwp.northeastern.edu/ns/fulltext'
    let $notesFunction := 
      let $loadedFunctions :=
        load-xquery-module($libNs, map { 'location-hints': ($fulltext-library-filepath) })('functions')
      let $functionName := QName($libNs, 'anchor-notes')
      return $loadedFunctions($functionName)(1)
    return $notesFunction($xml)
  };
  
  (: Given a type of text output and an element, create a plain text version of the 
    morphadorned TEI. :)
  declare function local:get-morphadorned-text($element as node(), $type as xs:string) {
    let $useType := if ( $type = $valid-morphadorner-types ) then $type else 'text'
    return
      if ( $type eq 'text') then
        local:get-text($element)
      else 
        let $strings :=
          if ( $element[self::lb][not($preserve-space)] ) then
            ' '
          (: Since Morphadorner will place the same value on both parts of the same 
            word, we will only process the first split token, and unbroken tokens. :)
          else if ( $element[@part[data(.) = ('M', 'F')]] ) then
            ()
          else if ( $element[self::c] ) then
            $element/data(.)
          else if ( $element[@lem or @pos or @reg or @spe] ) then
            $element/@*[local-name(.) eq $type]/data(.)
          else
            for $child in $element/*
            return local:get-morphadorned-text($child, $type)
        return
          string-join($strings,' ')
  };
  
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


(:  MAIN QUERY  :)
let $headerRow := ('filename', 'tr #', 'author pid', 'pub date', 'full text')
let $allRows := 
  (
    if ( $return-only-words ) then ()
    else local:make-cells-in-row($headerRow),
    
    for $text in $use-docs/TEI | $use-docs/teiCorpus
    let $file := tokenize($text/base-uri(),'/')[last()]
    let $text :=
      if ( $move-notes-to-anchors ) then
        local:anchor-notes($text)
      else $text
    let $optionalMetadata :=
      if ( $return-only-words ) then ()
      else
        let $header := $text/teiHeader
        let $idno := $header/fileDesc/publicationStmt/idno[@type eq 'WWP']/data(.)
        let $author := $header/fileDesc/titleStmt/author[1]/persName[@ref][1]/@ref/substring-after(data(.),'p:')
        let $pubDate := 
          let $date := $header/fileDesc/sourceDesc[@n][1]//imprint[1]/date[1]
          return 
            if ( $date[@from][@to] ) then
              concat( $date/@from/data(.), '–', $date/@to/data(.) )
            else $date/@when/data(.)
        return 
          ( $file, $idno, $author, $pubDate )
    (: Change $ELEMENTS to reflect the elements for which you want full-text representations. :)
    let $ELEMENTS := $text//text[not(parent::group)]
    (: Below, add the names of elements that you wish to remove from within $ELEMENTS.
     : For example, 
     :    ('castList', 'elision', 'figDesc', 'label', 'speaker')
     :)
    let $ELEMENTS2OMIT := ()
    let $fulltext := 
      let $wordSeq := for $element in $ELEMENTS
                      let $abridged := local:omit-descendants($element, $ELEMENTS2OMIT)
                      return 
                        if ( $is-morphadorned ) then
                          local:get-morphadorned-text($abridged, $morphadorner-text-type)
                        else local:get-text($abridged)
      let $wordSeparator := ' '
      return normalize-space(string-join(($wordSeq), $wordSeparator))
    (: The variable $optionalMetadata will be empty if $return-only-words is 'true()'. :)
    let $dataSeq := ( $optionalMetadata, $fulltext )
    order by $file
    return 
      if ( $fulltext ne '' ) then 
        local:make-cells-in-row($dataSeq)
      else ()
  )
return local:make-rows-in-table($allRows)
