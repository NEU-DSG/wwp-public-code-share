<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:h="http://www.w3.org/1999/xhtml"
  xmlns:wf="http://www.wwp.northeastern.edu/ns/functions"
  exclude-result-prefixes="#all"
  version="3.0">

  <xsl:output method="xhtml" indent="yes"/>

  <!--
      $0
      🄯 2026 Syd Bauman and the Northeastern University Digital Scholarship Group

      Usage:

      The input document should be the output of `xmlstarlet list`
      that is in and of the directory of interest. In addition to that
      input document, all files matching the $dataSel parameter
      (“.xml” by default) in that directory of interest are read in,
      and it is for that set of files that various counts of syntactic
      structures are reported. In general you probably do not want the
      output of `xmlstarlet`, the input to this program, to be counted
      by this program; thus best to name it with an extension other
      than “.xml”. E.g.:
      $ xmlstarlet list > ./files.list
                        && saxon.bash /PATH/TO/table_of_complexity_counts.xslt ./files.list
                        > syntactic_complexity_of_this_dir.xhtml
      Although setting $dataSel may accomplish the same goal in many
      circumstances. E.g.:
      $ xmlstarlet list > ./fileslist.xml
                        && saxon -xsl:/PATH/TO/table_of_complexity_counts.xslt
                        -s:./fileslist.xml
                        -o:./syntactic_complexity_of_this_dir.xhtml
                        dataSel='select=tei_*.xml;'
      Furthermore, we do not really need to test for validity, so
      &#x2D;&#x2D;parserFeature?uri=http%3A//apache.org/xml/features/nonvalidating/load-external-dtd:false
      is useful if the DTD is not where the DOCTYPE declaration says
      it is.

      NOTE: It should be quite easy to change this program so that it
      expects as input the output of `tree -N -X -s` instead, which
      would allow it to also use recurse=yes on the
      collection(). (Note that if you are using `tree -X` for fun
      rather than as input here, you might want &#x2D;&#x2D;si instead
      of -s, and probably want &#x2D;&#x2D;du in addition.)
  -->

  <!-- Remember the specified input for later use -->
  <xsl:variable name="input" select="/" as="document-node()"/>
  
  <!--
      parameters for determining set of “secondary” input documents,
      the ones for which we should calculate statistics
  -->
  <!-- dataDir = the input directory is the directory of the specified input file -->
  <xsl:param name="dataDir" select="base-uri(/) => replace('/[^/]+$','')" as="xs:string"/>
  <!-- dataSel = from within that directory select these files -->
  <xsl:param name="dataSel" select="'select=*.xml;'" as="xs:string"/>
  <!-- dataParams = parameters for Saxon collection function: non-recursive & ignore errors -->
  <xsl:param name="dataParams" select="'recurse=no;on-error=warning'" as="xs:string"/>
  <xsl:param name="collect_us" select="$dataDir||'?'||$dataSel||$dataParams => escape-html-uri()" as="xs:string"/>
  <xsl:variable name="input_files" select="collection( $collect_us )"/>
  
  <!-- path to table sorting routine -->
  <xsl:param name="sorttable" select="'/utils/bin/javascript/sorttable.js'" as="xs:string"/>
  
  <!-- “picture”s for use in calls to format-number() -->
  <xsl:param name="intNpic"  select="'#,###,###,##0&#xA0;&#xA0;&#xA0;'" as="xs:string"/>
  <xsl:param name="fracNpic" select="    '#,###,##0.00'"                as="xs:string"/>
  <!-- The non-digit characters we need to remove from numbers formatted with the pictures,
       above, to be able to cast them back them back into numbers for calculation. -->
  <xsl:param name="nonDigs" select="',&#xA0;'" as="xs:string"/>
  
  <!--
    Initial template: input is ignored, and an XHTML document is
    generated as output.
  -->
  <xsl:template match="/" name="xsl:initial-template" as="item()+">
    <xsl:text>&#x0A;</xsl:text>
    <html xml:lang="en" lang="en">
      <xsl:call-template name="html_head"/>
      <body>
        <xsl:call-template name="pre_table"/>
        <table class="sortable" border="1">
          <caption>counts for determining syntactic complexity</caption>
          <xsl:call-template name="table_head"/>
          <xsl:call-template name="table_body"/>
        </table>
        <xsl:call-template name="post_table"/>
      </body>
    </html>
  </xsl:template>
  
  <!-- ************************** -->
  <!-- Main 1st-level subroutines -->
  <!-- ************************** -->
  
  <xsl:template name="html_head" as="element(h:head)">
    <head>
      <title>Syntactic Complexity</title>
      <meta name="generated-by" content="{static-base-uri()}"/>
      <meta name="canonical-is" content="!!! put GitHub public codeshare URI here !!!"/>
      <meta name="generated-at" content="{current-dateTime()}"/>
      <xsl:variable name="sortTableJS" as="xs:string"
                    select="if ( unparsed-text-available( $sorttable ) )
                            then $sorttable
                            else 'https://www.wwp.neu.edu/utils/bin/javascript/sorttable.js'"/>
      <xsl:text>&#x0A;</xsl:text>
      <script type="application/javascript" src="{$sortTableJS}"/>
      <meta name="prettifier" content="just to get output to line up properly"/>
      <style type="text/css">
        body { background-color: #FAFCFE; padding: 1em; }
        aside.info { margin: 0 1em 2em 1em; padding: 0 1em; border: thin solid blue; }
        caption { padding: 1em; font-weight: bold; }
        table {
           background-color: #F0F0F8;
           padding: 1ex 1em 1ex 1ex;
           width: 100%; /* Takes full width of container */
           min-width: 200ch; /* forces horizontal scroll (adjust based on columns) */
           border-collapse: collapse; /* Removes spacing between cells */
           border: 1px solid #e0e0e0;
           }
        .table-container {
           overflow-x: auto; /* critical for sticky positioning */
           max-width: 100%;
           }
        th { padding: 0.75ex; vertical-align: text-top; }
        tbody { background-color: #FFFEFD; }
        tbody tr td { text-align: right; font-family: monospace; padding: 0.5ex 0.7ex 0.3ex 0.3ex; }
        td:nth-child(1) , th:nth-child(1) , td:nth-child(2) , th:nth-child(2) {
          background-color: #FBFBFA;
          padding: 12px 15px;
          text-align: left;
          border-bottom: 1px solid #e0e0e0;
          }
        td:nth-child(1) , th:nth-child(1) {
          position: sticky;
          left: 0; /* sticks to the left edge of the scrolling container */
          background-color: white; /* covers content behind the column when scrolling */
          z-index: 2; /* ensures column stays above other content */
          }
        td:nth-child(2) , th:nth-child(2) {
          position: sticky;
          left: 8ch; /* assumes first column is 8 chars wide */
          background-color: white;
          z-index: 1; /* lower than first column to avoid overlapping */
          }
        .file { text-align: left; }
        dt { font-style: italic; font-weight: bold; margin: 1ex 0em 0em 0em; }
      </style>
    </head>
  </xsl:template>
  
  <xsl:template name="pre_table" as="element()+">
    <h1>Some Statistics</h1>
    <p xsl:expand-text="yes">
      Various counts of XML constructs in { count($input_files) } files
      that may give insight into their “complexity”.
    </p>
    <aside class="info">
      <h2>glossary</h2>
      <dl>
        <dt>text node</dt>
        <dd>a text() node per the XDM</dd>
        <dt>content node</dt>
        <dd>a text node that contains at least one non-whitespace character</dd>
      </dl>
    </aside>
    <p>Click on a column heading to sort by that column; click again to
      reverse the sort order. You can also jump directly to the <a
      class="allcaps" style="text-decoration: none;" href="#avg">average</a> or
      <a style="text-decoration: none;" class="allcaps" href="#tot">total</a>
      line.</p>
  </xsl:template>
  
  <xsl:template name="table_head" as="element(h:thead)">
    <thead>
      <tr>
        <!-- 01 --><th>seq #</th>
        <!-- 02 --><th>file</th>
        <!-- 03 --><th>#01<br/>filesize in KiB</th> <!-- read from the STDIN to this pgm, not the collection() -->
        <!-- 04 --><th>#02<br/>num<br/>element<br/>types</th>
        <!-- 05 --><th>#03<br/>num<br/>element<br/>instances</th>
        <!-- 06 --><th>#04<br/>element<br/>instances<br/>/ KiB</th>
        <!-- 07 --><th>#05<br/>avg<br/>insts<br/>/ type</th>
        <!-- 08 --><th>#06<br/>max<br/>insts<br/>/ type</th>
        <!-- 09 --><th>#07<br/>num<br/>text<br/>nodes</th>
        <!-- 10 --><th>#08<br/>num<br/>content<br/>nodes</th>
        <!-- 11 --><th>#09<br/>content<br/>nodes<br/>/ KiB</th>
        <!-- 12 --><th>#10<br/>avg chars /<br/>content node</th>
        <!-- 13 --><th>#11<br/>max chars /<br/>content node</th>
        <!-- 14 --><th>#12<br/>avg content nodes<br/>/ element instance</th>
        <!-- 15 --><th>#13<br/>max content nodes<br/>/ element instance</th>
        <!-- 16 --><th>#14<br/>avg content nodes<br/>/ element type</th>
        <!-- 17 --><th>#15<br/>max content nodes<br/>/ element type</th>
        <!-- 18 --><th>#16<br/>avg depth / element instance</th>
        <!-- 19 --><th>#17<br/>max depth / element instance</th>
        <!-- 20 --><th>#18<br/>avg depth / node</th>
        <!-- 21 --><th>#19<br/>max depth / node</th>
        <!-- 22 --><th>#20<br/>avg width / element depth</th>
        <!-- 23 --><th>#21<br/>max width in elements</th>
        <!-- 24 --><th>#22<br/>avg width / node depth</th>
        <!-- 25 --><th>#23<br/>max width in nodes</th>
        <!-- 26 --><th>#24<br/>num attrs</th>
        <!-- 27 --><th>#25<br/>attrs<br/>/ KiB</th>
        <!-- 28 --><th>#26<br/>num attrs + elements</th>
        <!-- 29 --><th>#27<br/>attrs + elements<br/>/ KiB</th>
        <!-- 30 --><th>#28<br/>num attrs + elements + content nodes</th>
        <!-- 31 --><th>#29<br/>attrs + elements + content nodes<br/>/ KiB</th>
        <!-- 32 --><th>#30<br/>avg attr val len</th>
        <!-- 33 --><th>#31<br/>max attr val len</th>
      </tr>
    </thead>
  </xsl:template>
  
  <xsl:template name="table_body" as="element(h:tbody)">
    <!--
        First generate one row per input file with the various
        syntactical counts of stuff. 
    -->
    <xsl:variable name="rows" as="element(h:tr)*">
      <!-- Note that we use '*', not '+', above, in case the input
           fileset does not contain any documents $dataSel (in which
           case there will be no rows generated. That would be sad.) -->
      <xsl:for-each select="$input_files">
        <xsl:variable name="input_file_num" select="position()" as="xs:integer"/>
        <xsl:apply-templates select="." mode="stats">
          <xsl:with-param name="row_num" select="$input_file_num" as="xs:integer"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="extra_rows" as="element(h:tr)*">
      <xsl:call-template name="aggregates">
        <xsl:with-param name="rows" select="$rows" as="element(h:tr)*"/>
      </xsl:call-template>
    </xsl:variable>
    <tbody>
      <xsl:sequence select="$extra_rows,$rows"/>
    </tbody>
  </xsl:template>
  
  <xsl:template name="post_table" as="element(h:aside)">
    <aside class="reference">
      <h2>colophon</h2>
      <p xsl:expand-text="yes">
        Information extracted from
        <tt>{substring-before( $collect_us, '?' )}</tt>
        with
        <tt>{substring-after( $collect_us, '?')}</tt>
        (or <tt>{$collect_us})</tt>
        at
        <tt>{substring( current-dateTime() cast as xs:string, 1, 16 )}</tt>,
        using the
        <tt>{static-base-uri()}</tt>
        stylesheet.
      </p>
    </aside>
  </xsl:template>
  
  <!-- ******************************************************** -->
  <!-- Subroutines of table_body: should generate <tr> elements -->
  <!-- ******************************************************** -->
  
  <xsl:template match="document-node()" mode="stats" as="element(h:tr)">
    <xsl:param name="row_num" as="xs:integer"/>
    <xsl:variable name="doc" select="." as="document-node()"/>
    <xsl:variable name="fn" select="tokenize( base-uri( $doc ), '/')[last()]" as="xs:string"/>
    <xsl:variable name="fs_in_KiB" select="xs:decimal( $input/dir/f[ @n eq $fn ]/@s!xs:integer(.) div 1024.0 )" as="xs:decimal"/>
    <xsl:variable name="fss" select="$fs_in_KiB => format-number( $fracNpic )" as="xs:string"/> <!-- file size string -->
    <xsl:variable name="elementTypes" select="distinct-values( $doc//*!name(.) )" as="xs:string+"/>
    <xsl:variable name="num_elementInstances" select="count( $doc//* )" as="xs:integer"/>
    <xsl:variable name="instancesPerType" as="xs:integer+"
                  select="for $t in $elementTypes return ( count( $doc//*[ name(.) eq $t ] ) )"/>
    <xsl:variable name="text_nodes" as="xs:string*" select="$doc//text()"/>
    <xsl:variable name="content_nodes" as="xs:string*" select="$doc//text()[ normalize-space() ne '']"/>
    <xsl:variable name="chars_per_content_node" as="xs:integer*"
                  select="for $c in $content_nodes return string-length($c)"/>
    <xsl:variable name="content_node_children_per_element_instance" as="xs:integer+"
                  select="for $e in $doc//* return count( $e/text()[ normalize-space() ne ''] )"/>
    <xsl:variable name="content_node_children_per_element_type" as="xs:integer+"
                  select="for $t in $elementTypes
                          return sum( $doc//*[ name(.) eq $t ]!count( text()[ normalize-space() ne ''] ) )"/>
    <xsl:variable name="chars_per_element_instance" as="xs:integer+"
                  select="for $e in $doc//* return string-length( $e!string() )"/>
    <xsl:variable name="chars_per_element_type" as="xs:integer+"
                  select="for $t in $elementTypes return sum( $doc//*[ name(.) eq $t ]!string()!string-length(.) )"/>
    <xsl:variable name="depths_per_element_instance" as="xs:integer+"
                  select="for $e in $doc//* return count( $e/ancestor-or-self::* )"/>
    <xsl:variable name="max_element_depth" select="max( $depths_per_element_instance )" as="xs:integer"/>
    <xsl:variable name="depths_per_node" as="xs:integer+"
                  select="for $n in $doc//node() return count( $n/ancestor-or-self::node() )"/>
    <xsl:variable name="max_node_depth" select="max( $depths_per_node )" as="xs:integer"/>
    <xsl:variable name="attr_value_lengths" as="xs:integer*"
                  select="for $a in $doc//@* return string-length( normalize-space( $a ) )"/>
    <xsl:variable name="widths_per_element_depth" as="xs:integer+"
                  select="for $i in 1 to $max_element_depth
                          return count( $doc//*[ count( ancestor-or-self::* ) eq $i ] )"/>
    <xsl:variable name="widths_per_node_depth" as="xs:integer+"
                  select="for $i in 1 to $max_node_depth
                          return count( $doc//node()[ count( ancestor-or-self::node() ) eq $i ] )"/>
    <tr xsl:expand-text="yes">
      <!-- 01 --><td sorttable_customkey="{$row_num}">{$row_num}</td>  <!-- calculate on 2nd pass -->
      <!-- 02 --><td class="file" title="{ base-uri( $doc ) }">{ $fn }</td>
      <!-- 03 --><td sorttable_customkey="{ $fs_in_KiB }">{ $fss }</td>
      <!-- 04 --><td>{ count( $elementTypes ) => format-integer('###,###,##0') }</td>
      <!-- 05 --><td>{ $num_elementInstances => format-integer('###,###,##0') }</td>
      <!-- 06 --><td>{ ( $num_elementInstances div $fs_in_KiB ) => format-number( $fracNpic ) }</td>
      <!-- 07 --><td sorttable_customkey="{avg( $instancesPerType )}">{ avg( $instancesPerType ) => format-number('###,###,##0.00') }</td>
      <!-- 08 --><td>{ max( $instancesPerType ) => format-integer('###,###,##0') }</td>
      <!-- 09 --><td>{ count( $text_nodes ) => format-integer('###,###,##0') }</td>
      <!-- 10 --><td>{ count( $content_nodes ) => format-integer('###,###,##0') }</td>
      <!-- 11 --><td sorttable_customkey="{avg( $chars_per_content_node )}">{ avg( $chars_per_content_node ) => format-number('###,###,##0.00') }</td>
      <!-- 12 --><td>{ ( count( $content_nodes ) div $fs_in_KiB ) => format-number( $fracNpic ) }</td>
      <!-- 13 --><td>{ max( $chars_per_content_node ) }</td>
      <!-- 14 --><td sorttable_customkey="{avg( $content_node_children_per_element_instance )}">{ avg( $content_node_children_per_element_instance ) => format-number('###,###,##0.00') }</td>
      <!-- 15 --><td>{ max( $content_node_children_per_element_instance ) => format-integer('###,###,##0') }</td>
      <!-- 16 --><td sorttable_customkey="{avg( $content_node_children_per_element_type )}">{ avg( $content_node_children_per_element_type ) => format-number('###,###,##0.00') }</td>
      <!-- 17 --><td>{ max( $content_node_children_per_element_type ) => format-integer('###,###,##0') }</td>
      <!-- 18 --><td sorttable_customkey="{avg( $depths_per_element_instance )}">{ avg( $depths_per_element_instance ) => format-number('###,###,##0.00') }</td>
      <!-- 19 --><td>{ $max_element_depth => format-integer('###,###,##0') }</td>
      <!-- 20 --><td sorttable_customkey="{avg( $depths_per_node )}">{ avg( $depths_per_node ) => format-number('###,###,##0.00') }</td>
      <!-- 21 --><td>{ $max_node_depth => format-integer('###,###,##0') }</td>
      <!-- 22 --><td sorttable_customkey="{avg( $widths_per_element_depth )}">{ avg( $widths_per_element_depth ) => format-number('###,###,##0.00') }</td>
      <!-- 23 --><td>{ max( $widths_per_element_depth ) => format-integer('###,###,##0') }</td>
      <!-- 24 --><td sorttable_customkey="{avg( $widths_per_node_depth )}">{ avg( $widths_per_node_depth ) => format-number('###,###,##0.00') }</td>
      <!-- 25 --><td>{ max( $widths_per_node_depth ) => format-integer('###,###,##0') }</td>
      <!-- 26 --><td>{ count( //@* ) => format-integer('###,###,##0') }</td>
      <!-- 27 --><td>{ ( count( //@* ) div $fs_in_KiB ) => format-number( $fracNpic ) }</td>
      <!-- 28 --><td>{ ( count( //@* ) + count( //* ) ) => format-integer('###,###,##0') }</td>
      <!-- 29 --><td>{ ( ( count( //@* ) + count( //* ) ) div $fs_in_KiB ) => format-number( $fracNpic ) }</td>
      <!-- 30 --><td>{ ( count( //@* ) + count( //* ) + count( $content_nodes ) ) => format-integer('###,###,##0') }</td>
      <!-- 31 --><td>{ ( ( count( //@* ) + count( //* ) + count( $content_nodes ) ) div $fs_in_KiB ) => format-number( $fracNpic ) }</td>
      <!-- 32 --><td sorttable_customkey="{avg( $attr_value_lengths )}">{ avg( $attr_value_lengths ) => format-number('###,###,##0.00') }</td>
      <!-- 33 --><td>{ max( $attr_value_lengths ) }</td>
    </tr>
  </xsl:template>

  <xsl:template name="aggregates" as="element(h:tr)*"><!-- called via call-template -->
    <xsl:param name="rows" as="element(h:tr)*"/>
    <xsl:param name="count" select="count( $rows )"/>
    <xsl:if test="$count gt 0">
      <tr id="tot">
        <xsl:for-each select="1 to count( $rows[1]/h:td )">
          <xsl:variable name="pos" select="position()"/>
          <xsl:choose>
            <xsl:when test="$pos eq 1">
              <td  sorttable_customkey="~zzz">TOTAL</td>
            </xsl:when>
            <xsl:when test="$pos eq 2">
              <td style="font-style: italic;" sorttable_customkey="~zzz"><xsl:sequence select="$count"/> files</td>
            </xsl:when>
            <xsl:when test="$rows/h:td[ position() eq $pos ]!contains( ., '.') = true()">
              <xsl:variable name="seqofem" select="$rows/h:td[ $pos ]!translate( ., $nonDigs, '')!xs:decimal(.)" as="xs:decimal+"/>
              <td><xsl:sequence select="format-number( sum( $seqofem ), $fracNpic )"/></td>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="seqofem" select="$rows/h:td[ $pos ]!translate( ., $nonDigs, '')!xs:integer(.)" as="xs:integer+"/>
              <td><xsl:sequence select="format-number( sum( $seqofem ), $fracNpic )"/></td>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </tr>
      <tr id="avg">
        <xsl:for-each select="1 to count( $rows[1]/h:td )">
          <xsl:variable name="pos" select="position()"/>
          <xsl:choose>
            <xsl:when test="$pos eq 1">
              <td  sorttable_customkey="~yyy">AVERAGE</td>
            </xsl:when>
            <xsl:when test="$pos eq 2">
              <td style="font-style: italic;" sorttable_customkey="~yyy"><xsl:sequence select="$count"/> files</td>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="seqofem" select="$rows/h:td[ $pos ]!translate( ., $nonDigs, '')!xs:decimal(.)" as="xs:decimal+"/>
              <td><xsl:sequence select="format-number( avg( $seqofem ), $fracNpic )"/></td>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </tr>
    </xsl:if>
  </xsl:template>

  <!--
      Debugging function
  -->
  <xsl:function name="wf:whatisthis" as="xs:string">
    <xsl:param name="dot"/>
    <xsl:variable name="me">
      <xsl:if test="$dot[self::document-node()]">document()</xsl:if>
      <xsl:if test="$dot[self::node()]">node()</xsl:if>
      <xsl:if test="$dot[self::text()]">text()</xsl:if>
      <xsl:if test="$dot[self::element()]">element()</xsl:if>
      <xsl:if test="$dot[self::namespace-node()]">namespace-node()</xsl:if>
      <xsl:if test="$dot[self::attribute()]">attribute()</xsl:if>
      <xsl:if test="$dot[self::processing-instruction()]">pi()</xsl:if>
      <xsl:if test="$dot[self::comment()]">comment()</xsl:if>
    </xsl:variable>
    <xsl:sequence select="string-join( $me )"/>
  </xsl:function>

</xsl:stylesheet>
