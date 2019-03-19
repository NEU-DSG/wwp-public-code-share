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
 : @author Ashley M. Clark, Northeastern University Women Writers Project
 : @see https://github.com/NEU-DSG/wwp-public-code-share/tree/master/fulltext
 : @version 2.2
 :
 :  2019-03-19: v.2.2. In order to remove the dependency on Saxon EE, I removed the 
 :              dynamic function call. Instead, an explicit call to 
 :              wft:anchor-notes() has been commented out. To use the feature
 :              $move-notes-to-anchors, follow the instructions for 
 :              local:anchor-notes() below.
 :  2019-02-14: v.2.1. Merged in sane XPaths from a divergent git branch (see 
 :              2019-01-31 for details). Changed variable $text to $teiDoc.
 :  2019-02-01: v.2.0. Updated to XQuery version 3.1, which allows modules
 :              (libraries) to be dynamically loaded. Added the external variable 
 :              $move-notes-to-anchors, which moves <wwp:note>s from the <hyperDiv> 
 :              to their anchor in the text itself. For backwards compatibility with 
 :              older versions of this script, this new option is off by default. 
 :              The process requires XQuery Update to be enabled by the XQuery 
 :              processor. To make use of the new option, use Saxon EE with XQuery 
 :              Update and "Linked Tree" model turned on. Modified the indentation
 :              of the script for readability.
 :  2019-01-31: Use an easier XPath to select <text> elements (since
 :              all those that are not a child of <group> is the same
 :              set as all those that are a child of <TEI>).
 :  2018-12-20: v.1.4. Added link to GitHub.
 :  2018-11-29: Examine all <text> elements except those that are a
 :              child of <group>. Add change-log comments. --Syd
 :  2018-10-08: Allow a root element of <teiCorpus> as well as <TEI>.
 :              Note that nested corpora are not searched through.
 :              (I.e., we're looking at teiCorpus/TEI/text, not
 :              teiCorpus//text which might be better.) --Syd
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
 :              from output. Used the full path for `/TEI/text` to solve doubling 
 :              when the file has a <group> of <text>s.
 :  2017-08-01: Removed duplicate results when morphadorned XML includes split 
 :              tokens. Only unbroken tokens and the first split tokens are 
 :              processed  (`//w[not(@part) or @part[data(.) = ('N', 'I')]`).
 :  2017-07-12: v1.1. Added Morphadorner control, this header, and this changelog.
 :  2017-06-09: Fixed XPaths used to derive documents' publication date and author.
 :              Thanks to Thanasis for finding these bugs!
 :  2017-04-28: v1.0. Created from fulltext2table.xq.
 :)

(:  IMPORTS  :)
  import module namespace wft="http://www.wwp.northeastern.edu/ns/fulltext" 
    at "fulltext-library.xql";
(:  NAMESPACES  :)
  declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare namespace werr="http://www.wwp.northeastern.edu/ns/err";
(:  OPTIONS  :)
  declare option output:method "text";

  declare context item external;

(:  VARIABLES  :)
  (: Set $return-only-words to 'true()' to remove the header row and file metadata 
    entirely. Only that file's words are returned. :)
  declare variable $return-only-words as xs:boolean external := false();
  (: The "preserve-space" parameter determines whether whitespace is introduced 
    around elements that normally imply whitespace, such as <lb>. The default is to 
    preserve whitespace as it appears in the input XML. :)
  declare variable $preserve-space as xs:boolean external := true();
  (: Set $move-notes-to-anchors to 'true()' in order to move <wwp:note>s close to 
    their anchors, making sure not to break up a word in doing so.
    IMPORTANT: In order to use this feature in oXygen, you will need to follow the 
    instructions for the function local:anchor-notes() below. :)
  declare variable $move-notes-to-anchors as xs:boolean external := false();
  
  (: Morphadorner-specific control :)
  declare variable $is-morphadorned as xs:boolean external := false();
  declare variable $morphadorner-text-type as xs:string external := 'reg';
  declare variable $valid-morphadorner-types := ('lem', 'pos', 'reg', 'spe', 'text');


(:  FUNCTIONS  :)
  
  (: Wrapper function to call wft:anchor-notes(). In order to use the feature 
    $move-notes-to-anchors, you will need to do the following set-up once (but only 
    once):
      (1) make sure you have downloaded the XQuery file at
        https://raw.githubusercontent.com/NEU-DSG/wwp-public-code-share/master/fulltext/fulltext-library.xql ;
      (2) make sure the downloaded file is stored in the same location as this 
        script, and that it is named "fulltext-library.xql";
      (3) uncomment the line below that reads `wft:anchor-notes($xml)`, then comment 
        out or delete the line that reads `$xml`; and
      (4) use an XQuery processor that recognizes XQuery Update.
    To accomplish #2 in oXygen, use Saxon EE as your "transformer". Click on the 
    symbol next to "Saxon EE" to open the processor settings. Turn on the "linked 
    tree" model and XQuery Update. Turn off XQuery Update backups. :)
  declare function local:anchor-notes($xml as node()) {
    (:wft:anchor-notes($xml):)
    $xml
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

let $file := tokenize(/base-uri(),'/')[last()]
let $headerRow := ('filename', 'tr #', 'author pid', 'pub date', 'full text')
let $allRows := 
  (
    if ( $return-only-words ) then ()
    else local:make-cells-in-row($headerRow)
    ,
    let $teiDoc := /(TEI | teiCorpus)
    let $optionalMetadata :=
      if ( $return-only-words ) then ()
      else
        let $header := $teiDoc/teiHeader
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
    (: Refine $teiDoc. :)
    let $teiDoc :=
      if ( $move-notes-to-anchors ) then
        local:anchor-notes($teiDoc)
      else $teiDoc
    let $teiDoc := $teiDoc/descendant-or-self::TEI
  (: Change $ELEMENTS to reflect the elements for which you want full-text 
      representations. :)
    let $ELEMENTS := $teiDoc/text
  (: Below, add the names of elements that you wish to remove from within $ELEMENTS.
      For example, 
        ('castList', 'elision', 'figDesc', 'label', 'speaker')
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
